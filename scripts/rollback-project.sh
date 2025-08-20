#!/bin/bash
# Project Rollback Script
# Rolls back MASLDatlas project from new organized structure to flat structure

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

# Check if this is the new structure
check_new_structure() {
    if [ ! -d "scripts" ] && [ ! -d "config" ]; then
        print_status $YELLOW "⚠️ Project appears to already use flat structure"
        print_status $YELLOW "💡 No rollback needed"
        exit 0
    fi
}

# Create backup of new structure
create_backup() {
    print_header "📦 Creating Backup of New Structure"
    
    backup_dir="new_structure_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Copy organized structure
    if [ -d "scripts" ]; then
        cp -r scripts "$backup_dir/"
    fi
    if [ -d "config" ]; then
        cp -r config "$backup_dir/"
    fi
    if [ -d "tmp" ]; then
        cp -r tmp "$backup_dir/"
    fi
    
    print_status $GREEN "✅ New structure backed up to $backup_dir"
}

# Move files back to root
rollback_files() {
    print_header "🔄 Rolling Back to Flat Structure"
    
    # Move config files back
    if [ -d "config" ]; then
        for file in config/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                mv "$file" "./"
                print_status $GREEN "  ✅ Moved $file → $filename"
            fi
        done
        rmdir config 2>/dev/null || true
    fi
    
    # Move setup scripts back
    if [ -d "scripts/setup" ]; then
        for file in scripts/setup/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                mv "$file" "./"
                print_status $GREEN "  ✅ Moved $file → $filename"
            fi
        done
    fi
    
    # Move deployment scripts back
    if [ -d "scripts/deployment" ]; then
        for file in scripts/deployment/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                mv "$file" "./"
                print_status $GREEN "  ✅ Moved $file → $filename"
            fi
        done
    fi
    
    # Move dataset management scripts back
    if [ -d "scripts/dataset-management" ]; then
        for file in scripts/dataset-management/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                mv "$file" "./"
                print_status $GREEN "  ✅ Moved $file → $filename"
            fi
        done
    fi
    
    # Move testing scripts back
    if [ -d "scripts/testing" ]; then
        for file in scripts/testing/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                mv "$file" "./"
                print_status $GREEN "  ✅ Moved $file → $filename"
            fi
        done
    fi
    
    # Move temp files back
    if [ -d "tmp" ]; then
        for file in tmp/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                mv "$file" "./"
                print_status $GREEN "  ✅ Moved $file → $filename"
            fi
        done
        rmdir tmp 2>/dev/null || true
    fi
    
    # Remove empty scripts directory
    if [ -d "scripts" ]; then
        rmdir scripts/setup scripts/deployment scripts/dataset-management scripts/testing 2>/dev/null || true
        rmdir scripts 2>/dev/null || true
    fi
}

# Update Dockerfile back to old paths
update_dockerfile_rollback() {
    print_header "🐳 Updating Dockerfile for Flat Structure"
    
    if [ -f "Dockerfile" ]; then
        # Simple replacements to revert paths
        if grep -q "scripts/" Dockerfile; then
            print_status $YELLOW "  ⚠️ Dockerfile contains new paths"
            print_status $YELLOW "     Manual update recommended - see original flat structure"
            print_status $YELLOW "     Key changes needed:"
            print_status $YELLOW "       scripts/setup/install_optional_packages.R → install_optional_packages.R"
            print_status $YELLOW "       scripts/dataset-management/ → ./"
            print_status $YELLOW "       config/environment.yml → environment.yml"
        else
            print_status $GREEN "  ✅ Dockerfile appears to use flat structure"
        fi
    fi
}

# Verify rollback
verify_rollback() {
    print_header "✅ Verifying Rollback"
    
    # Check that organized directories are gone
    if [ ! -d "scripts" ] && [ ! -d "config" ]; then
        print_status $GREEN "  ✅ Organized structure removed"
    else
        print_status $YELLOW "  ⚠️ Some organized directories still exist"
    fi
    
    # Check for key files in root
    key_files=("datasets_sources.json" "environment.yml" "deploy-prod.sh" "download_datasets.py")
    found_files=0
    
    for file in "${key_files[@]}"; do
        if [ -f "$file" ]; then
            print_status $GREEN "  ✅ Found $file in root"
            found_files=$((found_files + 1))
        fi
    done
    
    if [ $found_files -gt 0 ]; then
        print_status $GREEN "  ✅ Files successfully moved to flat structure"
    else
        print_status $YELLOW "  ⚠️ No key files found (normal if starting fresh)"
    fi
}

# Show post-rollback instructions
show_post_rollback() {
    print_header "📋 Post-Rollback Instructions"
    
    echo "Rollback completed! Your project now uses the flat structure."
    echo ""
    echo "You can now use the original commands:"
    echo ""
    echo "Development:"
    echo "  python3 test_dataset_download.py"
    echo "  Rscript test_dataset_management.R"
    echo "  ./test_datasets.sh"
    echo ""
    echo "Deployment:"
    echo "  ./deploy-prod.sh domain.com"
    echo "  ./start.sh"
    echo "  ./stop.sh"
    echo ""
    echo "Setup:"
    echo "  Rscript install_optional_packages.R"
    echo "  ./check_conda_packages.sh"
    echo ""
    print_status $YELLOW "⚠️ Note: You may need to manually update Dockerfile paths"
    print_status $YELLOW "   if it was modified for the organized structure."
    echo ""
    print_status $GREEN "🎉 Rollback completed successfully!"
}

# Main rollback function
main() {
    print_header "⏪ MASLDatlas Project Rollback"
    
    echo "This script will rollback your project to the flat directory structure."
    echo "A backup of the organized structure will be created."
    echo ""
    print_status $YELLOW "⚠️ Warning: This will move all files back to the root directory."
    echo ""
    read -p "Continue with rollback? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status $YELLOW "Rollback cancelled."
        exit 0
    fi
    
    check_new_structure
    create_backup
    rollback_files
    update_dockerfile_rollback
    verify_rollback
    show_post_rollback
}

# Handle help flag
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "MASLDatlas Project Rollback Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --dry-run      Show what would be moved without making changes"
    echo ""
    echo "This script rolls back the organized project structure to flat structure."
    echo "Use this if you prefer the original flat directory layout."
    exit 0
fi

# Handle dry-run flag
if [[ "${1:-}" == "--dry-run" ]]; then
    echo "🔍 Dry run mode - showing what would be moved:"
    echo ""
    echo "Files that would be moved to root:"
    echo "  config/* → ./"
    echo "  scripts/setup/* → ./"
    echo "  scripts/deployment/* → ./"
    echo "  scripts/dataset-management/* → ./"
    echo "  scripts/testing/* → ./"
    echo "  tmp/* → ./"
    echo ""
    echo "Directories that would be removed:"
    echo "  config/, scripts/, tmp/"
    echo ""
    echo "Run without --dry-run to perform the rollback."
    exit 0
fi

# Run main function
main "$@"
