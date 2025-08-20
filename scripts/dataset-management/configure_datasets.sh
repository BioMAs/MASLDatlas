#!/bin/bash

# Dataset Configuration Helper
# Helps configure dataset sources for different storage providers

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_help() {
    cat << EOF
Dataset Configuration Helper for MASLDatlas

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    setup-zenodo        Setup Zenodo storage configuration
    setup-github        Setup GitHub Releases storage
    setup-s3           Setup AWS S3 storage
    setup-custom       Setup custom URL storage
    validate           Validate current configuration
    generate-hashes    Generate SHA256 hashes for local files
    
Examples:
    $0 setup-zenodo
    $0 setup-github yourusername/MASLDatlas
    $0 validate
    $0 generate-hashes

Storage Options:
    1. Zenodo (Recommended for academic data)
       - Free hosting up to 50GB per record
       - DOI assignment for permanent citation
       - Academic-friendly with version control
    
    2. GitHub Releases
       - Free with GitHub account
       - 2GB per file limit
       - Good for smaller datasets
    
    3. AWS S3 / Google Cloud / Azure
       - Professional cloud storage
       - Requires account and billing setup
       - Best for production environments
    
    4. Custom HTTP Server
       - Your own server or institutional storage
       - Full control but requires maintenance

EOF
}

setup_zenodo() {
    log_info "Setting up Zenodo configuration..."
    
    echo "📚 Zenodo Setup Instructions:"
    echo "1. Go to https://zenodo.org and create an account"
    echo "2. Upload your H5AD files to a new record"
    echo "3. Publish the record to get a DOI and permanent URLs"
    echo "4. Copy the file URLs from the published record"
    echo ""
    echo "Example Zenodo URL format:"
    echo "https://zenodo.org/record/1234567/files/GSE136103.h5ad"
    echo ""
    
    read -p "Enter your Zenodo record ID: " zenodo_record
    
    if [ -n "$zenodo_record" ]; then
        log_info "Generating template for Zenodo record $zenodo_record..."
        
        cat > datasets_sources_zenodo_template.json << EOF
{
  "datasets": {
    "Human": {
      "GSE136103": {
        "url": "https://zenodo.org/record/${zenodo_record}/files/GSE136103.h5ad",
        "sha256": "YOUR_SHA256_HASH_HERE",
        "size_mb": 450,
        "description": "Human liver scRNA-seq dataset GSE136103"
      }
    }
  },
  "config": {
    "download_timeout": 3600,
    "retry_attempts": 3,
    "verify_checksums": true,
    "parallel_downloads": 2,
    "storage_backends": {
      "primary": "zenodo"
    }
  }
}
EOF
        
        log_success "Template created: datasets_sources_zenodo_template.json"
        log_info "Replace YOUR_SHA256_HASH_HERE with actual hashes using: $0 generate-hashes"
    fi
}

setup_github() {
    local repo=${1:-"yourusername/MASLDatlas"}
    
    log_info "Setting up GitHub Releases configuration..."
    
    echo "📚 GitHub Releases Setup Instructions:"
    echo "1. Go to your repository: https://github.com/$repo"
    echo "2. Click 'Releases' tab"
    echo "3. Create a new release (e.g., v1.0-datasets)"
    echo "4. Upload your H5AD files as release assets"
    echo "5. Publish the release"
    echo ""
    echo "Example GitHub Release URL format:"
    echo "https://github.com/$repo/releases/download/v1.0-datasets/GSE136103.h5ad"
    echo ""
    
    read -p "Enter your release tag (e.g., v1.0-datasets): " release_tag
    
    if [ -n "$release_tag" ]; then
        log_info "Generating template for GitHub release $release_tag..."
        
        cat > datasets_sources_github_template.json << EOF
{
  "datasets": {
    "Human": {
      "GSE136103": {
        "url": "https://github.com/$repo/releases/download/${release_tag}/GSE136103.h5ad",
        "sha256": "YOUR_SHA256_HASH_HERE",
        "size_mb": 450,
        "description": "Human liver scRNA-seq dataset GSE136103"
      }
    }
  },
  "config": {
    "download_timeout": 3600,
    "retry_attempts": 3,
    "verify_checksums": true,
    "parallel_downloads": 2,
    "storage_backends": {
      "primary": "github_releases"
    }
  }
}
EOF
        
        log_success "Template created: datasets_sources_github_template.json"
        log_info "Replace YOUR_SHA256_HASH_HERE with actual hashes using: $0 generate-hashes"
    fi
}

setup_s3() {
    log_info "Setting up AWS S3 configuration..."
    
    echo "📚 AWS S3 Setup Instructions:"
    echo "1. Create an AWS account and S3 bucket"
    echo "2. Upload your H5AD files to the bucket"
    echo "3. Configure public read access or presigned URLs"
    echo "4. Get the direct URLs to your files"
    echo ""
    
    read -p "Enter your S3 bucket name: " bucket_name
    read -p "Enter your AWS region (e.g., us-east-1): " aws_region
    
    if [ -n "$bucket_name" ]; then
        cat > datasets_sources_s3_template.json << EOF
{
  "datasets": {
    "Human": {
      "GSE136103": {
        "url": "https://${bucket_name}.s3.${aws_region}.amazonaws.com/datasets/Human/GSE136103.h5ad",
        "sha256": "YOUR_SHA256_HASH_HERE",
        "size_mb": 450,
        "description": "Human liver scRNA-seq dataset GSE136103"
      }
    }
  },
  "config": {
    "download_timeout": 3600,
    "retry_attempts": 3,
    "verify_checksums": true,
    "parallel_downloads": 2,
    "storage_backends": {
      "primary": "s3"
    }
  }
}
EOF
        
        log_success "Template created: datasets_sources_s3_template.json"
    fi
}

setup_custom() {
    log_info "Setting up custom URL configuration..."
    
    echo "📚 Custom URL Setup Instructions:"
    echo "1. Upload your H5AD files to any HTTP-accessible server"
    echo "2. Note the direct download URLs"
    echo "3. Ensure the server supports range requests for large files"
    echo ""
    
    read -p "Enter your base URL (e.g., https://myserver.com/datasets): " base_url
    
    if [ -n "$base_url" ]; then
        cat > datasets_sources_custom_template.json << EOF
{
  "datasets": {
    "Human": {
      "GSE136103": {
        "url": "${base_url}/Human/GSE136103.h5ad",
        "sha256": "YOUR_SHA256_HASH_HERE",
        "size_mb": 450,
        "description": "Human liver scRNA-seq dataset GSE136103"
      }
    }
  },
  "config": {
    "download_timeout": 3600,
    "retry_attempts": 3,
    "verify_checksums": true,
    "parallel_downloads": 2,
    "storage_backends": {
      "primary": "custom"
    }
  }
}
EOF
        
        log_success "Template created: datasets_sources_custom_template.json"
    fi
}

validate_config() {
    log_info "Validating dataset configuration..."
    
    if [ ! -f "datasets_sources.json" ]; then
        log_error "datasets_sources.json not found"
        return 1
    fi
    
    # Check JSON syntax
    if ! python3 -m json.tool datasets_sources.json > /dev/null 2>&1; then
        log_error "Invalid JSON syntax in datasets_sources.json"
        return 1
    fi
    
    # Check required fields
    python3 -c "
import json
import sys

try:
    with open('datasets_sources.json', 'r') as f:
        config = json.load(f)
    
    required_fields = ['datasets', 'config']
    for field in required_fields:
        if field not in config:
            print(f'❌ Missing required field: {field}')
            sys.exit(1)
    
    dataset_count = 0
    for species, datasets in config['datasets'].items():
        for dataset_id, dataset_info in datasets.items():
            dataset_count += 1
            required_keys = ['url', 'description']
            for key in required_keys:
                if key not in dataset_info:
                    print(f'❌ Missing {key} for {species}/{dataset_id}')
                    sys.exit(1)
    
    print(f'✅ Configuration is valid ({dataset_count} datasets configured)')
    
except Exception as e:
    print(f'❌ Validation error: {e}')
    sys.exit(1)
"
    
    log_success "Configuration validation completed"
}

generate_hashes() {
    log_info "Generating SHA256 hashes for local dataset files..."
    
    if [ ! -d "datasets" ]; then
        log_error "datasets directory not found"
        return 1
    fi
    
    echo "# SHA256 Hashes for Dataset Files" > dataset_hashes.txt
    echo "# Generated on $(date)" >> dataset_hashes.txt
    echo "" >> dataset_hashes.txt
    
    find datasets -name "*.h5ad" | while read file; do
        log_info "Calculating hash for $file..."
        hash=$(sha256sum "$file" | cut -d' ' -f1)
        echo "$hash  $file" >> dataset_hashes.txt
        echo "  $file: $hash"
    done
    
    log_success "Hashes saved to dataset_hashes.txt"
}

# Main command handling
case "${1:-help}" in
    "setup-zenodo")
        setup_zenodo
        ;;
    "setup-github")
        setup_github "$2"
        ;;
    "setup-s3")
        setup_s3
        ;;
    "setup-custom")
        setup_custom
        ;;
    "validate")
        validate_config
        ;;
    "generate-hashes")
        generate_hashes
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
