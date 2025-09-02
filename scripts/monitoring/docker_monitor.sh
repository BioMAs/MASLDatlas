#!/bin/bash

# 🐳 MASLDatlas Docker Monitoring Script
# Monitors Docker containers and application health
# Author: MASLDatlas Team
# Version: 1.0

set -euo pipefail

# Configuration
LOG_FILE="logs/docker_monitoring_$(date +%Y%m%d).log"
CONTAINER_NAME="${1:-masldatlas-masldatlas-1}"
HEALTH_ENDPOINT="http://localhost:3838"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create logs directory
mkdir -p logs

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""
    
    case $level in
        "INFO") color=$GREEN ;;
        "WARN") color=$YELLOW ;;
        "ERROR") color=$RED ;;
        *) color=$NC ;;
    esac
    
    echo -e "${color}[$level]${NC} $message"
    echo "$timestamp [$level] $message" >> "$LOG_FILE"
}

# Check if Docker is running
check_docker() {
    log "INFO" "🐳 Checking Docker status..."
    
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker not found"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        log "ERROR" "Docker daemon not running"
        return 1
    fi
    
    log "INFO" "✅ Docker is running"
    return 0
}

# Check container status
check_container() {
    log "INFO" "📦 Checking container: $CONTAINER_NAME"
    
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        log "ERROR" "Container $CONTAINER_NAME not running"
        
        # Check if container exists but stopped
        if docker ps -a | grep -q "$CONTAINER_NAME"; then
            log "WARN" "Container exists but stopped"
            return 2
        else
            log "ERROR" "Container does not exist"
            return 1
        fi
    fi
    
    log "INFO" "✅ Container is running"
    return 0
}

# Check application health
check_app_health() {
    log "INFO" "🩺 Checking application health..."
    
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$HEALTH_ENDPOINT" > /dev/null 2>&1; then
            log "INFO" "✅ Application responding (attempt $attempt)"
            return 0
        fi
        
        log "WARN" "❌ Application not responding (attempt $attempt/$max_attempts)"
        attempt=$((attempt + 1))
        sleep 5
    done
    
    log "ERROR" "Application health check failed"
    return 1
}

# Get container resource usage
get_container_stats() {
    log "INFO" "📊 Getting container resource usage..."
    
    if docker ps | grep -q "$CONTAINER_NAME"; then
        # Get container stats (non-streaming, one measurement)
        local stats=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" "$CONTAINER_NAME")
        log "INFO" "Resource usage: $stats"
        
        # Log to separate stats file
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $stats" >> "logs/container_stats.log"
    else
        log "ERROR" "Cannot get stats - container not running"
    fi
}

# Get application logs (last 50 lines)
get_app_logs() {
    log "INFO" "📝 Getting application logs..."
    
    if docker ps | grep -q "$CONTAINER_NAME"; then
        local log_output="logs/app_logs_$(date +%Y%m%d_%H%M%S).log"
        docker logs --tail 50 "$CONTAINER_NAME" > "$log_output" 2>&1
        log "INFO" "Application logs saved to: $log_output"
    else
        log "ERROR" "Cannot get logs - container not running"
    fi
}

# Main monitoring function
run_monitoring() {
    log "INFO" "🚀 Starting MASLDatlas monitoring..."
    
    local status=0
    
    # Check Docker
    if ! check_docker; then
        status=1
    fi
    
    # Check container
    container_status=0
    check_container || container_status=$?
    
    if [ $container_status -eq 1 ]; then
        status=1
    elif [ $container_status -eq 2 ]; then
        log "INFO" "🔄 Attempting to restart container..."
        docker start "$CONTAINER_NAME" || {
            log "ERROR" "Failed to restart container"
            status=1
        }
    fi
    
    # Check application health
    if ! check_app_health; then
        status=1
        get_app_logs
    fi
    
    # Get resource stats
    get_container_stats
    
    if [ $status -eq 0 ]; then
        log "INFO" "✅ All checks passed"
    else
        log "ERROR" "❌ Some checks failed"
    fi
    
    return $status
}

# Auto-restart function
auto_restart() {
    log "INFO" "🔄 Attempting automatic restart..."
    
    # Stop container gracefully
    if docker ps | grep -q "$CONTAINER_NAME"; then
        log "INFO" "Stopping container..."
        docker stop "$CONTAINER_NAME" || true
    fi
    
    # Wait a moment
    sleep 5
    
    # Restart via docker-compose
    log "INFO" "Restarting via docker-compose..."
    if docker-compose up -d; then
        log "INFO" "✅ Restart successful"
        
        # Wait for startup
        sleep 30
        
        # Verify restart
        if check_app_health; then
            log "INFO" "✅ Application healthy after restart"
            return 0
        else
            log "ERROR" "❌ Application unhealthy after restart"
            return 1
        fi
    else
        log "ERROR" "❌ Restart failed"
        return 1
    fi
}

# Usage function
usage() {
    echo "Usage: $0 [CONTAINER_NAME] [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --monitor       Run monitoring check (default)"
    echo "  --restart       Auto-restart if unhealthy"
    echo "  --stats         Show resource stats only"
    echo "  --logs          Get application logs only"
    echo "  --help          Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                           # Monitor default container"
    echo "  $0 my-container --restart    # Monitor and auto-restart"
    echo "  $0 --stats                   # Get stats only"
}

# Main script
main() {
    case "${2:-}" in
        "--restart")
            if ! run_monitoring; then
                auto_restart
            fi
            ;;
        "--stats")
            get_container_stats
            ;;
        "--logs")
            get_app_logs
            ;;
        "--help")
            usage
            exit 0
            ;;
        "")
            run_monitoring
            ;;
        *)
            log "ERROR" "Unknown option: $2"
            usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
