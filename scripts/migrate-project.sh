#!/bin/bash
# Project Migration Script
# Migrates old MASLDatlas structure to new organized structure

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

# Check if this is already the new structure
check_current_structure() {
    if [ -d "scripts" ] && [ -d "config" ]; then
        print_status $GREEN "✅ Project already uses new structure"
        print_status $YELLOW "💡 If you need to update paths in custom scripts, see docs/migration-guide.md"
        exit 0
    fi
}

# Create backup
create_backup() {
    print_header "📦 Creating Backup"
    
    backup_dir="backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Copy files that will be moved
    files_to_backup=(
        "datasets_sources.json"
        "datasets_config.json" 
        "environment.yml"
        "reticulate_create_env.R"
        "install_optional_packages.R"
        "check_dependencies.R"
        "check_conda_packages.sh"
        "deploy-prod.sh"
        "start.sh"
        "stop.sh"
        "rebuild.sh"
        "startup.sh"
        "download_datasets.py"
        "update_dataset_config.py"
        "configure_datasets.sh"
        "dataset_manager.R"
        "test_"*.py
        "test_"*.R
        "test_"*.sh
        "*.rds"
        "*.tmp"
    )
    
    for pattern in "${files_to_backup[@]}"; do
        if ls $pattern 2>/dev/null; then
            cp -r $pattern "$backup_dir/" 2>/dev/null || true
        fi
    done
    
    print_status $GREEN "✅ Backup created in $backup_dir"
}

# Create new directory structure
create_directories() {
    print_header "📁 Creating New Directory Structure"
    
    directories=(
        "config"
        "scripts/setup"
        "scripts/deployment" 
        "scripts/dataset-management"
        "scripts/testing"
        "tmp"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        print_status $GREEN "  ✅ Created $dir/"
    done
}

# Move configuration files
move_config_files() {
    print_header "⚙️ Moving Configuration Files"
    
    config_files=(
        "datasets_sources.json"
        "datasets_config.json"
        "environment.yml"
    )
    
    for file in "${config_files[@]}"; do
        if [ -f "$file" ]; then
            mv "$file" "config/"
            print_status $GREEN "  ✅ Moved $file → config/"
        fi
    done
}

# Move setup scripts
move_setup_scripts() {
    print_header "🔧 Moving Setup Scripts"
    
    setup_files=(
        "reticulate_create_env.R"
        "install_optional_packages.R" 
        "check_dependencies.R"
        "check_conda_packages.sh"
    )
    
    for file in "${setup_files[@]}"; do
        if [ -f "$file" ]; then
            mv "$file" "scripts/setup/"
            print_status $GREEN "  ✅ Moved $file → scripts/setup/"
        fi
    done
}

# Move deployment scripts
move_deployment_scripts() {
    print_header "🚀 Moving Deployment Scripts"
    
    deployment_files=(
        "deploy-prod.sh"
        "start.sh"
        "stop.sh" 
        "rebuild.sh"
        "startup.sh"
    )
    
    for file in "${deployment_files[@]}"; do
        if [ -f "$file" ]; then
            mv "$file" "scripts/deployment/"
            chmod +x "scripts/deployment/$file"
            print_status $GREEN "  ✅ Moved $file → scripts/deployment/"
        fi
    done
}

# Move dataset management scripts
move_dataset_scripts() {
    print_header "📊 Moving Dataset Management Scripts"
    
    dataset_files=(
        "download_datasets.py"
        "update_dataset_config.py"
        "configure_datasets.sh"
        "dataset_manager.R"
    )
    
    for file in "${dataset_files[@]}"; do
        if [ -f "$file" ]; then
            mv "$file" "scripts/dataset-management/"
            [ "${file##*.}" = "sh" ] && chmod +x "scripts/dataset-management/$file"
            print_status $GREEN "  ✅ Moved $file → scripts/dataset-management/"
        fi
    done
}

# Move testing scripts
move_testing_scripts() {
    print_header "🧪 Moving Testing Scripts"
    
    # Move test files
    for file in test_*.py test_*.R test_*.sh; do
        if [ -f "$file" ]; then
            mv "$file" "scripts/testing/"
            [ "${file##*.}" = "sh" ] && chmod +x "scripts/testing/$file"
            print_status $GREEN "  ✅ Moved $file → scripts/testing/"
        fi
    done
}

# Move temporary files
move_temp_files() {
    print_header "🗂️ Moving Temporary Files"
    
    # Move RDS and temporary files
    for pattern in "*.rds" "*.tmp" "*.temp"; do
        for file in $pattern; do
            if [ -f "$file" ] && [ "$file" != "$pattern" ]; then
                mv "$file" "tmp/"
                print_status $GREEN "  ✅ Moved $file → tmp/"
            fi
        done
    done
}

# Update Dockerfile paths (if needed)
update_dockerfile() {
    print_header "🐳 Updating Dockerfile"
    
    if [ -f "Dockerfile" ]; then
        # Check if already updated
        if grep -q "scripts/setup/install_optional_packages.R" Dockerfile; then
            print_status $YELLOW "  ⚠️ Dockerfile already updated"
        else
            print_status $YELLOW "  ⚠️ Dockerfile may need manual updates"
            print_status $YELLOW "     See docs/migration-guide.md for details"
        fi
    fi
}

# Verify migration
verify_migration() {
    print_header "✅ Verifying Migration"
    
    required_dirs=("config" "scripts/setup" "scripts/deployment" "scripts/dataset-management" "scripts/testing")
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "$dir" ]; then
            print_status $GREEN "  ✅ $dir/ exists"
        else
            print_status $RED "  ❌ $dir/ missing"
            return 1
        fi
    done
    
    # Check for key files
    if [ -f "config/datasets_sources.json" ] || [ -f "config/datasets_config.json" ]; then
        print_status $GREEN "  ✅ Configuration files found"
    else
        print_status $YELLOW "  ⚠️ No configuration files found (normal for new projects)"
    fi
    
    # Test the new structure
    if [ -f "scripts/testing/test_datasets.sh" ]; then
        print_status $BLUE "  🧪 Testing new structure..."
        if ./scripts/testing/test_datasets.sh info > /dev/null 2>&1; then
            print_status $GREEN "  ✅ New structure test passed"
        else
            print_status $YELLOW "  ⚠️ New structure test had warnings (check manually)"
        fi
    fi
}

# Show next steps
show_next_steps() {
    print_header "🎯 Next Steps"
    
    echo "Migration completed successfully! Here's what to do next:"
    echo ""
    echo "1. Test the new structure:"
    echo "   ./scripts/testing/test_datasets.sh production"
    echo ""
    echo "2. Update your commands (see docs/migration-guide.md):"
    echo "   Old: python3 test_dataset_download.py"
    echo "   New: python3 scripts/testing/test_dataset_download.py"
    echo ""
    echo "3. Update deployment:"
    echo "   Old: ./deploy-prod.sh domain.com"
    echo "   New: ./scripts/deployment/deploy-prod.sh domain.com"
    echo ""
    echo "4. Review the project structure:"
    echo "   cat PROJECT_STRUCTURE.md"
    echo ""
    echo "5. If you have custom scripts, update their paths:"
    echo "   See docs/migration-guide.md for details"
    echo ""
    print_status $GREEN "🎉 Migration completed! Your project is now organized and ready."
}

# Main migration function
main() {
    print_header "🔄 MASLDatlas Project Migration"
    
    echo "This script will reorganize your project structure for better maintainability."
    echo "A backup will be created before making any changes."
    echo ""
    read -p "Continue with migration? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status $YELLOW "Migration cancelled."
        exit 0
    fi
    
    check_current_structure
    create_backup
    create_directories
    move_config_files
    move_setup_scripts
    move_deployment_scripts
    move_dataset_scripts
    move_testing_scripts
    move_temp_files
    update_dockerfile
    verify_migration
    show_next_steps
}

# Handle help flag
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "MASLDatlas Project Migration Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --dry-run      Show what would be moved without making changes"
    echo ""
    echo "This script reorganizes the project structure for better maintainability."
    echo "See docs/migration-guide.md for detailed information."
    exit 0
fi

# Handle dry-run flag
if [[ "${1:-}" == "--dry-run" ]]; then
    echo "🔍 Dry run mode - showing what would be moved:"
    echo ""
    echo "Files that would be moved:"
    echo "  datasets_sources.json → config/"
    echo "  environment.yml → config/"
    echo "  reticulate_create_env.R → scripts/setup/"
    echo "  deploy-prod.sh → scripts/deployment/"
    echo "  download_datasets.py → scripts/dataset-management/"
    echo "  test_*.py → scripts/testing/"
    echo "  *.rds → tmp/"
    echo ""
    echo "Directories that would be created:"
    echo "  config/, scripts/, tmp/"
    echo ""
    echo "Run without --dry-run to perform the migration."
    exit 0
fi

# Run main function
main "$@"
