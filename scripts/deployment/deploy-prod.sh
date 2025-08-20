#!/bin/bash

# Production deployment script for MASLDatlas
# Usage: ./deploy-prod.sh [domain]

set -e

# Configuration
DOMAIN=${1:-"masldatlas.yourdomain.com"}
COMPOSE_FILE="docker-compose.prod.yml"
SERVICE_NAME="masldatlas"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    if ! docker network ls | grep -q "traefik-network"; then
        log_error "Traefik network 'traefik-network' not found. Please ensure Traefik is running."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Update domain in docker-compose file
update_domain() {
    log_info "Updating domain to: $DOMAIN"
    
    # Create a backup of the original file
    cp $COMPOSE_FILE "${COMPOSE_FILE}.bak"
    
    # Replace the domain in the compose file
    sed -i.tmp "s/masldatlas\.yourdomain\.com/$DOMAIN/g" $COMPOSE_FILE
    rm "${COMPOSE_FILE}.tmp" 2>/dev/null || true
    
    log_success "Domain updated in $COMPOSE_FILE"
}

# Build the application
build_application() {
    log_info "Building MASLDatlas application..."
    
    docker-compose -f $COMPOSE_FILE build --no-cache
    
    log_success "Application built successfully"
}

# Deploy the application
deploy_application() {
    log_info "Deploying MASLDatlas to production..."
    
    # Stop existing service if running
    docker-compose -f $COMPOSE_FILE down 2>/dev/null || true
    
    # Start the service
    docker-compose -f $COMPOSE_FILE up -d
    
    log_success "Application deployed successfully"
}

# Health check
health_check() {
    log_info "Performing health check..."
    
    # Wait for container to start
    sleep 30
    
    # Check container status
    if ! docker-compose -f $COMPOSE_FILE ps | grep -q "Up"; then
        log_error "Container is not running"
        docker-compose -f $COMPOSE_FILE logs
        exit 1
    fi
    
    # Check application health
    local max_attempts=20
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "Health check attempt $attempt/$max_attempts..."
        
        if curl -f -s "https://$DOMAIN/" > /dev/null 2>&1; then
            log_success "Application is healthy and accessible at https://$DOMAIN"
            return 0
        fi
        
        sleep 15
        ((attempt++))
    done
    
    log_error "Health check failed after $max_attempts attempts"
    log_info "Container logs:"
    docker-compose -f $COMPOSE_FILE logs --tail=50
    exit 1
}

# Show status
show_status() {
    log_info "Deployment Status:"
    echo ""
    
    # Container status
    echo "Container Status:"
    docker-compose -f $COMPOSE_FILE ps
    echo ""
    
    # Resource usage
    echo "Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" \
        $(docker-compose -f $COMPOSE_FILE ps -q) 2>/dev/null || echo "No running containers"
    echo ""
    
    # Access information
    echo "Access Information:"
    echo "- Application URL: https://$DOMAIN"
    echo "- Traefik Dashboard: https://traefik.yourdomain.com (if configured)"
    echo ""
    
    # Quick commands
    echo "Management Commands:"
    echo "- View logs: docker-compose -f $COMPOSE_FILE logs -f"
    echo "- Stop service: docker-compose -f $COMPOSE_FILE down"
    echo "- Restart service: docker-compose -f $COMPOSE_FILE restart"
    echo "- Update: ./deploy-prod.sh $DOMAIN"
}

# Rollback function
rollback() {
    log_warning "Rolling back deployment..."
    
    if [ -f "${COMPOSE_FILE}.bak" ]; then
        mv "${COMPOSE_FILE}.bak" $COMPOSE_FILE
        log_info "Restored original compose file"
    fi
    
    docker-compose -f $COMPOSE_FILE down
    log_success "Rollback completed"
}

# Cleanup function
cleanup() {
    if [ -f "${COMPOSE_FILE}.bak" ]; then
        rm "${COMPOSE_FILE}.bak"
    fi
}

# Main deployment process
main() {
    log_info "Starting MASLDatlas production deployment..."
    log_info "Domain: $DOMAIN"
    echo ""
    
    # Set trap for cleanup on exit
    trap cleanup EXIT
    trap rollback ERR
    
    check_prerequisites
    update_domain
    build_application
    deploy_application
    health_check
    show_status
    
    log_success "🎉 MASLDatlas has been successfully deployed to production!"
    log_info "Access your application at: https://$DOMAIN"
}

# Help function
show_help() {
    echo "MASLDatlas Production Deployment Script"
    echo ""
    echo "Usage: $0 [DOMAIN]"
    echo ""
    echo "Arguments:"
    echo "  DOMAIN    The domain name for the application (default: masldatlas.yourdomain.com)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Deploy with default domain"
    echo "  $0 masld.example.com                 # Deploy with custom domain"
    echo ""
    echo "Prerequisites:"
    echo "  - Docker and Docker Compose installed"
    echo "  - Traefik running with 'traefik-network' network"
    echo "  - DNS pointing to your server"
    echo ""
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        main
        ;;
esac
