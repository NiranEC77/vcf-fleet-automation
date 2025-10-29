#!/bin/bash
# VCF Automation Setup Script
# Sets up VCF fleet automation with Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

print_status "Setting up VCF Fleet Automation..."

# Check prerequisites
print_status "Checking prerequisites..."

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install Terraform 1.4+"
    print_status "Install with: brew install terraform"
    exit 1
fi

# Check Terraform version
TF_VERSION=$(terraform version -json | jq -r '.terraform_version')
REQUIRED_VERSION="1.4.0"
if ! printf '%s\n%s\n' "$REQUIRED_VERSION" "$TF_VERSION" | sort -V -C; then
    print_error "Terraform version $TF_VERSION is not supported. Please install version $REQUIRED_VERSION or higher"
    exit 1
fi

print_success "Terraform $TF_VERSION found"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3"
    print_status "Install with: brew install python3"
    exit 1
fi

print_success "Python 3 found"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    print_warning "jq is not installed. Installing with brew..."
    if command -v brew &> /dev/null; then
        brew install jq
        print_success "jq installed"
    else
        print_error "Please install jq manually"
        exit 1
    fi
fi

# Check if PyYAML is installed
if ! python3 -c "import yaml" &> /dev/null; then
    print_warning "PyYAML is not installed. Installing..."
    pip3 install PyYAML
    print_success "PyYAML installed"
fi

# Create staging and prod environments
print_status "Creating environment configurations..."

for env in staging prod; do
    if [ ! -d "$SCRIPT_DIR/configs/$env" ]; then
        print_status "Creating $env environment..."
        mkdir -p "$SCRIPT_DIR/configs/$env"
        
        # Copy dev configuration as template
        cp "$SCRIPT_DIR/configs/dev/main.tf" "$SCRIPT_DIR/configs/$env/"
        cp "$SCRIPT_DIR/configs/dev/variables.tf" "$SCRIPT_DIR/configs/$env/"
        cp "$SCRIPT_DIR/configs/dev/terraform.tfvars.example" "$SCRIPT_DIR/configs/$env/"
        
        # Update environment in main.tf
        sed -i.bak "s/default = \"dev\"/default = \"$env\"/g" "$SCRIPT_DIR/configs/$env/variables.tf"
        rm "$SCRIPT_DIR/configs/$env/variables.tf.bak"
        
        print_success "$env environment created"
    else
        print_status "$env environment already exists"
    fi
done

# Create modules directory
print_status "Creating modules directory..."
mkdir -p "$SCRIPT_DIR/modules"

# Create a sample module
cat > "$SCRIPT_DIR/modules/vcf-network-pool/main.tf" << 'EOF'
# VCF Network Pool Module
# Reusable module for creating VCF network pools

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "network_configs" {
  description = "Network configurations"
  type = list(object({
    name        = string
    gateway     = string
    mask        = string
    subnet      = string
    type        = string
    vlan_id     = number
    ip_pools = object({
      start = string
      end   = string
    })
  }))
}

resource "vcf_network_pool" "pool" {
  name = "${var.environment}-network-pool"
  
  dynamic "network" {
    for_each = var.network_configs
    content {
      gateway = network.value.gateway
      mask    = network.value.mask
      mtu     = 9000
      subnet  = network.value.subnet
      type    = network.value.type
      vlan_id = network.value.vlan_id
      ip_pools {
        start = network.value.ip_pools.start
        end   = network.value.ip_pools.end
      }
    }
  }
}

output "pool_id" {
  description = "Network pool ID"
  value       = vcf_network_pool.pool.id
}
EOF

print_success "Modules directory created with sample module"

# Create .gitignore
print_status "Creating .gitignore..."
cat > "$SCRIPT_DIR/.gitignore" << 'EOF'
# Terraform
*.tfstate
*.tfstate.*
*.tfplan
*.tfplan.*
.terraform/
.terraform.lock.hcl

# Sensitive files
*.tfvars
!*.tfvars.example

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
env.bak/
venv.bak/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# VCF State
vcf-state.json
*.yaml
!*.yaml.example
EOF

print_success ".gitignore created"

# Create Makefile for common operations
print_status "Creating Makefile..."
cat > "$SCRIPT_DIR/Makefile" << 'EOF'
# VCF Fleet Automation Makefile

.PHONY: help init plan apply destroy status clean

# Default target
help:
	@echo "VCF Fleet Automation Commands:"
	@echo "  make init ENV=dev          - Initialize Terraform for environment"
	@echo "  make plan ENV=dev          - Create deployment plan"
	@echo "  make apply ENV=dev         - Deploy VCF fleet"
	@echo "  make destroy ENV=dev       - Destroy VCF fleet"
	@echo "  make status ENV=dev        - Show deployment status"
	@echo "  make clean                 - Clean up temporary files"
	@echo ""
	@echo "Python automation:"
	@echo "  make python-init ENV=dev   - Initialize with Python script"
	@echo "  make python-deploy ENV=dev - Deploy with Python script"
	@echo "  make python-status ENV=dev - Get status with Python script"

# Set default environment
ENV ?= dev

# Shell script automation
init:
	./scripts/vcf-deploy.sh $(ENV) --init-only

plan:
	./scripts/vcf-deploy.sh $(ENV) --plan-only

apply:
	./scripts/vcf-deploy.sh $(ENV)

destroy:
	./scripts/vcf-destroy.sh $(ENV)

status:
	./scripts/vcf-status.sh $(ENV)

# Python automation
python-init:
	python3 vcf_automation.py init --environment $(ENV)

python-plan:
	python3 vcf_automation.py plan --environment $(ENV)

python-deploy:
	python3 vcf_automation.py deploy --environment $(ENV)

python-destroy:
	python3 vcf_automation.py destroy --environment $(ENV)

python-status:
	python3 vcf_automation.py status --environment $(ENV)

python-export:
	python3 vcf_automation.py export --environment $(ENV) --output-file vcf-$(ENV)-config.yaml

# Cleanup
clean:
	find . -name "*.tfplan*" -delete
	find . -name "vcf-state.json" -delete
	find . -name "*.yaml" -not -name "*.yaml.example" -delete
	rm -rf .terraform/
EOF

print_success "Makefile created"

# Create a quick start guide
print_status "Creating quick start guide..."
cat > "$SCRIPT_DIR/QUICKSTART.md" << 'EOF'
# VCF Fleet Automation - Quick Start

## 1. Configure Your Environment

```bash
cd configs/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your VCF environment details
```

## 2. Deploy VCF Fleet

### Using Shell Scripts:
```bash
# Deploy to development
./scripts/vcf-deploy.sh dev

# Check status
./scripts/vcf-status.sh dev

# Destroy (if needed)
./scripts/vcf-destroy.sh dev
```

### Using Python Script:
```bash
# Initialize and deploy
python3 vcf_automation.py init --environment dev
python3 vcf_automation.py deploy --environment dev

# Check status
python3 vcf_automation.py status --environment dev

# Export configuration
python3 vcf_automation.py export --environment dev
```

### Using Make:
```bash
# Deploy
make apply ENV=dev

# Check status
make status ENV=dev

# Destroy
make destroy ENV=dev
```

## 3. What Gets Deployed

- **VCF Fleet Domain** with VCF Automation and Operations
- **VCF Workload Domain** with supervisor services enabled
- **Network pools** for all required networks
- **ESXi hosts** configured for VCF management
- **vCenter and NSX** instances for both domains

## 4. Next Steps

- Access your VCF management interfaces
- Configure VCF Automation workflows
- Set up VCF Operations monitoring
- Deploy workloads on the supervisor-enabled domain

## 5. Troubleshooting

- Check logs in the config directory
- Use `terraform plan` to see pending changes
- Validate configuration with `terraform validate`
- Check VCF connectivity with Python script
EOF

print_success "Quick start guide created"

# Final setup
print_status "Setting up final configurations..."

# Make all scripts executable
chmod +x "$SCRIPT_DIR/scripts"/*.sh
chmod +x "$SCRIPT_DIR/vcf_automation.py"

print_success "All scripts made executable"

# Create a sample environment configuration
print_status "Creating sample environment configuration..."
cat > "$SCRIPT_DIR/configs/dev/terraform.tfvars.sample" << 'EOF'
# Sample VCF Configuration
# Copy this to terraform.tfvars and update with your values

# VCF Provider Configuration
sddc_manager_host     = "192.168.1.10"
sddc_manager_username = "administrator@vsphere.local"
sddc_manager_password = "VMware1!"

# ESXi Hosts (update with your hosts)
esx_hosts = [
  {
    fqdn     = "esx01.dev.example.com"
    username = "root"
    password = "VMware1!"
  },
  {
    fqdn     = "esx02.dev.example.com"
    username = "root"
    password = "VMware1!"
  },
  {
    fqdn     = "esx03.dev.example.com"
    username = "root"
    password = "VMware1!"
  }
]

# License Keys (update with your licenses)
esx_license_key              = "YOUR_ESX_LICENSE_KEY"
vsan_license_key             = "YOUR_VSAN_LICENSE_KEY"
nsx_license_key              = "YOUR_NSX_LICENSE_KEY"
workload_vsan_license_key    = "YOUR_WORKLOAD_VSAN_LICENSE_KEY"
workload_nsx_license_key     = "YOUR_WORKLOAD_NSX_LICENSE_KEY"

# Passwords (update with secure passwords)
vcenter_root_password                    = "VMware1!"
nsx_manager_admin_password              = "VMware1!"
workload_vcenter_root_password          = "VMware1!"
workload_nsx_manager_admin_password     = "VMware1!"
EOF

print_success "Sample configuration created"

print_success "VCF Fleet Automation setup completed!"
echo ""
print_status "Next steps:"
echo "1. Edit configs/dev/terraform.tfvars with your VCF environment details"
echo "2. Run: ./scripts/vcf-deploy.sh dev"
echo "3. Or use: python3 vcf_automation.py deploy --environment dev"
echo "4. Check status: ./scripts/vcf-status.sh dev"
echo ""
print_status "Documentation:"
echo "- README.md - Complete documentation"
echo "- QUICKSTART.md - Quick start guide"
echo "- configs/dev/terraform.tfvars.sample - Sample configuration"
echo ""
print_success "Happy VCF automating! 🚀"
