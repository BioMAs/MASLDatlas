#!/bin/bash

# Startup script for MASLDatlas
# Downloads datasets if they don't exist, then starts the Shiny app

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

# Function to check if datasets exist
check_datasets() {
    log_info "Checking for existing datasets..."
    
    local dataset_count=0
    local existing_count=0
    
    if [ -f "config/datasets_sources.json" ]; then
        # Count total datasets
        dataset_count=$(python3 -c "
import json
with open('config/datasets_sources.json', 'r') as f:
    config = json.load(f)
total = 0
for species in config['datasets'].values():
    total += len(species)
print(total)
" 2>/dev/null || echo "0")
        
        # Count existing datasets
        if [ -d "datasets" ]; then
            existing_count=$(find datasets -name "*.h5ad" 2>/dev/null | wc -l | tr -d ' ')
        fi
        
        log_info "Found $existing_count/$dataset_count datasets"
        
        if [ "$existing_count" -eq "$dataset_count" ] && [ "$dataset_count" -gt "0" ]; then
            log_success "All datasets are present"
            return 0
        else
            log_warning "Some datasets are missing ($existing_count/$dataset_count found)"
            return 1
        fi
    else
        log_warning "datasets_sources.json not found, skipping dataset check"
        return 0
    fi
}

# Function to download datasets
download_datasets() {
    log_info "Downloading missing datasets..."
    
    if [ -f "scripts/dataset-management/download_datasets.py" ] && [ -f "config/datasets_sources.json" ]; then
        cd scripts/dataset-management
        if python3 download_datasets.py download --no-parallel; then
            cd /app
            log_success "Dataset download completed successfully"
            return 0
        else
            cd /app
            log_warning "Dataset download completed with some failures"
            return 1
        fi
    else
        log_error "Dataset download tools not found"
        return 1
    fi
}

# Function to start the Shiny app
start_shiny() {
    log_info "Starting MASLDatlas Shiny application..."
    
    # Ensure we're in the correct conda environment
    if [ -n "$CONDA_DEFAULT_ENV" ] && [ "$CONDA_DEFAULT_ENV" = "fibrosis_shiny" ]; then
        log_info "Using conda environment: $CONDA_DEFAULT_ENV"
    else
        log_info "Activating conda environment: fibrosis_shiny"
        source /opt/conda/etc/profile.d/conda.sh
        conda activate fibrosis_shiny
    fi
    
    # Set Shiny options
    export SHINY_HOST=${SHINY_HOST:-0.0.0.0}
    export SHINY_PORT=${SHINY_PORT:-3838}
    
    log_info "Starting Shiny app on $SHINY_HOST:$SHINY_PORT"
    
    # Start the application
    exec R -e "shiny::runApp('/app', host='$SHINY_HOST', port=$SHINY_PORT)"
}

# Main execution flow
main() {
    log_info "🚀 Starting MASLDatlas application..."
    
    # Change to app directory
    cd /app
    
    # Check for datasets only if we have the configuration
    if [ "${SKIP_DATASET_CHECK:-false}" != "true" ]; then
        if ! check_datasets; then
            if [ "${AUTO_DOWNLOAD_DATASETS:-true}" = "true" ]; then
                if ! download_datasets; then
                    log_warning "Dataset download failed, but continuing with application startup"
                fi
            else
                log_info "Auto-download disabled, starting application with existing datasets"
            fi
        fi
    else
        log_info "Dataset check skipped"
    fi
    
    # Start the Shiny application
    start_shiny
}

# Handle different startup modes
case "${1:-start}" in
    "start")
        main
        ;;
    "download-only")
        cd /app
        download_datasets
        ;;
    "check-datasets")
        cd /app/scripts/dataset-management
        python3 download_datasets.py list
        ;;
    "bash")
        exec /bin/bash
        ;;
    *)
        log_error "Unknown command: $1"
        log_info "Available commands: start, download-only, check-datasets, bash"
        exit 1
        ;;
esac
