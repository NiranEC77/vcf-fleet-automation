# VCF Fleet Automation with Terraform

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://terraform.io)
[![VMware](https://img.shields.io/badge/VMware-607078.svg?style=for-the-badge&logo=VMware&logoColor=white)](https://www.vmware.com)
[![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](https://www.python.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

This repository contains Terraform configurations and automation scripts for deploying VMware Cloud Foundation (VCF) fleets with VCF Automation, VCF Operations, and workload domains with supervisor services enabled.

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/NiranEC77/vcf-fleet-automation.git
cd vcf-fleet-automation

# Run setup
./setup.sh

# Configure your environment
cd configs/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your VCF details

# Deploy VCF fleet
./scripts/vcf-deploy.sh dev
```

## Overview

This automation deploys:
- **VCF Fleet Domain** with VCF Automation and Operations capabilities
- **VCF Workload Domain** with supervisor services enabled
- **Network pools** for management, vSAN, vMotion, VCF Automation, and VCF Operations
- **ESXi hosts** configured for VCF management
- **vCenter and NSX** instances for both domains

## Prerequisites

### 🏗️ **VCF 9 Bootstrap Prerequisites (Use Case 1: New VCF)**
- **VCF Installer Appliance** (Cloud Builder) for VCF 9
- **ESXi hosts** (minimum 4 for management domain, additional for workload domains)
- **VCF 9.0.0+** (includes VCF Automation and Operations built-in)
- **Valid VMware licenses** (ESXi, vSAN, NSX, VCF)
- **Network infrastructure** with proper VLANs

### 🏗️ **Existing VCF Prerequisites (Use Case 2: Manage Existing)**
- **Existing VCF Environment** with SDDC Manager already deployed
- **SDDC Manager** running and accessible (IP/FQDN, username, password)
- **VCF 9.0.0+** (supports VCF Automation and Operations)

### 🛠️ **Tool Prerequisites**
- Terraform 1.4+
- VCF Terraform Provider 0.17.0+
- Network connectivity to VCF environment

### 📝 **VCF 9 Bootstrap Process**
1. **Deploy VCF Installer Appliance** (Cloud Builder)
2. **Bootstrap VCF Management Domain** (includes VCF Automation/Operations)
3. **Use this automation** to create additional workload domains

## Quick Start

1. **Clone and setup:**
   ```bash
   cd /Users/niranevenchen/Documents/code
   # The VCF provider is already cloned at terraform-provider-vcf/
   ```

2. **Configure your environment:**
   ```bash
   cd vcf-automation/configs/dev
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your VCF environment details
   ```

3. **Deploy VCF fleet:**
   ```bash
   ./scripts/vcf-deploy.sh dev
   ```

## Directory Structure

```
vcf-automation/
├── configs/
│   ├── dev/                    # Development environment
│   │   ├── main.tf            # Main VCF fleet configuration
│   │   ├── variables.tf       # Variable definitions
│   │   └── terraform.tfvars.example  # Example configuration
│   ├── staging/               # Staging environment
│   └── prod/                  # Production environment
├── scripts/
│   ├── vcf-deploy.sh          # Deployment script
│   ├── vcf-destroy.sh         # Destruction script
│   └── vcf-status.sh          # Status checking script
└── modules/                   # Reusable Terraform modules
```

## Configuration

### Required Variables

Edit `configs/dev/terraform.tfvars` with your environment details:

```hcl
# VCF Provider Configuration
sddc_manager_host     = "192.168.1.10"
sddc_manager_username = "administrator@vsphere.local"
sddc_manager_password = "VMware1!"

# ESXi Hosts
esx_hosts = [
  {
    fqdn     = "esx01.dev.example.com"
    username = "root"
    password = "VMware1!"
  }
  # Add more hosts...
]

# License Keys
esx_license_key              = "YOUR_ESX_LICENSE_KEY"
vsan_license_key             = "YOUR_VSAN_LICENSE_KEY"
nsx_license_key              = "YOUR_NSX_LICENSE_KEY"
workload_vsan_license_key    = "YOUR_WORKLOAD_VSAN_LICENSE_KEY"
workload_nsx_license_key     = "YOUR_WORKLOAD_NSX_LICENSE_KEY"
```

### Network Configuration

The automation creates network pools for:
- **Management Network** (VLAN 100)
- **vSAN Network** (VLAN 101) 
- **vMotion Network** (VLAN 102)
- **VCF Automation Network** (VLAN 103)
- **VCF Operations Network** (VLAN 104)

## Usage

### Deploy VCF Fleet

```bash
# Deploy to development environment
./scripts/vcf-deploy.sh dev

# Deploy to staging environment  
./scripts/vcf-deploy.sh staging

# Deploy to production environment
./scripts/vcf-deploy.sh prod
```

### Check Status

```bash
# Check deployment status
./scripts/vcf-status.sh dev
```

### Destroy VCF Fleet

⚠️ **WARNING**: This will permanently destroy your VCF fleet!

```bash
# Destroy development environment
./scripts/vcf-destroy.sh dev
```

## VCF Fleet Components

### Fleet Domain
- **vCenter**: Fleet management vCenter
- **NSX**: Fleet NSX Manager cluster
- **Cluster**: Main fleet management cluster
- **Network Pools**: VCF Automation and Operations networks

### Workload Domain  
- **vCenter**: Workload vCenter with supervisor services
- **NSX**: Workload NSX Manager cluster
- **Cluster**: Workload cluster with supervisor enabled
- **Supervisor Services**: Tanzu Kubernetes Grid, vSphere with Tanzu

## Advanced Configuration

### Customizing Network Configuration

Edit the network variables in `variables.tf`:

```hcl
# Management Network
management_gateway = "192.168.10.1"
management_subnet  = "192.168.10.0"
management_vlan    = 100

# VCF Automation Network
vcf_automation_gateway = "192.168.13.1"
vcf_automation_subnet  = "192.168.13.0"
vcf_automation_vlan    = 103
```

### Adding More ESXi Hosts

Add hosts to the `esx_hosts` variable:

```hcl
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
  }
  # Add more hosts...
]
```

## Troubleshooting

### Common Issues

1. **Provider not found**: Ensure VCF provider is properly configured
2. **Network conflicts**: Check VLAN and IP address assignments
3. **License issues**: Verify all required licenses are valid
4. **Host connectivity**: Ensure ESXi hosts are accessible

### Debugging

Enable Terraform debug logging:

```bash
export TF_LOG=DEBUG
./scripts/vcf-deploy.sh dev
```

### Checking Logs

Terraform logs are stored in the config directory:
```bash
ls -la configs/dev/.terraform/
```

## Security Considerations

- Store sensitive variables in environment variables or secure vaults
- Use strong passwords for all accounts
- Regularly rotate credentials
- Limit network access to VCF management interfaces
- Enable audit logging

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the Mozilla Public License 2.0 - see the [LICENSE](LICENSE) file for details.

## Support

- [VMware Cloud Foundation Documentation](https://docs.vmware.com/en/VMware-Cloud-Foundation/)
- [VCF Terraform Provider Documentation](https://registry.terraform.io/providers/vmware/vcf/latest/docs)
- [VMware Community](https://communities.vmware.com/)

## References

- [VMware Cloud Foundation](https://github.com/vmware/terraform-provider-vcf)
- [Terraform Provider for VCF](https://registry.terraform.io/providers/vmware/vcf/)
- [VCF Automation Documentation](https://docs.vmware.com/en/VMware-Cloud-Foundation/)
- [VCF Operations Documentation](https://docs.vmware.com/en/VMware-Cloud-Foundation/)
