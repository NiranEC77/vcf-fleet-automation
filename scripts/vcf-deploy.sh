#!/bin/bash
# VCF Fleet Deployment Script
# Deploys VCF fleet with VCF Automation, Operations, and workload domain with supervisor enabled

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
        print_error "Terraform is not installed. Please install Terraform 1.4+"
        exit 1
    fi
    
    # Check Terraform version
    TF_VERSION=$(terraform version -json | jq -r '.terraform_version')
    REQUIRED_VERSION="1.4.0"
    if ! printf '%s\n%s\n' "$REQUIRED_VERSION" "$TF_VERSION" | sort -V -C; then
        print_error "Terraform version $TF_VERSION is not supported. Please install version $REQUIRED_VERSION or higher"
        exit 1
    fi
    
    # Check if config directory exists
    if [ ! -d "$CONFIG_DIR" ]; then
        print_error "Configuration directory not found: $CONFIG_DIR"
        exit 1
    fi
    
    # Check if terraform.tfvars exists
    if [ ! -f "$CONFIG_DIR/terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Please copy terraform.tfvars.example and update with your values"
        print_status "Copying example file..."
        cp "$CONFIG_DIR/terraform.tfvars.example" "$CONFIG_DIR/terraform.tfvars"
        print_warning "Please edit $CONFIG_DIR/terraform.tfvars with your configuration before running again"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    cd "$CONFIG_DIR"
    
    if [ ! -d ".terraform" ]; then
        terraform init
        print_success "Terraform initialized"
    else
        print_status "Terraform already initialized"
    fi
}

# Function to validate configuration
validate_config() {
    print_status "Validating Terraform configuration..."
    cd "$CONFIG_DIR"
    
    if terraform validate; then
        print_success "Configuration validation passed"
    else
        print_error "Configuration validation failed"
        exit 1
    fi
}

# Function to create execution plan
create_plan() {
    print_status "Creating execution plan..."
    cd "$CONFIG_DIR"
    
    PLAN_FILE="vcf-fleet-${ENVIRONMENT}.tfplan"
    terraform plan -out="$PLAN_FILE"
    print_success "Execution plan created: $PLAN_FILE"
    echo "$PLAN_FILE"
}

# Function to apply changes
apply_changes() {
    local plan_file="$1"
    print_status "Applying VCF fleet deployment..."
    cd "$CONFIG_DIR"
    
    if [ -n "$plan_file" ] && [ -f "$plan_file" ]; then
        terraform apply "$plan_file"
    else
        print_warning "No plan file provided, applying without plan"
        terraform apply -auto-approve
    fi
    
    print_success "VCF fleet deployment completed!"
}

# Function to show outputs
show_outputs() {
    print_status "Retrieving deployment outputs..."
    cd "$CONFIG_DIR"
    
    if terraform output -json > /dev/null 2>&1; then
        print_success "Deployment outputs:"
        terraform output
    else
        print_warning "No outputs available"
    fi
}

# Function to deploy VCF fleet
deploy_vcf_fleet() {
    print_status "Starting VCF fleet deployment for environment: $ENVIRONMENT"
    
    check_prerequisites
    init_terraform
    validate_config
    
    # Ask for confirmation before applying
    print_warning "This will deploy a VCF fleet with:"
    print_warning "  - VCF Fleet Domain with VCF Automation and Operations"
    print_warning "  - VCF Workload Domain with Supervisor Services enabled"
    print_warning "  - Network pools and host configurations"
    echo ""
    read -p "Do you want to continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_status "Deployment cancelled by user"
        exit 0
    fi
    
    local plan_file
    plan_file=$(create_plan)
    apply_changes "$plan_file"
    show_outputs
    
    print_success "VCF fleet deployment completed successfully!"
    print_status "You can now access:"
    print_status "  - Fleet vCenter: Check terraform output for vcenter_fleet_url"
    print_status "  - Workload vCenter: Check terraform output for vcenter_workload_url"
    print_status "  - NSX Fleet: Check terraform output for nsx_fleet_url"
    print_status "  - NSX Workload: Check terraform output for nsx_workload_url"
}

# Function to show help
show_help() {
    echo "VCF Fleet Deployment Script"
    echo ""
    echo "Usage: $0 [ENVIRONMENT]"
    echo ""
    echo "Arguments:"
    echo "  ENVIRONMENT    Environment to deploy (dev, staging, prod). Default: dev"
    echo ""
    echo "Examples:"
    echo "  $0 dev         # Deploy to development environment"
    echo "  $0 staging     # Deploy to staging environment"
    echo "  $0 prod        # Deploy to production environment"
    echo ""
    echo "Prerequisites:"
    echo "  - Terraform 1.4+ installed"
    echo "  - VCF provider configured"
    echo "  - terraform.tfvars file with your configuration"
    echo ""
    echo "Configuration:"
    echo "  - Copy terraform.tfvars.example to terraform.tfvars"
    echo "  - Update terraform.tfvars with your VCF environment details"
    echo "  - Ensure all required licenses and credentials are configured"
}

# Main execution
main() {
    case "${1:-}" in
        -h|--help|help)
            show_help
            exit 0
            ;;
        *)
            deploy_vcf_fleet
            ;;
    esac
}

# Run main function with all arguments
main "$@"
