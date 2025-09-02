#!/bin/bash

# 🚀 MASLDatlas Smart Deployment Script
# Intelligent deployment with monitoring and rollback capabilities
# Author: MASLDatlas Team
# Version: 2.0

set -euo pipefail

# Configuration
DOMAIN="${1:-localhost}"
ENVIRONMENT="${2:-production}"
DEPLOY_MODE="${3:-standard}"
LOG_FILE="logs/deployment_$(date +%Y%m%d_%H%M%S).log"
BACKUP_BEFORE_DEPLOY=true
HEALTH_CHECK_TIMEOUT=300  # 5 minutes
ROLLBACK_ON_FAILURE=true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Create logs directory
mkdir -p logs

# Enhanced logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""
    
    case $level in
        "INFO") color=$GREEN ;;
        "WARN") color=$YELLOW ;;
        "ERROR") color=$RED ;;
        "DEBUG") color=$CYAN ;;
        *) color=$NC ;;
    esac
    
    echo -e "${color}[$level]${NC} $message"
    echo "$timestamp [$level] $message" >> "$LOG_FILE"
}

# Progress indicator
show_progress() {
    local message="$1"
    local duration="${2:-3}"
    
    log "INFO" "$message"
    for i in $(seq 1 $duration); do
        echo -n "."
        sleep 1
    done
    echo ""
}

# Pre-deployment checks
pre_deployment_checks() {
    log "INFO" "🔍 Running pre-deployment checks..."
    
    local checks_passed=true
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker not found"
        checks_passed=false
    fi
    
    if ! docker info &> /dev/null; then
        log "ERROR" "Docker daemon not running"
        checks_passed=false
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log "ERROR" "Docker Compose not found"
        checks_passed=false
    fi
    
    # Check required files
    local required_files=(
        "Dockerfile"
        "docker-compose.prod.yml"
        "config/datasets_config.json"
        "app.R"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log "ERROR" "Required file missing: $file"
            checks_passed=false
        fi
    done
    
    # Check datasets
    if [ ! -d "datasets" ]; then
        log "WARN" "Datasets directory not found - will be created"
    fi
    
    # Check disk space (minimum 5GB)
    local available_space=$(df . | tail -1 | awk '{print $4}')
    local available_gb=$((available_space / 1024 / 1024))
    
    if [ $available_gb -lt 5 ]; then
        log "ERROR" "Insufficient disk space: ${available_gb}GB available (minimum 5GB required)"
        checks_passed=false
    fi
    
    if [ "$checks_passed" = true ]; then
        log "INFO" "✅ All pre-deployment checks passed"
        return 0
    else
        log "ERROR" "❌ Pre-deployment checks failed"
        return 1
    fi
}

# Create backup before deployment
create_deployment_backup() {
    if [ "$BACKUP_BEFORE_DEPLOY" = true ]; then
        log "INFO" "💾 Creating backup before deployment..."
        
        if [ -f "scripts/backup/backup_system.sh" ]; then
            if ./scripts/backup/backup_system.sh backup; then
                log "INFO" "✅ Backup created successfully"
            else
                log "WARN" "⚠️ Backup failed, continuing anyway"
            fi
        else
            log "WARN" "Backup script not found, skipping backup"
        fi
    fi
}

# Build application image
build_application() {
    log "INFO" "🏗️ Building application image..."
    
    local build_start=$(date +%s)
    
    # Build with progress and detailed logs
    if docker-compose -f docker-compose.prod.yml build --no-cache 2>&1 | tee -a "$LOG_FILE"; then
        local build_end=$(date +%s)
        local build_time=$((build_end - build_start))
        log "INFO" "✅ Build completed in ${build_time}s"
        return 0
    else
        log "ERROR" "❌ Build failed"
        return 1
    fi
}

# Deploy application
deploy_application() {
    log "INFO" "🚀 Deploying application..."
    
    # Stop existing containers gracefully
    log "INFO" "⏹️ Stopping existing containers..."
    docker-compose -f docker-compose.prod.yml down --timeout 30 || true
    
    # Wait a moment for cleanup
    sleep 5
    
    # Start new containers
    log "INFO" "▶️ Starting new containers..."
    if docker-compose -f docker-compose.prod.yml up -d; then
        log "INFO" "✅ Containers started"
        return 0
    else
        log "ERROR" "❌ Failed to start containers"
        return 1
    fi
}

# Advanced health check
perform_health_check() {
    log "INFO" "🏥 Performing comprehensive health check..."
    
    local health_url="http://localhost:3838"
    local start_time=$(date +%s)
    local timeout=$HEALTH_CHECK_TIMEOUT
    
    # Wait for container to be ready
    log "INFO" "⏳ Waiting for container to start..."
    local container_ready=false
    local wait_time=0
    
    while [ $wait_time -lt 60 ]; do
        if docker ps | grep -q "masldatlas-prod"; then
            if [ "$(docker inspect --format='{{.State.Health.Status}}' masldatlas-prod 2>/dev/null || echo 'unknown')" != "unhealthy" ]; then
                container_ready=true
                break
            fi
        fi
        sleep 5
        wait_time=$((wait_time + 5))
        echo -n "."
    done
    echo ""
    
    if [ "$container_ready" = false ]; then
        log "ERROR" "Container failed to start properly"
        return 1
    fi
    
    # HTTP health check
    log "INFO" "🌐 Testing HTTP endpoint..."
    local attempt=1
    local max_attempts=$((timeout / 10))
    
    while [ $attempt -le $max_attempts ]; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -gt $timeout ]; then
            log "ERROR" "Health check timeout after ${timeout}s"
            return 1
        fi
        
        log "DEBUG" "Health check attempt $attempt/$max_attempts"
        
        if curl -f -s --max-time 10 "$health_url" > /dev/null 2>&1; then
            log "INFO" "✅ HTTP endpoint responding"
            
            # Additional R-specific health check
            if perform_app_specific_checks; then
                log "INFO" "✅ Application health check passed"
                return 0
            else
                log "WARN" "Application health check failed, but endpoint is responding"
                return 1
            fi
        fi
        
        attempt=$((attempt + 1))
        sleep 10
    done
    
    log "ERROR" "❌ Health check failed after $max_attempts attempts"
    return 1
}

# Application-specific health checks
perform_app_specific_checks() {
    log "INFO" "🧪 Running application-specific checks..."
    
    # Check if Shiny app is properly loaded
    local response=$(curl -s --max-time 30 "http://localhost:3838" 2>/dev/null || echo "")
    
    if [[ "$response" == *"Multi-species scRNA-seq Atlas"* ]]; then
        log "INFO" "✅ Shiny application loaded correctly"
    else
        log "ERROR" "❌ Shiny application not properly loaded"
        return 1
    fi
    
    # Check container logs for errors
    local error_count=$(docker logs masldatlas-prod 2>&1 | grep -i "error\|failed\|exception" | wc -l)
    
    if [ $error_count -gt 0 ]; then
        log "WARN" "⚠️ Found $error_count error messages in logs"
        log "DEBUG" "Recent errors:"
        docker logs --tail 10 masldatlas-prod 2>&1 | grep -i "error\|failed\|exception" | head -5 | while read line; do
            log "DEBUG" "  $line"
        done
    else
        log "INFO" "✅ No critical errors in logs"
    fi
    
    return 0
}

# Rollback function
perform_rollback() {
    log "INFO" "🔄 Performing rollback..."
    
    # Stop current deployment
    docker-compose -f docker-compose.prod.yml down || true
    
    # Try to restore from latest backup
    local latest_backup=$(find backups -name "*.tar.gz" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [ -n "$latest_backup" ] && [ -f "$latest_backup" ]; then
        log "INFO" "📦 Restoring from backup: $latest_backup"
        if ./scripts/backup/backup_system.sh restore "$latest_backup"; then
            log "INFO" "✅ Rollback completed"
        else
            log "ERROR" "❌ Rollback failed"
        fi
    else
        log "WARN" "No backup available for rollback"
    fi
}

# Post-deployment tasks
post_deployment_tasks() {
    log "INFO" "📋 Running post-deployment tasks..."
    
    # Show deployment status
    show_deployment_status
    
    # Set up monitoring (if available)
    if [ -f "scripts/monitoring/docker_monitor.sh" ]; then
        log "INFO" "🔍 Setting up monitoring..."
        chmod +x scripts/monitoring/docker_monitor.sh
        
        # Run initial monitoring check
        ./scripts/monitoring/docker_monitor.sh masldatlas-prod || log "WARN" "Initial monitoring check failed"
    fi
    
    # Clean up old images
    log "INFO" "🧹 Cleaning up old Docker images..."
    docker image prune -f || true
    
    log "INFO" "✅ Post-deployment tasks completed"
}

# Show deployment status
show_deployment_status() {
    log "INFO" "📊 Deployment Status Summary"
    echo "=============================================="
    
    # Container status
    echo "🐳 Container Status:"
    docker ps --filter "name=masldatlas" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # Resource usage
    echo ""
    echo "📊 Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" masldatlas-prod 2>/dev/null || echo "  Stats not available"
    
    # Health status
    echo ""
    echo "🏥 Health Status:"
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' masldatlas-prod 2>/dev/null || echo "unknown")
    echo "  Health: $health_status"
    
    # Access information
    echo ""
    echo "🌐 Access Information:"
    echo "  Local: http://localhost:3838"
    if [ "$DOMAIN" != "localhost" ]; then
        echo "  Production: https://$DOMAIN"
    fi
    
    echo "=============================================="
}

# Main deployment function
main_deployment() {
    log "INFO" "🚀 Starting MASLDatlas deployment to $ENVIRONMENT"
    log "INFO" "📅 Deployment started at $(date)"
    log "INFO" "🏷️ Domain: $DOMAIN"
    log "INFO" "📝 Log file: $LOG_FILE"
    
    local deployment_start=$(date +%s)
    local deployment_success=true
    
    # Run pre-deployment checks
    if ! pre_deployment_checks; then
        log "ERROR" "Pre-deployment checks failed"
        exit 1
    fi
    
    # Create backup
    create_deployment_backup
    
    # Build application
    if ! build_application; then
        log "ERROR" "Build failed"
        exit 1
    fi
    
    # Deploy application
    if ! deploy_application; then
        log "ERROR" "Deployment failed"
        if [ "$ROLLBACK_ON_FAILURE" = true ]; then
            perform_rollback
        fi
        exit 1
    fi
    
    # Health check
    if ! perform_health_check; then
        log "ERROR" "Health check failed"
        deployment_success=false
        
        if [ "$ROLLBACK_ON_FAILURE" = true ]; then
            perform_rollback
            exit 1
        fi
    fi
    
    # Post-deployment tasks
    post_deployment_tasks
    
    local deployment_end=$(date +%s)
    local deployment_time=$((deployment_end - deployment_start))
    
    if [ "$deployment_success" = true ]; then
        log "INFO" "🎉 Deployment completed successfully in ${deployment_time}s"
        log "INFO" "🌐 Application available at: http://localhost:3838"
        if [ "$DOMAIN" != "localhost" ]; then
            log "INFO" "🌍 Production URL: https://$DOMAIN"
        fi
    else
        log "ERROR" "❌ Deployment completed with errors in ${deployment_time}s"
        exit 1
    fi
}

# Usage information
usage() {
    echo "MASLDatlas Smart Deployment Script v2.0"
    echo ""
    echo "Usage: $0 [DOMAIN] [ENVIRONMENT] [MODE]"
    echo ""
    echo "Parameters:"
    echo "  DOMAIN      Target domain (default: localhost)"
    echo "  ENVIRONMENT Environment name (default: production)"
    echo "  MODE        Deployment mode (standard|fast|safe)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Local deployment"
    echo "  $0 masldatlas.example.com             # Production deployment"
    echo "  $0 staging.example.com staging        # Staging deployment"
    echo "  $0 localhost development fast         # Fast local deployment"
    echo ""
    echo "Environment Variables:"
    echo "  BACKUP_BEFORE_DEPLOY=false           # Skip backup"
    echo "  ROLLBACK_ON_FAILURE=false            # Disable auto-rollback"
    echo "  HEALTH_CHECK_TIMEOUT=600             # Extend health check timeout"
}

# Handle command line arguments
case "${1:-}" in
    "help"|"--help"|"-h")
        usage
        exit 0
        ;;
    *)
        main_deployment
        ;;
esac
