#!/bin/bash
# Quick test script for volume-based Docker deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    log_info "🔍 Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check if datasets directory exists
    if [ ! -d "./datasets" ]; then
        log_warning "Datasets directory doesn't exist, creating it..."
        mkdir -p ./datasets/{Human,Mouse,Zebrafish,Integrated}
    fi
    
    log_success "Prerequisites check passed"
}

# Test volume mounting
test_volume_mount() {
    log_info "🧪 Testing volume mount..."
    
    # Create test file
    echo "test" > ./datasets/volume_test.txt
    
    # Test mount with simple container
    if docker run --rm -v "$(pwd)/datasets:/test" alpine:latest sh -c "
        if [ -f '/test/volume_test.txt' ]; then
            echo 'Volume mount successful'
            exit 0
        else
            echo 'Volume mount failed'
            exit 1
        fi
    "; then
        log_success "Volume mount test passed"
        rm -f ./datasets/volume_test.txt
    else
        log_error "Volume mount test failed"
        rm -f ./datasets/volume_test.txt
        exit 1
    fi
}

# Build application image
build_image() {
    log_info "🐳 Building MASLDatlas image..."
    
    if docker build -t masldatlas-volume-test .; then
        log_success "Image built successfully"
        
        # Show image size
        local image_size=$(docker images masldatlas-volume-test --format "{{.Size}}")
        log_info "📦 Image size: $image_size"
    else
        log_error "Image build failed"
        exit 1
    fi
}

# Test container startup
test_container() {
    log_info "🚀 Testing container startup..."
    
    # Remove any existing test container
    docker rm -f masldatlas-test 2>/dev/null || true
    
    # Start container with volume mounts
    if docker run -d \
        --name masldatlas-test \
        -p 3839:3838 \
        -v "$(pwd)/datasets:/app/datasets:ro" \
        -v "$(pwd)/config:/app/config:ro" \
        -v "$(pwd)/enrichment_sets:/app/enrichment_sets:ro" \
        -e AUTO_DOWNLOAD_DATASETS=false \
        masldatlas-volume-test; then
        
        log_success "Container started successfully"
        
        # Wait for startup
        log_info "⏳ Waiting for application to start..."
        sleep 10
        
        # Check if container is running
        if docker ps | grep -q masldatlas-test; then
            log_success "Container is running"
            
            # Check application health
            log_info "🏥 Checking application health..."
            local health_attempts=0
            local max_attempts=12 # 2 minutes max
            
            while [ $health_attempts -lt $max_attempts ]; do
                if curl -f http://localhost:3839 >/dev/null 2>&1; then
                    log_success "Application is responding!"
                    log_info "🌐 Access the application at: http://localhost:3839"
                    break
                fi
                
                health_attempts=$((health_attempts + 1))
                log_info "   Attempt $health_attempts/$max_attempts..."
                sleep 10
            done
            
            if [ $health_attempts -eq $max_attempts ]; then
                log_warning "Application health check timeout"
                log_info "📋 Checking container logs..."
                docker logs --tail 20 masldatlas-test
            fi
        else
            log_error "Container stopped unexpectedly"
            log_info "📋 Container logs:"
            docker logs masldatlas-test
            exit 1
        fi
    else
        log_error "Failed to start container"
        exit 1
    fi
}

# Test dataset access
test_dataset_access() {
    log_info "📊 Testing dataset access from container..."
    
    # Check if datasets are accessible
    local dataset_output=$(docker exec masldatlas-test sh -c "
        echo 'Checking datasets directory:'
        ls -la /app/datasets/ 2>/dev/null || echo 'Datasets directory not accessible'
        echo ''
        echo 'Checking for .h5ad files:'
        find /app/datasets -name '*.h5ad' 2>/dev/null | wc -l || echo '0'
    ")
    
    echo "$dataset_output"
    
    local h5ad_count=$(echo "$dataset_output" | tail -1)
    if [ "$h5ad_count" -gt 0 ]; then
        log_success "Found $h5ad_count dataset files in container"
    else
        log_warning "No dataset files found in container"
    fi
}

# Cleanup
cleanup() {
    log_info "🧹 Cleaning up test resources..."
    
    # Stop and remove test container
    docker rm -f masldatlas-test 2>/dev/null || true
    
    # Optionally remove test image
    if [ "${1:-}" = "--remove-image" ]; then
        docker rmi masldatlas-volume-test 2>/dev/null || true
        log_info "Test image removed"
    fi
    
    log_success "Cleanup completed"
}

# Show results
show_results() {
    echo ""
    echo "=================================================="
    log_info "🎯 Volume-based Deployment Test Results"
    echo "=================================================="
    
    # Image info
    local image_info=$(docker images masldatlas-volume-test --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}")
    echo "📦 Image Information:"
    echo "$image_info"
    echo ""
    
    # Volume info
    echo "💾 Volume Configuration:"
    echo "   ./datasets          → /app/datasets (read-only)"
    echo "   ./config            → /app/config (read-only)"
    echo "   ./enrichment_sets   → /app/enrichment_sets (read-only)"
    echo ""
    
    # Container status
    if docker ps | grep -q masldatlas-test; then
        log_success "✅ Container is running: http://localhost:3839"
        echo ""
        echo "🛠️ Management commands:"
        echo "   docker logs masldatlas-test              # View logs"
        echo "   docker exec -it masldatlas-test bash     # Enter container"
        echo "   docker stop masldatlas-test              # Stop container"
        echo "   ./scripts/dataset-management/manage_volume.sh status  # Check volumes"
        echo ""
        echo "🧹 To cleanup:"
        echo "   $0 cleanup --remove-image"
    else
        log_warning "❌ Container is not running"
    fi
}

# Main function
main() {
    case "${1:-test}" in
        "test")
            echo "🧪 MASLDatlas Volume-based Deployment Test"
            echo "==========================================="
            check_prerequisites
            test_volume_mount
            build_image
            test_container
            test_dataset_access
            show_results
            ;;
        "cleanup")
            cleanup "${2:-}"
            ;;
        "build-only")
            check_prerequisites
            build_image
            ;;
        "help"|"--help"|"-h")
            echo "Volume-based Deployment Test Script"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  test          Run complete test (default)"
            echo "  build-only    Build image only"
            echo "  cleanup       Remove test container"
            echo "  cleanup --remove-image    Remove container and image"
            echo "  help          Show this help"
            ;;
        *)
            log_error "Unknown command: $1"
            echo "Use '$0 help' for available commands"
            exit 1
            ;;
    esac
}

# Handle Ctrl+C
trap 'log_warning "Test interrupted"; cleanup; exit 1' INT

# Run main function
main "$@"
