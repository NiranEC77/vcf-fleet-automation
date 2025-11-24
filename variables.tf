# VCF Infrastructure Variables
# Based on VCF Terraform Provider: https://registry.terraform.io/providers/vmware/vcf/latest/docs

# ============================================================================
# VCF Provider Configuration
# ============================================================================

variable "use_cloud_builder" {
  description = "Set to true for initial bootstrap with Cloud Builder, false for managing existing VCF with SDDC Manager"
  type        = bool
  default     = true
}

# Cloud Builder / VCF Installer Configuration (for initial bootstrap)
variable "installer_host" {
  description = "Cloud Builder / VCF Installer host IP or FQDN"
  type        = string
  default     = null
}

variable "installer_username" {
  description = "Cloud Builder / VCF Installer username"
  type        = string
  default     = "admin"
}

variable "installer_password" {
  description = "Cloud Builder / VCF Installer password"
  type        = string
  sensitive   = true
  default     = null
}

# SDDC Manager Configuration (for managing existing VCF)
variable "sddc_manager_host" {
  description = "SDDC Manager host IP or FQDN (for existing VCF deployments)"
  type        = string
  default     = null
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
  default     = null
}

variable "allow_unverified_tls" {
  description = "Allow unverified TLS certificates (set to true for self-signed certs or IP addresses)"
  type        = bool
  default     = true
}

# ============================================================================
# Management Domain - Basic Configuration
# ============================================================================

variable "deploy_management_domain" {
  description = "Deploy management domain (only true for initial bootstrap with Cloud Builder)"
  type        = bool
  default     = true
}

variable "instance_id" {
  description = "SDDC Instance ID (management domain name). 3-20 characters, letters, numbers, and hyphens only"
  type        = string
}

variable "management_pool_name" {
  description = "Management network pool name"
  type        = string
}

variable "skip_esx_thumbprint_validation" {
  description = "Skip ESXi thumbprint validation"
  type        = bool
  default     = false
}

variable "ceip_enabled" {
  description = "Enable VCF Customer Experience Improvement Program"
  type        = bool
  default     = true
}

variable "fips_enabled" {
  description = "Enable Federal Information Processing Standards"
  type        = bool
  default     = false
}

variable "vcf_version" {
  description = "VCF version (e.g., 9.0.1.0)"
  type        = string
  default     = null
}

# ============================================================================
# DNS and NTP Configuration
# ============================================================================

variable "dns_domain" {
  description = "DNS domain (e.g., vcf.lab)"
  type        = string
}

variable "dns_nameserver" {
  description = "Primary DNS nameserver IP"
  type        = string
}

variable "dns_secondary_nameserver" {
  description = "Secondary DNS nameserver IP"
  type        = string
  default     = null
}

variable "ntp_servers" {
  description = "List of NTP servers"
  type        = list(string)
}

# ============================================================================
# Management Domain - vCenter Configuration
# ============================================================================

variable "mgmt_vcenter_hostname" {
  description = "Management vCenter hostname"
  type        = string
}

variable "mgmt_vcenter_root_password" {
  description = "Management vCenter root password (8-20 chars)"
  type        = string
  sensitive   = true
}

variable "mgmt_vcenter_vm_size" {
  description = "Management vCenter VM size (tiny, small, medium, large, xlarge)"
  type        = string
  default     = "medium"
}

variable "mgmt_vcenter_storage_size" {
  description = "Management vCenter storage size (lstorage, xlstorage)"
  type        = string
  default     = "lstorage"
}

variable "mgmt_vcenter_ssl_thumbprint" {
  description = "Management vCenter SSL thumbprint"
  type        = string
  default     = null
}

# ============================================================================
# Management Domain - Cluster Configuration
# ============================================================================

variable "mgmt_cluster_name" {
  description = "Management cluster name"
  type        = string
}

variable "mgmt_datacenter_name" {
  description = "Management datacenter name"
  type        = string
}

variable "mgmt_cluster_evc_mode" {
  description = "Management cluster EVC mode"
  type        = string
  default     = null
}

# ============================================================================
# Management Domain - vSAN Configuration
# ============================================================================

variable "mgmt_vsan_datastore_name" {
  description = "Management vSAN datastore name"
  type        = string
}

variable "mgmt_vsan_failures_to_tolerate" {
  description = "Management vSAN failures to tolerate (1 or 2)"
  type        = number
  default     = 1
}

variable "mgmt_vsan_dedup_enabled" {
  description = "Enable vSAN deduplication and compression"
  type        = bool
  default     = true
}

variable "mgmt_vsan_esa_enabled" {
  description = "Enable vSAN ESA"
  type        = bool
  default     = false
}

# ============================================================================
# Management Domain - ESXi Hosts
# ============================================================================

variable "mgmt_esxi_hosts" {
  description = "Management domain ESXi hosts with IP addresses"
  type = list(object({
    hostname       = string
    username       = string
    password       = string
    ssl_thumbprint = string
    ssh_thumbprint = string
  }))
}

# ============================================================================
# Management Domain - Network Configuration
# ============================================================================

variable "mgmt_networks" {
  description = "Management domain network specifications"
  type = list(object({
    network_type    = string
    vlan_id         = number
    mtu             = number
    subnet          = string
    subnet_mask     = string
    gateway         = string
    port_group_key  = string
    teaming_policy  = string
    active_uplinks  = list(string)
    standby_uplinks = list(string)
    ip_ranges = list(object({
      start = string
      end   = string
    }))
  }))
}

# ============================================================================
# Management Domain - DVS Configuration
# ============================================================================

variable "mgmt_dvs_configs" {
  description = "Management domain DVS configurations"
  type = list(object({
    name     = string
    mtu      = number
    networks = list(string)
    vmnic_mappings = list(object({
      vmnic  = string
      uplink = string
    }))
    nsx_switch_config = object({
      transport_zones = list(object({
        transport_type = string
        name           = string
      }))
    })
    nsx_teamings = list(object({
      policy          = string
      active_uplinks  = list(string)
      standby_uplinks = list(string)
    }))
  }))
}

# ============================================================================
# Management Domain - NSX Configuration
# ============================================================================

variable "mgmt_nsx_enabled" {
  description = "Enable NSX for management domain"
  type        = bool
  default     = true
}

variable "mgmt_nsx_manager_size" {
  description = "NSX Manager size (medium, large)"
  type        = string
  default     = "medium"
}

variable "mgmt_nsx_root_password" {
  description = "NSX Manager root password"
  type        = string
  sensitive   = true
}

variable "mgmt_nsx_admin_password" {
  description = "NSX Manager admin password"
  type        = string
  sensitive   = true
}

variable "mgmt_nsx_audit_password" {
  description = "NSX Manager audit password"
  type        = string
  sensitive   = true
}

variable "mgmt_nsx_vip_fqdn" {
  description = "NSX Manager VIP FQDN"
  type        = string
}

variable "mgmt_nsx_transport_vlan_id" {
  description = "NSX transport VLAN ID"
  type        = number
}

variable "mgmt_nsx_managers" {
  description = "NSX Manager hostnames"
  type = list(object({
    hostname = string
  }))
}

variable "mgmt_nsx_ip_pool" {
  description = "NSX IP address pool for TEP"
  type = object({
    name        = string
    description = string
    subnets = list(object({
      cidr    = string
      gateway = string
      ip_ranges = list(object({
        start = string
        end   = string
      }))
    }))
  })
  default = null
}

# ============================================================================
# VCF Automation Configuration
# ============================================================================

variable "vcf_automation_enabled" {
  description = "Enable VCF Automation"
  type        = bool
  default     = true
}

variable "vcf_automation_hostname" {
  description = "VCF Automation hostname"
  type        = string
  default     = null
}

variable "vcf_automation_ip_pool" {
  description = "VCF Automation IP pool (2 IPs for standard, 4 for HA)"
  type        = list(string)
  default     = []
}

variable "vcf_automation_node_prefix" {
  description = "VCF Automation node prefix"
  type        = string
  default     = "vcfa-appliance"
}

variable "vcf_automation_internal_cluster_cidr" {
  description = "VCF Automation internal cluster CIDR (198.18.0.0/15, 240.0.0.0/15, or 250.0.0.0/15)"
  type        = string
  default     = "198.18.0.0/15"
}

variable "vcf_automation_admin_password" {
  description = "VCF Automation admin password"
  type        = string
  sensitive   = true
  default     = null
}

# ============================================================================
# VCF Operations Configuration
# ============================================================================

variable "vcf_operations_enabled" {
  description = "Enable VCF Operations"
  type        = bool
  default     = true
}

variable "vcf_operations_appliance_size" {
  description = "VCF Operations appliance size (xsmall, small, medium, large, xlarge)"
  type        = string
  default     = "medium"
}

variable "vcf_operations_admin_password" {
  description = "VCF Operations admin password"
  type        = string
  sensitive   = true
  default     = null
}

variable "vcf_operations_load_balancer_fqdn" {
  description = "VCF Operations load balancer FQDN"
  type        = string
  default     = null
}

variable "vcf_operations_nodes" {
  description = "VCF Operations nodes"
  type = list(object({
    hostname      = string
    type          = string
    root_password = string
  }))
  default = []
}

# ============================================================================
# VCF Operations Collector Configuration
# ============================================================================

variable "vcf_operations_collector_enabled" {
  description = "Enable VCF Operations Collector"
  type        = bool
  default     = true
}

variable "vcf_operations_collector_hostname" {
  description = "VCF Operations Collector hostname"
  type        = string
  default     = null
}

variable "vcf_operations_collector_appliance_size" {
  description = "VCF Operations Collector appliance size (small, standard)"
  type        = string
  default     = "small"
}

variable "vcf_operations_collector_root_password" {
  description = "VCF Operations Collector root password"
  type        = string
  sensitive   = true
  default     = null
}

# ============================================================================
# VCF Fleet Manager Configuration
# ============================================================================

variable "vcf_fleet_manager_enabled" {
  description = "Enable VCF Fleet Manager"
  type        = bool
  default     = true
}

variable "vcf_fleet_manager_hostname" {
  description = "Fleet Manager hostname"
  type        = string
  default     = null
}

variable "vcf_fleet_manager_root_password" {
  description = "Fleet Manager root password"
  type        = string
  sensitive   = true
  default     = null
}

variable "vcf_fleet_manager_admin_password" {
  description = "Fleet Manager admin password"
  type        = string
  sensitive   = true
  default     = null
}

# ============================================================================
# SDDC Manager Additional Configuration
# ============================================================================

variable "sddc_manager_config_enabled" {
  description = "Configure SDDC Manager settings"
  type        = bool
  default     = false
}

variable "sddc_manager_hostname" {
  description = "SDDC Manager hostname"
  type        = string
  default     = null
}

variable "sddc_manager_root_password" {
  description = "SDDC Manager root password"
  type        = string
  sensitive   = true
  default     = null
}

variable "sddc_manager_ssh_password" {
  description = "SDDC Manager SSH password (vcf user)"
  type        = string
  sensitive   = true
  default     = null
}

variable "sddc_manager_local_password" {
  description = "SDDC Manager local admin password (break glass)"
  type        = string
  sensitive   = true
  default     = null
}

# ============================================================================
# WORKLOAD DOMAIN - Basic Configuration
# ============================================================================

variable "workload_domain_enabled" {
  description = "Enable workload domain creation"
  type        = bool
  default     = true
}

variable "workload_domain_name" {
  description = "Workload domain name (3-20 characters)"
  type        = string
  default     = "wld"
}

variable "workload_domain_org_name" {
  description = "Workload domain organization name"
  type        = string
  default     = null
}

# ============================================================================
# Workload Domain - vCenter Configuration
# ============================================================================

variable "workload_vcenter_name" {
  description = "Workload vCenter name"
  type        = string
  default     = null
}

variable "workload_datacenter_name" {
  description = "Workload datacenter name"
  type        = string
  default     = null
}

variable "workload_vcenter_root_password" {
  description = "Workload vCenter root password (8-20 chars)"
  type        = string
  sensitive   = true
  default     = null
}

variable "workload_vcenter_vm_size" {
  description = "Workload vCenter VM size (tiny, small, medium, large, xlarge)"
  type        = string
  default     = "medium"
}

variable "workload_vcenter_storage_size" {
  description = "Workload vCenter storage size (lstorage, xlstorage)"
  type        = string
  default     = "lstorage"
}

variable "workload_vcenter_ip" {
  description = "Workload vCenter IP address"
  type        = string
  default     = null
}

variable "workload_vcenter_subnet_mask" {
  description = "Workload vCenter subnet mask"
  type        = string
  default     = null
}

variable "workload_vcenter_gateway" {
  description = "Workload vCenter gateway"
  type        = string
  default     = null
}

variable "workload_vcenter_fqdn" {
  description = "Workload vCenter FQDN"
  type        = string
  default     = null
}

# ============================================================================
# Workload Domain - SSO Configuration
# ============================================================================

variable "workload_sso_domain_name" {
  description = "Workload SSO domain name"
  type        = string
  default     = null
}

variable "workload_sso_domain_password" {
  description = "Workload SSO domain password"
  type        = string
  sensitive   = true
  default     = null
}

# ============================================================================
# Workload Domain - NSX Configuration
# ============================================================================

variable "workload_nsx_enabled" {
  description = "Enable NSX for workload domain"
  type        = bool
  default     = true
}

variable "workload_nsx_admin_password" {
  description = "Workload NSX admin password"
  type        = string
  sensitive   = true
  default     = null
}

variable "workload_nsx_audit_password" {
  description = "Workload NSX audit password"
  type        = string
  sensitive   = true
  default     = null
}

variable "workload_nsx_vip" {
  description = "Workload NSX VIP address"
  type        = string
  default     = null
}

variable "workload_nsx_vip_fqdn" {
  description = "Workload NSX VIP FQDN"
  type        = string
  default     = null
}

variable "workload_nsx_form_factor" {
  description = "Workload NSX form factor (small, medium, large)"
  type        = string
  default     = "large"
}

variable "workload_nsx_managers" {
  description = "Workload NSX Manager nodes with IP addresses"
  type = list(object({
    name        = string
    ip_address  = string
    fqdn        = string
    subnet_mask = string
    gateway     = string
  }))
  default = []
}

# ============================================================================
# Workload Domain - Cluster Configuration
# ============================================================================

variable "workload_clusters" {
  description = "Workload domain cluster specifications"
  type = list(object({
    name                      = string
    cluster_image_id          = string
    evc_mode                  = string
    high_availability_enabled = bool
    geneve_vlan_id            = number
    
    vsan_datastore = object({
      datastore_name                = string
      failures_to_tolerate          = number
      dedup_and_compression_enabled = bool
      esa_enabled                   = bool
    })
    
    host_ids = list(string)
    
    vmnic_mappings = list(object({
      vmnic_id = string
      vds_name = string
      uplink   = string
    }))
    
    vds_configs = list(object({
      name          = string
      is_used_by_nsx = bool
      portgroups = list(object({
        name           = string
        transport_type = string
        active_uplinks = list(string)
      }))
    }))
    
    ip_address_pool = object({
      name        = string
      description = string
      subnets = list(object({
        cidr    = string
        gateway = string
        ip_ranges = list(object({
          start = string
          end   = string
        }))
      }))
    })
  }))
  default = []
}
