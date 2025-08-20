#!/bin/bash
# Dataset Management Test Suite
# Comprehensive testing script for the MASLDatlas dataset system

set -e  # Exit on any error

# Get project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if Python is available
check_python() {
    if ! command -v python3 &> /dev/null; then
        print_status $RED "❌ Python 3 is required but not installed"
        exit 1
    fi
    
    # Check required packages
    if ! python3 -c "import requests" &> /dev/null; then
        print_status $YELLOW "⚠️  Installing required Python package: requests"
        pip3 install requests
    fi
}

# Run basic connectivity test
test_connectivity() {
    print_header "🔗 Testing Dataset Connectivity"
    
    cd "$PROJECT_ROOT/scripts/testing"
    if python3 test_dataset_download.py; then
        print_status $GREEN "✅ Connectivity test passed"
        return 0
    else
        print_status $RED "❌ Connectivity test failed"
        return 1
    fi
}

# Run validation test
test_validation() {
    print_header "🔍 Testing System Validation"
    
    cd "$PROJECT_ROOT/scripts/testing"
    if python3 test_complete_download.py --validation-only; then
        print_status $GREEN "✅ Validation test passed"
        return 0
    else
        print_status $RED "❌ Validation test failed"
        return 1
    fi
}

# Run quick download test
test_download() {
    print_header "📥 Testing Quick Download"
    
    print_status $YELLOW "⚠️  This will download the smallest dataset (~392MB)"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$PROJECT_ROOT/scripts/testing"
        if python3 test_complete_download.py --quick-test; then
            print_status $GREEN "✅ Download test passed"
            return 0
        else
            print_status $RED "❌ Download test failed"
            return 1
        fi
    else
        print_status $YELLOW "⏭️  Download test skipped"
        return 0
    fi
}

# Run partial download test
test_partial_download() {
    print_header "🧪 Testing Partial Downloads"
    
    cd "$PROJECT_ROOT/scripts/testing"
    if python3 test_dataset_download.py --download-test; then
        print_status $GREEN "✅ Partial download test passed"
        return 0
    else
        print_status $RED "❌ Partial download test failed"
        return 1
    fi
}

# Update dataset configuration
update_config() {
    print_header "🔧 Updating Dataset Configuration"
    
    cd "$PROJECT_ROOT/scripts/dataset-management"
    if python3 update_dataset_config.py; then
        print_status $GREEN "✅ Configuration updated successfully"
        print_status $YELLOW "💡 Review the output and update config/datasets_sources.json if needed"
        return 0
    else
        print_status $RED "❌ Configuration update failed"
        return 1
    fi
}

# Docker integration test
test_docker() {
    print_header "🐳 Testing Docker Integration"
    
    if ! command -v docker &> /dev/null; then
        print_status $YELLOW "⚠️  Docker not found, skipping Docker tests"
        return 0
    fi
    
    print_status $BLUE "Building Docker image..."
    if docker build -t masldatlas-test . > /dev/null 2>&1; then
        print_status $GREEN "✅ Docker build successful"
        
        print_status $BLUE "Testing dataset validation in container..."
        if docker run --rm masldatlas-test python3 test_dataset_download.py > /dev/null 2>&1; then
            print_status $GREEN "✅ Docker dataset test passed"
            
            # Cleanup
            docker rmi masldatlas-test > /dev/null 2>&1 || true
            return 0
        else
            print_status $RED "❌ Docker dataset test failed"
            return 1
        fi
    else
        print_status $RED "❌ Docker build failed"
        return 1
    fi
}

# Show system information
show_info() {
    print_header "📊 System Information"
    
    echo "Python version: $(python3 --version)"
    echo "Available disk space: $(df -h . | tail -1 | awk '{print $4}')"
    echo "Dataset configuration: $(ls -la $PROJECT_ROOT/config/datasets_sources.json 2>/dev/null || echo 'Not found')"
    
    if [ -f "$PROJECT_ROOT/config/datasets_sources.json" ]; then
        echo "Configured datasets:"
        python3 -c "
import json
with open('$PROJECT_ROOT/config/datasets_sources.json', 'r') as f:
    config = json.load(f)
    total_size = 0
    for species, datasets in config['datasets'].items():
        count = len(datasets)
        size = sum(d.get('size_mb', 0) for d in datasets.values())
        total_size += size
        print(f'  {species}: {count} dataset(s), {size:.1f} MB')
    print(f'Total: {len([d for species in config[\"datasets\"].values() for d in species])} datasets, {total_size:.1f} MB ({total_size/1024:.1f} GB)')
"
    fi
}

# Main menu
show_menu() {
    echo ""
    print_status $BLUE "🧪 MASLDatlas Dataset Test Suite"
    echo ""
    echo "Available options:"
    echo "  1) Quick connectivity test (recommended first)"
    echo "  2) Full validation test"
    echo "  3) Partial download test (1KB samples)"
    echo "  4) Complete download test (downloads smallest dataset)"
    echo "  5) Update dataset configuration from Zenodo"
    echo "  6) Docker integration test"
    echo "  7) Show system information"
    echo "  8) Run all tests (except full download)"
    echo "  9) Run production-ready test suite"
    echo "  0) Exit"
    echo ""
}

# Run all basic tests
run_all_tests() {
    print_header "🚀 Running All Basic Tests"
    
    local tests_passed=0
    local total_tests=4
    
    test_connectivity && ((tests_passed++)) || true
    test_validation && ((tests_passed++)) || true
    test_partial_download && ((tests_passed++)) || true
    test_docker && ((tests_passed++)) || true
    
    print_header "📊 Test Summary"
    echo "Tests passed: $tests_passed/$total_tests"
    
    if [ $tests_passed -eq $total_tests ]; then
        print_status $GREEN "🎉 All tests passed! System is ready for deployment."
        return 0
    else
        print_status $RED "❌ Some tests failed. Please review the output above."
        return 1
    fi
}

# Production test suite
run_production_tests() {
    print_header "🏭 Running Production Test Suite"
    
    local tests_passed=0
    local total_tests=3
    
    test_connectivity && ((tests_passed++)) || true
    test_validation && ((tests_passed++)) || true
    test_partial_download && ((tests_passed++)) || true
    
    print_header "📋 Production Readiness Report"
    echo "Tests passed: $tests_passed/$total_tests"
    
    if [ $tests_passed -eq $total_tests ]; then
        print_status $GREEN "🎉 System is production-ready!"
        echo ""
        echo "Next steps:"
        echo "1. Deploy with: ./deploy-prod.sh your-domain.com"
        echo "2. Monitor logs: docker-compose logs -f"
        echo "3. Test application: https://your-domain.com"
        return 0
    else
        print_status $RED "❌ System is not ready for production deployment."
        echo ""
        echo "Please fix the issues above before deploying."
        return 1
    fi
}

# Main script
main() {
    # Check prerequisites
    check_python
    
    # Show system info
    show_info
    
    # If arguments provided, run specific test
    case "${1:-}" in
        "connectivity"|"connect")
            test_connectivity
            exit $?
            ;;
        "validation"|"validate")
            test_validation
            exit $?
            ;;
        "download")
            test_download
            exit $?
            ;;
        "partial")
            test_partial_download
            exit $?
            ;;
        "update")
            update_config
            exit $?
            ;;
        "docker")
            test_docker
            exit $?
            ;;
        "all")
            run_all_tests
            exit $?
            ;;
        "production"|"prod")
            run_production_tests
            exit $?
            ;;
        "info")
            exit 0
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [test_type]"
            echo ""
            echo "Available test types:"
            echo "  connectivity  - Test dataset connectivity"
            echo "  validation    - Test system validation"
            echo "  download      - Test complete download"
            echo "  partial       - Test partial downloads"
            echo "  update        - Update configuration"
            echo "  docker        - Test Docker integration"
            echo "  all           - Run all basic tests"
            echo "  production    - Run production test suite"
            echo "  info          - Show system information"
            echo "  help          - Show this help"
            echo ""
            echo "If no argument is provided, an interactive menu will be shown."
            exit 0
            ;;
    esac
    
    # Interactive mode
    while true; do
        show_menu
        read -p "Enter your choice (0-9): " choice
        
        case $choice in
            1)
                test_connectivity
                ;;
            2)
                test_validation
                ;;
            3)
                test_partial_download
                ;;
            4)
                test_download
                ;;
            5)
                update_config
                ;;
            6)
                test_docker
                ;;
            7)
                show_info
                ;;
            8)
                run_all_tests
                ;;
            9)
                run_production_tests
                ;;
            0)
                print_status $GREEN "👋 Goodbye!"
                exit 0
                ;;
            *)
                print_status $RED "❌ Invalid option. Please choose 0-9."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function with all arguments
main "$@"
