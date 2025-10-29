#!/bin/bash
# VCF Fleet Destruction Script
# Destroys VCF fleet deployment (use with extreme caution!)

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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        exit 1
    fi
    
    # Check if config directory exists
    if [ ! -d "$CONFIG_DIR" ]; then
        print_error "Configuration directory not found: $CONFIG_DIR"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to destroy VCF fleet
destroy_vcf_fleet() {
    print_error "⚠️  WARNING: This will DESTROY your VCF fleet deployment!"
    print_error "This action will:"
    print_error "  - Remove all VCF domains and clusters"
    print_error "  - Remove all hosts from VCF management"
    print_error "  - Remove network pools and configurations"
    print_error "  - This action CANNOT be undone!"
    echo ""
    
    # Double confirmation
    print_warning "Type 'DESTROY' to confirm destruction of environment: $ENVIRONMENT"
    read -p "Confirmation: " confirm1
    
    if [ "$confirm1" != "DESTROY" ]; then
        print_status "Destruction cancelled by user"
        exit 0
    fi
    
    print_warning "Are you absolutely sure? Type 'YES' to proceed:"
    read -p "Final confirmation: " confirm2
    
    if [ "$confirm2" != "YES" ]; then
        print_status "Destruction cancelled by user"
        exit 0
    fi
    
    check_prerequisites
    
    print_status "Starting VCF fleet destruction for environment: $ENVIRONMENT"
    cd "$CONFIG_DIR"
    
    # Initialize if needed
    if [ ! -d ".terraform" ]; then
        terraform init
    fi
    
    # Destroy with auto-approve
    print_status "Destroying VCF fleet resources..."
    terraform destroy -auto-approve
    
    print_success "VCF fleet destruction completed!"
    print_warning "Please verify that all resources have been properly removed"
}

# Function to show help
show_help() {
    echo "VCF Fleet Destruction Script"
    echo ""
    echo "Usage: $0 [ENVIRONMENT]"
    echo ""
    echo "Arguments:"
    echo "  ENVIRONMENT    Environment to destroy (dev, staging, prod). Default: dev"
    echo ""
    echo "⚠️  WARNING: This script will permanently destroy your VCF fleet!"
    echo "   Make sure you have backups and are certain you want to proceed."
    echo ""
    echo "Examples:"
    echo "  $0 dev         # Destroy development environment"
    echo "  $0 staging     # Destroy staging environment"
    echo "  $0 prod        # Destroy production environment (DANGEROUS!)"
}

# Main execution
main() {
    case "${1:-}" in
        -h|--help|help)
            show_help
            exit 0
            ;;
        *)
            destroy_vcf_fleet
            ;;
    esac
}

# Run main function with all arguments
main "$@"
