#!/bin/bash
# VCF Fleet Status Script
# Shows current status of VCF fleet deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENT=${1:-dev}
CONFIG_DIR="$PROJECT_ROOT/configs/$ENVIRONMENT"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check VCF status
check_vcf_status() {
    print_status "Checking VCF fleet status for environment: $ENVIRONMENT"
    
    if [ ! -d "$CONFIG_DIR" ]; then
        print_error "Configuration directory not found: $CONFIG_DIR"
        exit 1
    fi
    
    cd "$CONFIG_DIR"
    
    # Check if Terraform is initialized
    if [ ! -d ".terraform" ]; then
        print_warning "Terraform not initialized. Run 'vcf-deploy.sh' first."
        exit 1
    fi
    
    # Show Terraform state
    print_status "Terraform State:"
    if terraform show -json > /dev/null 2>&1; then
        print_success "Resources are deployed"
        
        # Show resource count
        RESOURCE_COUNT=$(terraform state list | wc -l)
        print_status "Total resources: $RESOURCE_COUNT"
        
        # Show key resources
        print_status "Key Resources:"
        terraform state list | grep -E "(vcf_domain|vcf_cluster|vcf_host|vcf_network_pool)" | while read -r resource; do
            echo "  - $resource"
        done
        
    else
        print_warning "No resources deployed or state not available"
    fi
    
    # Show outputs if available
    print_status "Deployment Outputs:"
    if terraform output -json > /dev/null 2>&1; then
        terraform output
    else
        print_warning "No outputs available"
    fi
    
    # Show plan if there are changes
    print_status "Checking for pending changes:"
    if terraform plan -detailed-exitcode > /dev/null 2>&1; then
        case $? in
            0)
                print_success "No changes needed - infrastructure is up to date"
                ;;
            2)
                print_warning "Changes detected - run 'vcf-deploy.sh' to apply"
                ;;
            *)
                print_error "Error checking for changes"
                ;;
        esac
    else
        print_error "Error running terraform plan"
    fi
}

# Function to show help
show_help() {
    echo "VCF Fleet Status Script"
    echo ""
    echo "Usage: $0 [ENVIRONMENT]"
    echo ""
    echo "Arguments:"
    echo "  ENVIRONMENT    Environment to check (dev, staging, prod). Default: dev"
    echo ""
    echo "This script shows:"
    echo "  - Current Terraform state"
    echo "  - Deployed resources"
    echo "  - Deployment outputs"
    echo "  - Pending changes"
    echo ""
    echo "Examples:"
    echo "  $0 dev         # Check development environment status"
    echo "  $0 staging     # Check staging environment status"
    echo "  $0 prod        # Check production environment status"
}

# Main execution
main() {
    case "${1:-}" in
        -h|--help|help)
            show_help
            exit 0
            ;;
        *)
            check_vcf_status
            ;;
    esac
}

# Run main function with all arguments
main "$@"
