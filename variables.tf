# VCF Infrastructure Variables

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ============================================================================
# SDDC Manager Configuration
# ============================================================================

variable "sddc_manager_host" {
  description = "SDDC Manager host IP or FQDN"
  type        = string
}

variable "sddc_manager_username" {
  description = "SDDC Manager username"
  type        = string
  default     = "administrator@vsphere.local"
}

variable "sddc_manager_password" {
  description = "SDDC Manager password"
  type        = string
  sensitive   = true
}

# ============================================================================
# Network Configuration
# ============================================================================

variable "management_network" {
  description = "Management network configuration"
  type = object({
    gateway       = string
    mask          = string
    subnet        = string
    vlan_id       = number
    mtu           = number
    ip_pool_start = string
    ip_pool_end   = string
  })
  default = {
    gateway       = "192.168.10.1"
    mask          = "255.255.255.0"
    subnet        = "192.168.10.0"
    vlan_id       = 100
    mtu           = 9000
    ip_pool_start = "192.168.10.50"
    ip_pool_end   = "192.168.10.100"
  }
}

variable "vsan_network" {
  description = "vSAN network configuration"
  type = object({
    gateway       = string
    mask          = string
    subnet        = string
    vlan_id       = number
    mtu           = number
    ip_pool_start = string
    ip_pool_end   = string
  })
  default = {
    gateway       = "192.168.11.1"
    mask          = "255.255.255.0"
    subnet        = "192.168.11.0"
    vlan_id       = 101
    mtu           = 9000
    ip_pool_start = "192.168.11.50"
    ip_pool_end   = "192.168.11.100"
  }
}

variable "vmotion_network" {
  description = "vMotion network configuration"
  type = object({
    gateway       = string
    mask          = string
    subnet        = string
    vlan_id       = number
    mtu           = number
    ip_pool_start = string
    ip_pool_end   = string
  })
  default = {
    gateway       = "192.168.12.1"
    mask          = "255.255.255.0"
    subnet        = "192.168.12.0"
    vlan_id       = 102
    mtu           = 9000
    ip_pool_start = "192.168.12.50"
    ip_pool_end   = "192.168.12.100"
  }
}

# ============================================================================
# Management Domain - ESXi Hosts
# ============================================================================

variable "management_domain_esxi_hosts" {
  description = "ESXi hosts for management domain with IP addresses"
  type = list(object({
    fqdn         = string
    ip_address   = string
    username     = string
    password     = string
    storage_type = string
  }))
  default = [
    {
      fqdn         = "esx-mgmt-01.example.com"
      ip_address   = "192.168.10.11"
      username     = "root"
      password     = "changeme"
      storage_type = "VSAN"
    },
    {
      fqdn         = "esx-mgmt-02.example.com"
      ip_address   = "192.168.10.12"
      username     = "root"
      password     = "changeme"
      storage_type = "VSAN"
    },
    {
      fqdn         = "esx-mgmt-03.example.com"
      ip_address   = "192.168.10.13"
      username     = "root"
      password     = "changeme"
      storage_type = "VSAN"
    }
  ]
}

variable "management_domain_vsan_ftol" {
  description = "vSAN failures to tolerate for management domain"
  type        = number
  default     = 1
}

variable "management_domain_geneve_vlan" {
  description = "Geneve VLAN ID for management domain"
  type        = number
  default     = 2
}

# ============================================================================
# Workload Domain - ESXi Hosts
# ============================================================================

variable "workload_domain_esxi_hosts" {
  description = "ESXi hosts for workload domain with IP addresses"
  type = list(object({
    fqdn         = string
    ip_address   = string
    username     = string
    password     = string
    storage_type = string
  }))
  default = [
    {
      fqdn         = "esx-wkld-01.example.com"
      ip_address   = "192.168.20.11"
      username     = "root"
      password     = "changeme"
      storage_type = "VSAN"
    },
    {
      fqdn         = "esx-wkld-02.example.com"
      ip_address   = "192.168.20.12"
      username     = "root"
      password     = "changeme"
      storage_type = "VSAN"
    },
    {
      fqdn         = "esx-wkld-03.example.com"
      ip_address   = "192.168.20.13"
      username     = "root"
      password     = "changeme"
      storage_type = "VSAN"
    },
    {
      fqdn         = "esx-wkld-04.example.com"
      ip_address   = "192.168.20.14"
      username     = "root"
      password     = "changeme"
      storage_type = "VSAN"
    }
  ]
}

variable "workload_domain_vsan_ftol" {
  description = "vSAN failures to tolerate for workload domain"
  type        = number
  default     = 1
}

variable "workload_domain_geneve_vlan" {
  description = "Geneve VLAN ID for workload domain"
  type        = number
  default     = 3
}

# ============================================================================
# Management Domain - vCenter Configuration
# ============================================================================

variable "management_vcenter" {
  description = "Management domain vCenter configuration"
  type = object({
    name            = string
    datacenter_name = string
    root_password   = string
    vm_size         = string
    storage_size    = string
    ip_address      = string
    subnet_mask     = string
    gateway         = string
    fqdn            = string
  })
  sensitive = true
}

# ============================================================================
# Workload Domain - vCenter Configuration
# ============================================================================

variable "workload_vcenter" {
  description = "Workload domain vCenter configuration"
  type = object({
    name            = string
    datacenter_name = string
    root_password   = string
    vm_size         = string
    storage_size    = string
    ip_address      = string
    subnet_mask     = string
    gateway         = string
    fqdn            = string
  })
  sensitive = true
}

# ============================================================================
# Management Domain - NSX Configuration
# ============================================================================

variable "management_nsx" {
  description = "Management domain NSX configuration"
  type = object({
    vip            = string
    vip_fqdn       = string
    admin_password = string
    form_factor    = string
  })
  sensitive = true
}

variable "management_nsx_managers" {
  description = "NSX Manager nodes for management domain"
  type = list(object({
    name        = string
    ip_address  = string
    fqdn        = string
    subnet_mask = string
    gateway     = string
  }))
  default = [
    {
      name        = "nsx-mgmt-01"
      ip_address  = "192.168.10.21"
      fqdn        = "nsx-mgmt-01.example.com"
      subnet_mask = "255.255.255.0"
      gateway     = "192.168.10.1"
    },
    {
      name        = "nsx-mgmt-02"
      ip_address  = "192.168.10.22"
      fqdn        = "nsx-mgmt-02.example.com"
      subnet_mask = "255.255.255.0"
      gateway     = "192.168.10.1"
    },
    {
      name        = "nsx-mgmt-03"
      ip_address  = "192.168.10.23"
      fqdn        = "nsx-mgmt-03.example.com"
      subnet_mask = "255.255.255.0"
      gateway     = "192.168.10.1"
    }
  ]
}

# ============================================================================
# Workload Domain - NSX Configuration
# ============================================================================

variable "workload_nsx" {
  description = "Workload domain NSX configuration"
  type = object({
    vip            = string
    vip_fqdn       = string
    admin_password = string
    form_factor    = string
  })
  sensitive = true
}

variable "workload_nsx_managers" {
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
      name        = "nsx-wkld-01"
      ip_address  = "192.168.20.21"
      fqdn        = "nsx-wkld-01.example.com"
      subnet_mask = "255.255.255.0"
      gateway     = "192.168.20.1"
    },
    {
      name        = "nsx-wkld-02"
      ip_address  = "192.168.20.22"
      fqdn        = "nsx-wkld-02.example.com"
      subnet_mask = "255.255.255.0"
      gateway     = "192.168.20.1"
    },
    {
      name        = "nsx-wkld-03"
      ip_address  = "192.168.20.23"
      fqdn        = "nsx-wkld-03.example.com"
      subnet_mask = "255.255.255.0"
      gateway     = "192.168.20.1"
    }
  ]
}

# ============================================================================
# NSX Edge Nodes Configuration
# ============================================================================

variable "nsx_edge_nodes" {
  description = "NSX Edge nodes for workload domain"
  type = list(object({
    name        = string
    ip_address  = string
    fqdn        = string
    subnet_mask = string
    gateway     = string
  }))
  default = [
    {
      name        = "nsx-edge-01"
      ip_address  = "192.168.20.31"
      fqdn        = "nsx-edge-01.example.com"
      subnet_mask = "255.255.255.0"
      gateway     = "192.168.20.1"
    },
    {
      name        = "nsx-edge-02"
      ip_address  = "192.168.20.32"
      fqdn        = "nsx-edge-02.example.com"
      subnet_mask = "255.255.255.0"
      gateway     = "192.168.20.1"
    }
  ]
}

# ============================================================================
# VCF Automation Configuration
# ============================================================================

variable "vcf_automation_enabled" {
  description = "Enable VCF Automation service"
  type        = bool
  default     = true
}

variable "vcf_automation_ip" {
  description = "VCF Automation IP address"
  type        = string
  default     = "192.168.10.41"
}

variable "vcf_automation_fqdn" {
  description = "VCF Automation FQDN"
  type        = string
  default     = "vcf-automation.example.com"
}

variable "vcf_automation_subnet_mask" {
  description = "VCF Automation subnet mask"
  type        = string
  default     = "255.255.255.0"
}

variable "vcf_automation_gateway" {
  description = "VCF Automation gateway"
  type        = string
  default     = "192.168.10.1"
}

# ============================================================================
# VCF Operations Configuration
# ============================================================================

variable "vcf_operations_enabled" {
  description = "Enable VCF Operations service"
  type        = bool
  default     = true
}

variable "vcf_operations_ip" {
  description = "VCF Operations IP address"
  type        = string
  default     = "192.168.10.42"
}

variable "vcf_operations_fqdn" {
  description = "VCF Operations FQDN"
  type        = string
  default     = "vcf-operations.example.com"
}

variable "vcf_operations_subnet_mask" {
  description = "VCF Operations subnet mask"
  type        = string
  default     = "255.255.255.0"
}

variable "vcf_operations_gateway" {
  description = "VCF Operations gateway"
  type        = string
  default     = "192.168.10.1"
}

# ============================================================================
# VCF Operations Collector Configuration
# ============================================================================

variable "vcf_operations_collector_enabled" {
  description = "Enable VCF Operations Collector service"
  type        = bool
  default     = true
}

variable "vcf_operations_collector_ip" {
  description = "VCF Operations Collector IP address"
  type        = string
  default     = "192.168.10.43"
}

variable "vcf_operations_collector_fqdn" {
  description = "VCF Operations Collector FQDN"
  type        = string
  default     = "vcf-ops-collector.example.com"
}

variable "vcf_operations_collector_subnet_mask" {
  description = "VCF Operations Collector subnet mask"
  type        = string
  default     = "255.255.255.0"
}

variable "vcf_operations_collector_gateway" {
  description = "VCF Operations Collector gateway"
  type        = string
  default     = "192.168.10.1"
}

# ============================================================================
# Fleet Manager Configuration
# ============================================================================

variable "fleet_manager_enabled" {
  description = "Enable Fleet Manager service"
  type        = bool
  default     = true
}

variable "fleet_manager_ip" {
  description = "Fleet Manager IP address"
  type        = string
  default     = "192.168.10.44"
}

variable "fleet_manager_fqdn" {
  description = "Fleet Manager FQDN"
  type        = string
  default     = "fleet-manager.example.com"
}

variable "fleet_manager_subnet_mask" {
  description = "Fleet Manager subnet mask"
  type        = string
  default     = "255.255.255.0"
}

variable "fleet_manager_gateway" {
  description = "Fleet Manager gateway"
  type        = string
  default     = "192.168.10.1"
}

# ============================================================================
# Supervisor Configuration
# ============================================================================

variable "supervisor_enabled" {
  description = "Enable Supervisor for workload domain"
  type        = bool
  default     = true
}

variable "supervisor_management_ip" {
  description = "Supervisor management IP address"
  type        = string
  default     = "192.168.20.50"
}

variable "supervisor_control_plane_ips" {
  description = "Supervisor control plane IP addresses"
  type        = list(string)
  default     = ["192.168.20.51", "192.168.20.52", "192.168.20.53"]
}

variable "supervisor_subnet_mask" {
  description = "Supervisor subnet mask"
  type        = string
  default     = "255.255.255.0"
}

variable "supervisor_gateway" {
  description = "Supervisor gateway"
  type        = string
  default     = "192.168.20.1"
}

variable "supervisor_dns_servers" {
  description = "Supervisor DNS servers"
  type        = list(string)
  default     = ["192.168.10.2", "192.168.10.3"]
}

variable "supervisor_ntp_servers" {
  description = "Supervisor NTP servers"
  type        = list(string)
  default     = ["time.vmware.com"]
}

# ============================================================================
# Supervisor Pools Configuration
# ============================================================================

variable "supervisor_pools" {
  description = "Supervisor pools configuration with IP ranges"
  type = map(object({
    name           = string
    ip_range_start = string
    ip_range_end   = string
    subnet_mask    = string
    gateway        = string
  }))
  default = {
    pool1 = {
      name           = "supervisor-pool-1"
      ip_range_start = "192.168.20.60"
      ip_range_end   = "192.168.20.80"
      subnet_mask    = "255.255.255.0"
      gateway        = "192.168.20.1"
    },
    pool2 = {
      name           = "supervisor-pool-2"
      ip_range_start = "192.168.20.81"
      ip_range_end   = "192.168.20.100"
      subnet_mask    = "255.255.255.0"
      gateway        = "192.168.20.1"
    }
  }
}

