# VCF Fleet Variables
# Development Environment

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# VCF Provider Configuration
variable "sddc_manager_host" {
  description = "SDDC Manager host IP or FQDN"
  type        = string
}

variable "sddc_manager_username" {
  description = "SDDC Manager username"
  type        = string
}

variable "sddc_manager_password" {
  description = "SDDC Manager password"
  type        = string
  sensitive   = true
}

# ESXi Hosts Configuration
variable "esx_hosts" {
  description = "List of ESXi hosts for VCF fleet"
  type = list(object({
    fqdn     = string
    username = string
    password = string
  }))
  default = [
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
}

# Network Configuration - Management
variable "management_gateway" {
  description = "Management network gateway"
  type        = string
  default     = "192.168.10.1"
}

variable "management_mask" {
  description = "Management network subnet mask"
  type        = string
  default     = "255.255.255.0"
}

variable "management_subnet" {
  description = "Management network subnet"
  type        = string
  default     = "192.168.10.0"
}

variable "management_vlan" {
  description = "Management network VLAN ID"
  type        = number
  default     = 100
}

variable "management_ip_start" {
  description = "Management network IP pool start"
  type        = string
  default     = "192.168.10.5"
}

variable "management_ip_end" {
  description = "Management network IP pool end"
  type        = string
  default     = "192.168.10.50"
}

# Network Configuration - vSAN
variable "vsan_gateway" {
  description = "vSAN network gateway"
  type        = string
  default     = "192.168.11.1"
}

variable "vsan_mask" {
  description = "vSAN network subnet mask"
  type        = string
  default     = "255.255.255.0"
}

variable "vsan_subnet" {
  description = "vSAN network subnet"
  type        = string
  default     = "192.168.11.0"
}

variable "vsan_vlan" {
  description = "vSAN network VLAN ID"
  type        = number
  default     = 101
}

variable "vsan_ip_start" {
  description = "vSAN network IP pool start"
  type        = string
  default     = "192.168.11.5"
}

variable "vsan_ip_end" {
  description = "vSAN network IP pool end"
  type        = string
  default     = "192.168.11.50"
}

# Network Configuration - vMotion
variable "vmotion_gateway" {
  description = "vMotion network gateway"
  type        = string
  default     = "192.168.12.1"
}

variable "vmotion_mask" {
  description = "vMotion network subnet mask"
  type        = string
  default     = "255.255.255.0"
}

variable "vmotion_subnet" {
  description = "vMotion network subnet"
  type        = string
  default     = "192.168.12.0"
}

variable "vmotion_vlan" {
  description = "vMotion network VLAN ID"
  type        = number
  default     = 102
}

variable "vmotion_ip_start" {
  description = "vMotion network IP pool start"
  type        = string
  default     = "192.168.12.5"
}

variable "vmotion_ip_end" {
  description = "vMotion network IP pool end"
  type        = string
  default     = "192.168.12.50"
}

# Network Configuration - VCF Automation
variable "vcf_automation_gateway" {
  description = "VCF Automation network gateway"
  type        = string
  default     = "192.168.13.1"
}

variable "vcf_automation_mask" {
  description = "VCF Automation network subnet mask"
  type        = string
  default     = "255.255.255.0"
}

variable "vcf_automation_subnet" {
  description = "VCF Automation network subnet"
  type        = string
  default     = "192.168.13.0"
}

variable "vcf_automation_vlan" {
  description = "VCF Automation network VLAN ID"
  type        = number
  default     = 103
}

variable "vcf_automation_ip_start" {
  description = "VCF Automation network IP pool start"
  type        = string
  default     = "192.168.13.5"
}

variable "vcf_automation_ip_end" {
  description = "VCF Automation network IP pool end"
  type        = string
  default     = "192.168.13.50"
}

# Network Configuration - VCF Operations
variable "vcf_operations_gateway" {
  description = "VCF Operations network gateway"
  type        = string
  default     = "192.168.14.1"
}

variable "vcf_operations_mask" {
  description = "VCF Operations network subnet mask"
  type        = string
  default     = "255.255.255.0"
}

variable "vcf_operations_subnet" {
  description = "VCF Operations network subnet"
  type        = string
  default     = "192.168.14.0"
}

variable "vcf_operations_vlan" {
  description = "VCF Operations network VLAN ID"
  type        = number
  default     = 104
}

variable "vcf_operations_ip_start" {
  description = "VCF Operations network IP pool start"
  type        = string
  default     = "192.168.14.5"
}

variable "vcf_operations_ip_end" {
  description = "VCF Operations network IP pool end"
  type        = string
  default     = "192.168.14.50"
}

# vCenter Configuration - Fleet Domain
variable "vcenter_root_password" {
  description = "vCenter root password for fleet domain"
  type        = string
  sensitive   = true
}

variable "vcenter_vm_size" {
  description = "vCenter VM size (small, medium, large)"
  type        = string
  default     = "medium"
}

variable "vcenter_storage_size" {
  description = "vCenter storage size (sstorage, lstorage)"
  type        = string
  default     = "lstorage"
}

variable "vcenter_ip" {
  description = "vCenter IP address for fleet domain"
  type        = string
  default     = "192.168.10.10"
}

variable "vcenter_subnet_mask" {
  description = "vCenter subnet mask for fleet domain"
  type        = string
  default     = "255.255.255.0"
}

variable "vcenter_gateway" {
  description = "vCenter gateway for fleet domain"
  type        = string
  default     = "192.168.10.1"
}

variable "vcenter_fqdn" {
  description = "vCenter FQDN for fleet domain"
  type        = string
  default     = "vcenter-fleet.dev.example.com"
}

# NSX Configuration - Fleet Domain
variable "nsx_vip" {
  description = "NSX VIP for fleet domain"
  type        = string
  default     = "192.168.10.11"
}

variable "nsx_vip_fqdn" {
  description = "NSX VIP FQDN for fleet domain"
  type        = string
  default     = "nsx-fleet.dev.example.com"
}

variable "nsx_manager_admin_password" {
  description = "NSX Manager admin password for fleet domain"
  type        = string
  sensitive   = true
}

variable "nsx_form_factor" {
  description = "NSX form factor (small, medium, large)"
  type        = string
  default     = "small"
}


variable "nsx_manager_nodes" {
  description = "NSX Manager nodes for fleet domain"
  type = list(object({
    name        = string
    ip_address  = string
    fqdn        = string
    subnet_mask = string
    gateway     = string
  }))
  default = [
    {
      name        = "nsx-fleet-01a"
      ip_address  = "192.168.10.12"
      fqdn        = "nsx-fleet-01a.dev.example.com"
      subnet_mask = "255.255.255.0"
      gateway     = "192.168.10.1"
    },
    {
      name        = "nsx-fleet-01b"
      ip_address  = "192.168.10.13"
      fqdn        = "nsx-fleet-01b.dev.example.com"
      subnet_mask = "255.255.255.0"
      gateway     = "192.168.10.1"
    },
    {
      name        = "nsx-fleet-01c"
      ip_address  = "192.168.10.14"
      fqdn        = "nsx-fleet-01c.dev.example.com"
      subnet_mask = "255.255.255.0"
      gateway     = "192.168.10.1"
    }
  ]
}

# vCenter Configuration - Workload Domain
variable "workload_vcenter_root_password" {
  description = "vCenter root password for workload domain"
  type        = string
  sensitive   = true
}

variable "workload_vcenter_vm_size" {
  description = "vCenter VM size for workload domain"
  type        = string
  default     = "medium"
}

variable "workload_vcenter_storage_size" {
  description = "vCenter storage size for workload domain"
  type        = string
  default     = "lstorage"
}

variable "workload_vcenter_ip" {
  description = "vCenter IP address for workload domain"
  type        = string
  default     = "192.168.20.10"
}

variable "workload_vcenter_subnet_mask" {
  description = "vCenter subnet mask for workload domain"
  type        = string
  default     = "255.255.255.0"
}

variable "workload_vcenter_gateway" {
  description = "vCenter gateway for workload domain"
  type        = string
  default     = "192.168.20.1"
}

variable "workload_vcenter_fqdn" {
  description = "vCenter FQDN for workload domain"
  type        = string
  default     = "vcenter-workload.dev.example.com"
}

# NSX Configuration - Workload Domain
variable "workload_nsx_vip" {
  description = "NSX VIP for workload domain"
  type        = string
  default     = "192.168.20.11"
}

variable "workload_nsx_vip_fqdn" {
  description = "NSX VIP FQDN for workload domain"
  type        = string
  default     = "nsx-workload.dev.example.com"
}

variable "workload_nsx_manager_admin_password" {
  description = "NSX Manager admin password for workload domain"
  type        = string
  sensitive   = true
}

variable "workload_nsx_form_factor" {
  description = "NSX form factor for workload domain"
  type        = string
  default     = "small"
}


variable "workload_nsx_manager_nodes" {
  description = "NSX Manager nodes for workload domain"
  type = list(object({
    name        = string
    ip_address  = string
    fqdn        = string
    subnet_mask = string
    gateway     = string
  }))
  default = [
    {
      name        = "nsx-workload-01a"
      ip_address  = "192.168.20.12"
      fqdn        = "nsx-workload-01a.dev.example.com"
      subnet_mask = "255.255.255.0"
      gateway     = "192.168.20.1"
    },
    {
      name        = "nsx-workload-01b"
      ip_address  = "192.168.20.13"
      fqdn        = "nsx-workload-01b.dev.example.com"
      subnet_mask = "255.255.255.0"
      gateway     = "192.168.20.1"
    },
    {
      name        = "nsx-workload-01c"
      ip_address  = "192.168.20.14"
      fqdn        = "nsx-workload-01c.dev.example.com"
      subnet_mask = "255.255.255.0"
      gateway     = "192.168.20.1"
    }
  ]
}


# vSAN Configuration
variable "vsan_failures_to_tolerate" {
  description = "vSAN failures to tolerate for fleet domain"
  type        = number
  default     = 1
}

variable "workload_vsan_failures_to_tolerate" {
  description = "vSAN failures to tolerate for workload domain"
  type        = number
  default     = 1
}

# Geneve Configuration
variable "geneve_vlan_id" {
  description = "Geneve VLAN ID for fleet domain"
  type        = number
  default     = 2
}

variable "workload_geneve_vlan_id" {
  description = "Geneve VLAN ID for workload domain"
  type        = number
  default     = 3
}
