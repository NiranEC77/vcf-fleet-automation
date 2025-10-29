# VCF Fleet Deployment with VCF Automation and Operations
# Development Environment Configuration
# 
# PREREQUISITE: VCF must be installed first using VMware Cloud Builder
# This automation requires an existing VCF environment with SDDC Manager running

terraform {
  required_version = ">= 1.4"
  required_providers {
    vcf = {
      source  = "vmware/vcf"
      version = "~> 0.17.0"
    }
  }
}

# VCF Provider Configuration
provider "vcf" {
  sddc_manager_host     = var.sddc_manager_host
  sddc_manager_username = var.sddc_manager_username
  sddc_manager_password = var.sddc_manager_password
}

# Network Pool for VCF Fleet
resource "vcf_network_pool" "fleet_pool" {
  name = "${var.environment}-vcf-fleet-pool"
  
  # Management Network
  network {
    gateway = var.management_gateway
    mask    = var.management_mask
    mtu     = 9000
    subnet  = var.management_subnet
    type    = "MANAGEMENT"
    vlan_id = var.management_vlan
    ip_pools {
      start = var.management_ip_start
      end   = var.management_ip_end
    }
  }
  
  # vSAN Network
  network {
    gateway = var.vsan_gateway
    mask    = var.vsan_mask
    mtu     = 9000
    subnet  = var.vsan_subnet
    type    = "VSAN"
    vlan_id = var.vsan_vlan
    ip_pools {
      start = var.vsan_ip_start
      end   = var.vsan_ip_end
    }
  }
  
  # vMotion Network
  network {
    gateway = var.vmotion_gateway
    mask    = var.vmotion_mask
    mtu     = 9000
    subnet  = var.vmotion_subnet
    type    = "vMotion"
    vlan_id = var.vmotion_vlan
    ip_pools {
      start = var.vmotion_ip_start
      end   = var.vmotion_ip_end
    }
  }
  
  # VCF Automation Network
  network {
    gateway = var.vcf_automation_gateway
    mask    = var.vcf_automation_mask
    mtu     = 9000
    subnet  = var.vcf_automation_subnet
    type    = "VCF_AUTOMATION"
    vlan_id = var.vcf_automation_vlan
    ip_pools {
      start = var.vcf_automation_ip_start
      end   = var.vcf_automation_ip_end
    }
  }
  
  # VCF Operations Network
  network {
    gateway = var.vcf_operations_gateway
    mask    = var.vcf_operations_mask
    mtu     = 9000
    subnet  = var.vcf_operations_subnet
    type    = "VCF_OPERATIONS"
    vlan_id = var.vcf_operations_vlan
    ip_pools {
      start = var.vcf_operations_ip_start
      end   = var.vcf_operations_ip_end
    }
  }
}

# VCF Hosts for Fleet
resource "vcf_host" "fleet_hosts" {
  count = length(var.esx_hosts)
  
  fqdn            = var.esx_hosts[count.index].fqdn
  username        = var.esx_hosts[count.index].username
  password        = var.esx_hosts[count.index].password
  network_pool_id = vcf_network_pool.fleet_pool.id
  storage_type    = "VSAN"
}

# VCF Domain for Fleet Management
resource "vcf_domain" "fleet_domain" {
  name = "${var.environment}-vcf-fleet-domain"
  
  vcenter_configuration {
    name            = "${var.environment}-vcenter"
    datacenter_name = "${var.environment}-datacenter"
    root_password   = var.vcenter_root_password
    vm_size         = var.vcenter_vm_size
    storage_size    = var.vcenter_storage_size
    ip_address      = var.vcenter_ip
    subnet_mask     = var.vcenter_subnet_mask
    gateway         = var.vcenter_gateway
    fqdn            = var.vcenter_fqdn
  }
  
  nsx_configuration {
    vip                        = var.nsx_vip
    vip_fqdn                   = var.nsx_vip_fqdn
    nsx_manager_admin_password = var.nsx_manager_admin_password
    form_factor                = var.nsx_form_factor
    
    dynamic "nsx_manager_node" {
      for_each = var.nsx_manager_nodes
      content {
        name        = nsx_manager_node.value.name
        ip_address  = nsx_manager_node.value.ip_address
        fqdn        = nsx_manager_node.value.fqdn
        subnet_mask = nsx_manager_node.value.subnet_mask
        gateway     = nsx_manager_node.value.gateway
      }
    }
  }
  
  # Main Cluster for Fleet Management
  cluster {
    name = "${var.environment}-fleet-cluster"
    
    dynamic "host" {
      for_each = vcf_host.fleet_hosts
      content {
        id          = host.value.id
        vmnic {
          id       = "vmnic0"
          vds_name = "${var.environment}-fleet-vds"
        }
        vmnic {
          id       = "vmnic1"
          vds_name = "${var.environment}-fleet-vds"
        }
      }
    }
    
    vds {
      name = "${var.environment}-fleet-vds"
      portgroup {
        name           = "${var.environment}-fleet-mgmt-pg"
        transport_type = "MANAGEMENT"
      }
      portgroup {
        name           = "${var.environment}-fleet-vsan-pg"
        transport_type = "VSAN"
      }
      portgroup {
        name           = "${var.environment}-fleet-vmotion-pg"
        transport_type = "VMOTION"
      }
    }
    
    vsan_datastore {
      datastore_name       = "${var.environment}-fleet-vsan-ds"
      failures_to_tolerate = var.vsan_failures_to_tolerate
    }
    
    geneve_vlan_id = var.geneve_vlan_id
  }
}

# VCF Workload Domain with Supervisor Enabled
resource "vcf_domain" "workload_domain" {
  name = "${var.environment}-workload-domain"
  
  vcenter_configuration {
    name            = "${var.environment}-workload-vcenter"
    datacenter_name = "${var.environment}-workload-datacenter"
    root_password   = var.workload_vcenter_root_password
    vm_size         = var.workload_vcenter_vm_size
    storage_size    = var.workload_vcenter_storage_size
    ip_address      = var.workload_vcenter_ip
    subnet_mask     = var.workload_vcenter_subnet_mask
    gateway         = var.workload_vcenter_gateway
    fqdn            = var.workload_vcenter_fqdn
  }
  
  nsx_configuration {
    vip                        = var.workload_nsx_vip
    vip_fqdn                   = var.workload_nsx_vip_fqdn
    nsx_manager_admin_password = var.workload_nsx_manager_admin_password
    form_factor                = var.workload_nsx_form_factor
    
    dynamic "nsx_manager_node" {
      for_each = var.workload_nsx_manager_nodes
      content {
        name        = nsx_manager_node.value.name
        ip_address  = nsx_manager_node.value.ip_address
        fqdn        = nsx_manager_node.value.fqdn
        subnet_mask = nsx_manager_node.value.subnet_mask
        gateway     = nsx_manager_node.value.gateway
      }
    }
  }
  
  # Workload Cluster with Supervisor Services
  cluster {
    name = "${var.environment}-workload-cluster"
    
    dynamic "host" {
      for_each = vcf_host.fleet_hosts
      content {
        id          = host.value.id
        vmnic {
          id       = "vmnic0"
          vds_name = "${var.environment}-workload-vds"
        }
        vmnic {
          id       = "vmnic1"
          vds_name = "${var.environment}-workload-vds"
        }
      }
    }
    
    vds {
      name = "${var.environment}-workload-vds"
      portgroup {
        name           = "${var.environment}-workload-mgmt-pg"
        transport_type = "MANAGEMENT"
      }
      portgroup {
        name           = "${var.environment}-workload-vsan-pg"
        transport_type = "VSAN"
      }
      portgroup {
        name           = "${var.environment}-workload-vmotion-pg"
        transport_type = "VMOTION"
      }
    }
    
    vsan_datastore {
      datastore_name       = "${var.environment}-workload-vsan-ds"
      failures_to_tolerate = var.workload_vsan_failures_to_tolerate
    }
    
    geneve_vlan_id = var.workload_geneve_vlan_id
  }
  
  # Enable Supervisor Services
  supervisor_services {
    enabled = true
    # Add supervisor services configuration here
    # This would include Tanzu Kubernetes Grid, vSphere with Tanzu, etc.
  }
}
