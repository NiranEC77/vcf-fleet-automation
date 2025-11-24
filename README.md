# VCF Infrastructure Terraform Configuration

This is a simplified Terraform configuration for deploying VMware Cloud Foundation (VCF) infrastructure. All scripts have been removed - you simply configure the variables and run Terraform directly.

## Prerequisites

- VMware Cloud Foundation environment already installed with SDDC Manager running
- Terraform >= 1.4 installed
- Access to SDDC Manager with administrator credentials
- All component IPs and FQDNs planned and documented

## Quick Start

### 1. Configure Your Variables

Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and configure all IP addresses and settings for your environment:

- **Management Domain ESXi Hosts** - IP addresses for management domain hosts
- **Workload Domain ESXi Hosts** - IP addresses for workload domain hosts
- **vCenter Servers** - IPs for management and workload vCenter instances
- **NSX Managers** - IP addresses for NSX Manager nodes (management and workload)
- **NSX Edges** - IP addresses for NSX Edge nodes
- **VCF Automation** - IP address for VCF Automation service
- **VCF Operations** - IP address for VCF Operations service
- **VCF Operations Collector** - IP address for VCF Ops Collector
- **Fleet Manager** - IP address for Fleet Manager
- **Supervisor** - Management and control plane IPs for Supervisor
- **Supervisor Pools** - IP ranges for Supervisor pools

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

### 4. Apply the Configuration

```bash
terraform apply
```

### 5. View Outputs

```bash
terraform output
```

## Configuration Files

### main.tf
Contains all infrastructure resource definitions:
- Network pools
- ESXi hosts (management and workload domains)
- Management domain with vCenter and NSX
- Workload domain with vCenter, NSX, and Supervisor
- VCF services (Automation, Operations, Fleet Manager)
- Supervisor and Supervisor pools

### variables.tf
Comprehensive variable definitions for all components with sensible defaults. All IP addresses and network configuration can be customized.

### outputs.tf
Useful outputs including:
- Domain IDs and names
- All component IP addresses
- Network configuration details

### terraform.tfvars.example
Example configuration file with all variables. Copy to `terraform.tfvars` and customize for your environment.

## IP Address Planning

Make sure you have planned and documented:

1. **Management Domain** (typically 192.168.10.0/24):
   - ESXi hosts: .11, .12, .13
   - vCenter: .15
   - NSX VIP: .20
   - NSX Managers: .21, .22, .23
   - VCF Services: .41-.44

2. **Workload Domain** (typically 192.168.20.0/24):
   - ESXi hosts: .11-.14
   - vCenter: .15
   - NSX VIP: .20
   - NSX Managers: .21, .22, .23
   - NSX Edges: .31, .32
   - Supervisor: .50-.53
   - Supervisor Pools: .60-.100

3. **Infrastructure Networks**:
   - vSAN: 192.168.11.0/24
   - vMotion: 192.168.12.0/24

## Customization

### Adding More ESXi Hosts

Edit the `management_domain_esxi_hosts` or `workload_domain_esxi_hosts` list in `terraform.tfvars`:

```hcl
workload_domain_esxi_hosts = [
  {
    fqdn         = "esx-wkld-05.example.com"
    ip_address   = "192.168.20.15"
    username     = "root"
    password     = "YourESXiPassword!"
    storage_type = "VSAN"
  }
]
```

### Adding More NSX Edges

Add entries to the `nsx_edge_nodes` list in `terraform.tfvars`:

```hcl
nsx_edge_nodes = [
  {
    name        = "nsx-edge-03"
    ip_address  = "192.168.20.33"
    fqdn        = "nsx-edge-03.example.com"
    subnet_mask = "255.255.255.0"
    gateway     = "192.168.20.1"
  }
]
```

### Adding More Supervisor Pools

Add entries to the `supervisor_pools` map in `terraform.tfvars`:

```hcl
supervisor_pools = {
  pool3 = {
    name           = "supervisor-pool-3"
    ip_range_start = "192.168.20.101"
    ip_range_end   = "192.168.20.120"
    subnet_mask    = "255.255.255.0"
    gateway        = "192.168.20.1"
  }
}
```

### Disabling Optional Services

Set the enabled flag to `false` in `terraform.tfvars`:

```hcl
vcf_automation_enabled = false
vcf_operations_enabled = false
fleet_manager_enabled = false
supervisor_enabled = false
```

## Destroying Infrastructure

To destroy all created infrastructure:

```bash
terraform destroy
```

## Troubleshooting

### Viewing Current State

```bash
terraform show
```

### Refreshing State

```bash
terraform refresh
```

### Listing Resources

```bash
terraform state list
```

### Viewing Specific Resource

```bash
terraform state show vcf_domain.management
```

## Security Notes

- Never commit `terraform.tfvars` to version control (it contains passwords)
- Use environment variables or a secrets management tool for sensitive values
- Ensure SDDC Manager API access is secured
- Review all security group and firewall rules

## Support

For issues with the Terraform VCF provider, see:
- [VMware VCF Provider Documentation](https://registry.terraform.io/providers/vmware/vcf/latest/docs)
- [VCF Provider GitHub Repository](https://github.com/vmware/terraform-provider-vcf)
