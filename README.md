# VCF Infrastructure Terraform Configuration

Simplified Terraform configuration for deploying VMware Cloud Foundation (VCF) infrastructure using the official [VMware VCF Terraform Provider](https://registry.terraform.io/providers/vmware/vcf/latest/docs).

## Overview

This Terraform configuration automates VCF deployment in two stages:

1. **Management Domain** (`vcf_instance` resource) - Bootstraps the initial VCF environment including:
   - SDDC Manager
   - Management vCenter
   - Management NSX cluster
   - VCF Automation
   - VCF Operations
   - VCF Operations Collector
   - VCF Fleet Manager
   - Management ESXi cluster with vSAN

2. **Workload Domain** (`vcf_domain` resource) - Creates workload domains including:
   - Workload vCenter
   - Workload NSX cluster
   - Workload ESXi clusters with vSAN
   - Supervisor (vSphere with Tanzu) - optional
   - NSX Edge clusters - separate resource

## Prerequisites

### Before You Begin

1. **VCF Cloud Builder** must have completed the initial bringup
2. **SDDC Manager** must be running and accessible
3. **ESXi hosts** must be prepared and powered on
4. **Network infrastructure** must be configured (VLANs, routing, etc.)
5. **DNS records** must exist for all components
6. **NTP** must be configured and reachable
7. **Terraform** >= 1.4 installed
8. **SSL/SSH thumbprints** collected from all hosts

### Required Information

Before filling out `terraform.tfvars`, gather:

- ✅ SDDC Manager endpoint and credentials
- ✅ All ESXi host FQDNs, IPs, and SSL thumbprints
- ✅ IP addresses for vCenter instances (management and workload)
- ✅ IP addresses for NSX Manager nodes (3 per domain)
- ✅ IP addresses for NSX Edge nodes
- ✅ IP addresses for VCF services (Automation, Operations, Collector, Fleet Manager)
- ✅ IP pools for NSX TEP (Tunnel Endpoint) networks
- ✅ IP ranges for Supervisor control plane (if enabling vSphere with Tanzu)
- ✅ Network configuration (VLANs, subnets, gateways)
- ✅ DNS and NTP servers
- ✅ Passwords for all components

## Quick Start

### 1. Configure Your Environment

Copy the example configuration:

```bash
cd /path/to/vcf-automation
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your environment details. The example file is based on VCF 9.x JSON structure.

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Validate Configuration

```bash
terraform validate
```

### 4. Review Deployment Plan

```bash
terraform plan
```

Review carefully - this will show what will be created.

### 5. Deploy Management Domain

Deploy just the management domain first:

```bash
# Optionally, set workload_domain_enabled = false in terraform.tfvars
terraform apply -target=vcf_instance.management_domain
```

This typically takes 2-4 hours depending on your environment.

### 6. Deploy Workload Domain

After management domain is complete:

```bash
# If you disabled workload domain, re-enable it in terraform.tfvars
terraform apply
```

This will create the workload domain, which typically takes 1-2 hours.

### 7. View Outputs

```bash
terraform output
terraform output deployment_summary
```

## Configuration Structure

### Main Files

```
vcf-automation/
├── main.tf                    # Main infrastructure resources
│   ├── vcf_instance          # Management domain bootstrap
│   └── vcf_domain            # Workload domain
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── terraform.tfvars          # Your configuration (create from example)
├── terraform.tfvars.example  # Example with VCF 9.x structure
└── README.md                 # This file
```

### Key Components in Configuration

#### Management Domain (`vcf_instance`)

The management domain includes:

- **vCenter Configuration**: Management vCenter appliance
- **NSX Configuration**: NSX Manager cluster for management
- **Cluster & vSAN**: Management cluster with vSAN datastore
- **ESXi Hosts**: Minimum 4 hosts for management domain
- **DVS Configuration**: Distributed virtual switches
- **Networks**: Management, vMotion, vSAN, VM_Management networks
- **VCF Automation**: (Optional) VCF Automation appliances
- **VCF Operations**: (Optional) VCF Operations appliance
- **VCF Operations Collector**: (Optional) Log Insight collector
- **Fleet Manager**: (Optional) Fleet Management appliance

#### Workload Domain (`vcf_domain`)

The workload domain includes:

- **vCenter Configuration**: Separate vCenter for workload
- **NSX Configuration**: Separate NSX Manager cluster (or shared)
- **SSO Domain**: Separate SSO domain for workload
- **Clusters**: One or more workload clusters
- **vSAN Datastores**: Per-cluster vSAN configuration
- **DVS Configuration**: Workload distributed virtual switches
- **IP Address Pools**: NSX TEP IP pools per cluster

## IP Address Planning

### Management Domain Example (10.0.0.0/24)

| Component | IP Address | FQDN |
|-----------|------------|------|
| SDDC Manager | 10.0.0.5 | sddc-mgr9.vcf.lab |
| ESXi Host 1 | 10.0.0.11 | esx9-1.vcf.lab |
| ESXi Host 2 | 10.0.0.12 | esx9-2.vcf.lab |
| ESXi Host 3 | 10.0.0.13 | esx9-3.vcf.lab |
| ESXi Host 4 | 10.0.0.14 | esx9-4.vcf.lab |
| Management vCenter | 10.0.0.15 | vcsa9-mgmt.vcf.lab |
| NSX Manager VIP | 10.0.0.20 | nsx9-mgmt.vcf.lab |
| NSX Manager 1 | 10.0.0.21 | nsx9-mgmt-appliance1.vcf.lab |
| VCF Automation | 10.0.0.50-51 | vcf-a.vcf.lab |
| VCF Operations | 10.0.0.60 | vcops9.vcf.lab |
| VCF Ops Collector | 10.0.0.61 | vcops-appliance.vcf.lab |
| Fleet Manager | 10.0.0.62 | fleet9.vcf.lab |

### Workload Domain Example (10.0.0.0/24)

| Component | IP Address | FQDN |
|-----------|------------|------|
| Workload vCenter | 10.0.0.25 | vcsa9-wld.vcf.lab |
| Workload NSX VIP | 10.0.0.30 | nsx9-wld.vcf.lab |
| Workload NSX Manager 1 | 10.0.0.31 | nsx9-wldappliance1.vcf.lab |

### Network Segregation

Typical network layout:

- **Management Network**: 10.0.0.0/24 (VLAN 3139)
- **vMotion Network**: 10.0.4.0/24 (VLAN 3141)
- **vSAN Network**: 10.0.8.0/24 (VLAN 3140)
- **NSX TEP Network**: 10.2.2.0/24 (VLAN 3138)

## Important Notes

### 1. Host IDs for Workload Domain

Workload domain clusters require **host UUIDs**, not hostnames. Get these after commissioning:

```bash
# Query commissioned hosts from SDDC Manager
curl -u "admin@local:password" \
  https://sddc-manager.example.com/v1/hosts

# Or use Terraform data source
data "vcf_host" "commissioned_hosts" {
  # Query available hosts
}
```

Then use the returned UUIDs in your `workload_clusters[].host_ids` list.

### 2. SSL/SSH Thumbprints (OPTIONAL)

**Good News!** Thumbprints are **NOT required** for deployment. The configuration uses:

```hcl
skip_esx_thumbprint_validation = true
```

This automatically bypasses thumbprint validation, making deployment much easier!

#### Optional: Fetch Thumbprints Manually

If you need thumbprints for documentation or security compliance:

```bash
# Use the helper script
./scripts/get-thumbprints.sh esx9-1.vcf.lab esx9-2.vcf.lab vcsa9-mgmt.vcf.lab

# Or manually:
# Get SSL thumbprint (SHA256)
openssl s_client -connect esx-host.example.com:443 </dev/null 2>/dev/null | \
  openssl x509 -fingerprint -sha256 -noout

# Get SSH thumbprint
ssh-keyscan esx-host.example.com 2>/dev/null | \
  ssh-keygen -lf - -E sha256
```

**Note:** Leave `ssl_thumbprint` and `ssh_thumbprint` empty in your configuration - they're automatically skipped!

### 3. Deployment Time

- **Management Domain**: 2-4 hours
- **Workload Domain**: 1-2 hours per domain
- **Total**: 3-6 hours for complete deployment

Monitor progress in SDDC Manager UI.

### 4. NSX Edge Cluster

NSX Edge nodes are deployed separately using the `vcf_edge_cluster` resource. Add this after workload domain creation:

```hcl
resource "vcf_edge_cluster" "workload_edges" {
  # Edge cluster configuration
}
```

### 5. Supervisor (vSphere with Tanzu)

Supervisor configuration is done through the `supervisorActivationSpec` in the workload cluster. This typically requires:

- Supervisor management IPs
- Control plane IPs (3 minimum)
- Service CIDR
- VPC/NSX network configuration

### 6. License Keys

Set `deployWithoutLicenseKeys = true` in the JSON spec, or provide:

- vSphere license keys
- vSAN license keys
- NSX license keys

License keys can be added later through SDDC Manager.

## Customization

### Adding More ESXi Hosts

Add entries to `mgmt_esxi_hosts` or get host IDs for workload clusters:

```hcl
mgmt_esxi_hosts = [
  {
    hostname       = "esx9-5.vcf.lab"
    username       = "root"
    password       = "VMware123!VMware123!"
    ssl_thumbprint = "..."
    ssh_thumbprint = ""
  }
]
```

### Adding More Workload Clusters

Add entries to the `workload_clusters` list in `terraform.tfvars`:

```hcl
workload_clusters = [
  {
    name = "cls-wld9-02"
    # ... cluster configuration
  }
]
```

### Disabling Optional Services

```hcl
vcf_automation_enabled           = false
vcf_operations_enabled           = false
vcf_operations_collector_enabled = false
vcf_fleet_manager_enabled        = false
workload_domain_enabled          = false
```

## Troubleshooting

### View Terraform State

```bash
terraform show
terraform state list
```

### Check SDDC Manager Tasks

Log into SDDC Manager UI and check the Tasks page for deployment progress.

### Terraform Logs

Enable debug logging:

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform apply
```

### Common Issues

1. **Thumbprint Mismatch**: Verify SSL/SSH thumbprints are correct
2. **DNS Resolution**: Ensure all FQDNs resolve correctly
3. **Network Connectivity**: Verify VLAN configuration and routing
4. **Host Not Found**: Ensure hosts are commissioned in SDDC Manager
5. **Timeout**: Management domain deployment can take 2-4 hours

## Destroying Infrastructure

⚠️ **WARNING**: This will destroy your entire VCF environment!

```bash
# Destroy workload domain first
terraform destroy -target=vcf_domain.workload

# Then destroy management domain
terraform destroy -target=vcf_instance.management_domain

# Or destroy everything
terraform destroy
```

## Resources

- [VMware VCF Terraform Provider Documentation](https://registry.terraform.io/providers/vmware/vcf/latest/docs)
- [VCF Documentation](https://docs.vmware.com/en/VMware-Cloud-Foundation/)
- [VCF API Documentation](https://developer.vmware.com/apis/vcf/)
- [Provider GitHub Repository](https://github.com/vmware/terraform-provider-vcf)

## Security Best Practices

1. **Never commit `terraform.tfvars`** - Contains sensitive passwords
2. **Use secrets management** - Consider HashiCorp Vault or similar
3. **Rotate credentials** - Change default passwords after deployment
4. **Limit API access** - Restrict SDDC Manager API access
5. **Enable FIPS** - Set `fips_enabled = true` for compliance
6. **Review security policies** - Configure NSX security policies

## Support

For issues with:
- **Terraform configuration**: Review this README and example files
- **VCF provider**: Check [provider documentation](https://registry.terraform.io/providers/vmware/vcf/latest/docs)
- **VCF product**: Contact VMware Support
