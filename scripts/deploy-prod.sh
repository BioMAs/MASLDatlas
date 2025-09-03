#!/bin/bash
# Simple Production Deployment Script for MASLDatlas
# Déploie l'application optimisée en production avec Traefik

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo "🚀 MASLDatlas Production Deployment"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "app.R" ]; then
    echo "❌ app.R not found. Please run this script from the MASLDatlas directory."
    exit 1
fi

# Check if Traefik network exists
if ! docker network ls | grep -q "web"; then
    log_warning "Traefik 'web' network not found. Creating it..."
    docker network create web
fi

# Build and start production
log_info "Building and starting production environment..."
docker-compose -f docker-compose.prod.yml up -d --build

# Wait for services to be ready
log_info "Waiting for services to start..."
sleep 30

# Check if application is responding
log_info "Checking application health..."
if curl -f "http://localhost:3838" > /dev/null 2>&1; then
    log_success "Application is running!"
    echo ""
    echo "🌐 Application available at:"
    echo "  - Local: http://localhost:3838"
    echo "  - Production: https://masldatlas.scilicium.com (with Traefik)"
    echo ""
    echo "🚀 Optimizations active:"
    echo "  - Performance modules loaded"
    echo "  - 8GB RAM limit with tmpfs cache"
    echo "  - 4 CPU cores available"
    echo "  - Health checks enabled"
else
    log_warning "Application not responding yet, check logs:"
    echo "docker-compose -f docker-compose.prod.yml logs -f"
fi

log_success "Production deployment complete!"
