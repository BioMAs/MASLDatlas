#!/bin/bash
# Dataset Volume Management Script
# Manages datasets via Docker volumes instead of embedding them in the image

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    echo "=================================================="
    print_status $BLUE "$1"
    echo "=================================================="
}

# Check if datasets directory exists and is accessible
check_datasets_volume() {
    print_header "📊 Checking Datasets Volume"
    
    if [ ! -d "./datasets" ]; then
        print_status $YELLOW "⚠️ Datasets directory doesn't exist, creating it..."
        mkdir -p ./datasets
        mkdir -p ./datasets/{Human,Mouse,Zebrafish,Integrated}
        print_status $GREEN "✅ Created datasets directory structure"
    fi
    
    # Check permissions
    if [ -w "./datasets" ]; then
        print_status $GREEN "✅ Datasets directory is writable"
    else
        print_status $RED "❌ Datasets directory is not writable"
        print_status $YELLOW "💡 Run: sudo chown -R \$(whoami) ./datasets"
        return 1
    fi
    
    # Check for existing datasets
    local dataset_count=$(find ./datasets -name "*.h5ad" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$dataset_count" -gt 0 ]; then
        print_status $GREEN "✅ Found $dataset_count dataset files"
        echo "Datasets found:"
        find ./datasets -name "*.h5ad" -exec basename {} \; | sort
    else
        print_status $YELLOW "⚠️ No dataset files found in ./datasets"
        print_status $BLUE "💡 Datasets will be downloaded when the container starts"
    fi
}

# Download datasets to the local datasets directory
download_datasets_to_volume() {
    print_header "⬇️ Downloading Datasets to Volume"
    
    if [ ! -f "config/datasets_sources.json" ]; then
        print_status $RED "❌ datasets_sources.json not found in config/"
        return 1
    fi
    
    if [ ! -f "scripts/dataset-management/download_datasets.py" ]; then
        print_status $RED "❌ download_datasets.py not found"
        return 1
    fi
    
    print_status $BLUE "🐍 Running dataset downloader..."
    cd scripts/dataset-management
    
    # Set the target directory to the mounted volume
    export DATASETS_DIR="../../datasets"
    
    if python3 download_datasets.py download --no-parallel; then
        cd ../..
        print_status $GREEN "✅ Dataset download completed successfully"
        
        # Show what was downloaded
        local downloaded_count=$(find ./datasets -name "*.h5ad" 2>/dev/null | wc -l | tr -d ' ')
        print_status $GREEN "📊 Downloaded $downloaded_count dataset files"
    else
        cd ../..
        print_status $YELLOW "⚠️ Dataset download completed with some warnings"
        return 1
    fi
}

# List available datasets
list_datasets() {
    print_header "📋 Available Datasets"
    
    if [ -f "config/datasets_sources.json" ]; then
        print_status $BLUE "📖 Configured datasets:"
        python3 -c "
import json
with open('config/datasets_sources.json', 'r') as f:
    config = json.load(f)
for species, datasets in config['datasets'].items():
    print(f'  {species}:')
    for dataset in datasets:
        print(f'    - {dataset[\"name\"]} ({dataset[\"filename\"]})')
" 2>/dev/null || print_status $RED "❌ Error reading datasets configuration"
    fi
    
    print_status $BLUE "💾 Local datasets:"
    if [ -d "./datasets" ]; then
        local found_files=false
        for species_dir in ./datasets/*/; do
            if [ -d "$species_dir" ]; then
                species=$(basename "$species_dir")
                files=$(find "$species_dir" -name "*.h5ad" 2>/dev/null)
                if [ -n "$files" ]; then
                    echo "  $species:"
                    echo "$files" | while read -r file; do
                        filename=$(basename "$file")
                        size=$(du -h "$file" 2>/dev/null | cut -f1)
                        echo "    - $filename ($size)"
                    done
                    found_files=true
                fi
            fi
        done
        
        if [ "$found_files" = false ]; then
            print_status $YELLOW "    No dataset files found"
        fi
    else
        print_status $YELLOW "    Datasets directory doesn't exist"
    fi
}

# Clean datasets directory
clean_datasets() {
    print_header "🗑️ Cleaning Datasets"
    
    echo "This will remove all downloaded datasets from ./datasets/"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -d "./datasets" ]; then
            print_status $YELLOW "🗑️ Removing dataset files..."
            find ./datasets -name "*.h5ad" -delete 2>/dev/null || true
            print_status $GREEN "✅ Dataset files removed"
        else
            print_status $YELLOW "⚠️ Datasets directory doesn't exist"
        fi
    else
        print_status $BLUE "Operation cancelled"
    fi
}

# Test volume mounting with Docker
test_volume_mount() {
    print_header "🧪 Testing Volume Mount"
    
    print_status $BLUE "🐳 Testing Docker volume mount..."
    
    # Check if datasets directory exists
    if [ ! -d "./datasets" ]; then
        mkdir -p ./datasets
        print_status $GREEN "✅ Created datasets directory"
    fi
    
    # Test with a simple container
    if docker run --rm -v "$(pwd)/datasets:/test/datasets" alpine:latest sh -c "
        echo 'Testing volume mount...'
        ls -la /test/datasets || echo 'Directory not accessible'
        echo 'test' > /test/datasets/test.txt
        echo 'Volume mount test completed'
    "; then
        if [ -f "./datasets/test.txt" ]; then
            rm -f "./datasets/test.txt"
            print_status $GREEN "✅ Volume mount test successful"
        else
            print_status $RED "❌ Volume mount test failed - file not created"
            return 1
        fi
    else
        print_status $RED "❌ Docker volume mount test failed"
        return 1
    fi
}

# Show volume status
show_status() {
    print_header "📊 Dataset Volume Status"
    
    echo "📁 Project directory: $(pwd)"
    echo "📊 Datasets directory: $(pwd)/datasets"
    echo ""
    
    # Directory info
    if [ -d "./datasets" ]; then
        local total_size=$(du -sh ./datasets 2>/dev/null | cut -f1)
        local file_count=$(find ./datasets -type f 2>/dev/null | wc -l | tr -d ' ')
        local h5ad_count=$(find ./datasets -name "*.h5ad" 2>/dev/null | wc -l | tr -d ' ')
        
        echo "📈 Directory size: $total_size"
        echo "📄 Total files: $file_count"
        echo "🧬 Dataset files (.h5ad): $h5ad_count"
        echo ""
        
        if [ "$h5ad_count" -gt 0 ]; then
            echo "📋 Dataset files by species:"
            for species_dir in ./datasets/*/; do
                if [ -d "$species_dir" ]; then
                    species=$(basename "$species_dir")
                    local species_count=$(find "$species_dir" -name "*.h5ad" 2>/dev/null | wc -l | tr -d ' ')
                    if [ "$species_count" -gt 0 ]; then
                        echo "  $species: $species_count files"
                    fi
                fi
            done
        fi
    else
        echo "❌ Datasets directory doesn't exist"
    fi
    
    echo ""
    echo "🐳 Docker Compose configuration:"
    if [ -f "docker-compose.yml" ]; then
        echo "  Development: docker-compose.yml"
        grep -A 5 "volumes:" docker-compose.yml | head -6
    fi
    
    if [ -f "docker-compose.prod.yml" ]; then
        echo "  Production: docker-compose.prod.yml"
        grep -A 5 "volumes:" docker-compose.prod.yml | head -6
    fi
}

# Main function
main() {
    case "${1:-status}" in
        "check")
            check_datasets_volume
            ;;
        "download")
            check_datasets_volume
            download_datasets_to_volume
            ;;
        "list")
            list_datasets
            ;;
        "clean")
            clean_datasets
            ;;
        "test")
            test_volume_mount
            ;;
        "status")
            show_status
            ;;
        "help"|"--help"|"-h")
            echo "Dataset Volume Management Script"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  status     Show volume status and configuration (default)"
            echo "  check      Check datasets volume accessibility"
            echo "  download   Download datasets to the volume"
            echo "  list       List available and local datasets"
            echo "  clean      Remove all dataset files from volume"
            echo "  test       Test Docker volume mounting"
            echo "  help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 status              # Show current status"
            echo "  $0 download            # Download datasets to ./datasets"
            echo "  $0 test                # Test Docker volume mount"
            ;;
        *)
            print_status $RED "❌ Unknown command: $1"
            echo "Use '$0 help' for available commands"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
