# VCF Infrastructure Deployment
# Simple Terraform configuration for VMware Cloud Foundation

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

# Network Pool for VCF
resource "vcf_network_pool" "main" {
  name = "${var.environment}-vcf-network-pool"
  
  # Management Network
  network {
    gateway = var.management_network.gateway
    mask    = var.management_network.mask
    mtu     = var.management_network.mtu
    subnet  = var.management_network.subnet
    type    = "MANAGEMENT"
    vlan_id = var.management_network.vlan_id
    ip_pools {
      start = var.management_network.ip_pool_start
      end   = var.management_network.ip_pool_end
    }
  }
  
  # vSAN Network
  network {
    gateway = var.vsan_network.gateway
    mask    = var.vsan_network.mask
    mtu     = var.vsan_network.mtu
    subnet  = var.vsan_network.subnet
    type    = "VSAN"
    vlan_id = var.vsan_network.vlan_id
    ip_pools {
      start = var.vsan_network.ip_pool_start
      end   = var.vsan_network.ip_pool_end
    }
  }
  
  # vMotion Network
  network {
    gateway = var.vmotion_network.gateway
    mask    = var.vmotion_network.mask
    mtu     = var.vmotion_network.mtu
    subnet  = var.vmotion_network.subnet
    type    = "VMOTION"
    vlan_id = var.vmotion_network.vlan_id
    ip_pools {
      start = var.vmotion_network.ip_pool_start
      end   = var.vmotion_network.ip_pool_end
    }
  }
}

# ESXi Hosts for Management Domain
resource "vcf_host" "management_domain_hosts" {
  count = length(var.management_domain_esxi_hosts)
  
  fqdn            = var.management_domain_esxi_hosts[count.index].fqdn
  username        = var.management_domain_esxi_hosts[count.index].username
  password        = var.management_domain_esxi_hosts[count.index].password
  network_pool_id = vcf_network_pool.main.id
  storage_type    = var.management_domain_esxi_hosts[count.index].storage_type
}

# ESXi Hosts for Workload Domain
resource "vcf_host" "workload_domain_hosts" {
  count = length(var.workload_domain_esxi_hosts)
  
  fqdn            = var.workload_domain_esxi_hosts[count.index].fqdn
  username        = var.workload_domain_esxi_hosts[count.index].username
  password        = var.workload_domain_esxi_hosts[count.index].password
  network_pool_id = vcf_network_pool.main.id
  storage_type    = var.workload_domain_esxi_hosts[count.index].storage_type
}

# Management Domain
resource "vcf_domain" "management" {
  name = "${var.environment}-management-domain"
  
  vcenter_configuration {
    name            = var.management_vcenter.name
    datacenter_name = var.management_vcenter.datacenter_name
    root_password   = var.management_vcenter.root_password
    vm_size         = var.management_vcenter.vm_size
    storage_size    = var.management_vcenter.storage_size
    ip_address      = var.management_vcenter.ip_address
    subnet_mask     = var.management_vcenter.subnet_mask
    gateway         = var.management_vcenter.gateway
    fqdn            = var.management_vcenter.fqdn
  }
  
  nsx_configuration {
    vip                        = var.management_nsx.vip
    vip_fqdn                   = var.management_nsx.vip_fqdn
    nsx_manager_admin_password = var.management_nsx.admin_password
    form_factor                = var.management_nsx.form_factor
    
    dynamic "nsx_manager_node" {
      for_each = var.management_nsx_managers
      content {
        name        = nsx_manager_node.value.name
        ip_address  = nsx_manager_node.value.ip_address
        fqdn        = nsx_manager_node.value.fqdn
        subnet_mask = nsx_manager_node.value.subnet_mask
        gateway     = nsx_manager_node.value.gateway
      }
    }
  }
  
  cluster {
    name = "${var.environment}-management-cluster"
    
    dynamic "host" {
      for_each = vcf_host.management_domain_hosts
      content {
        id = host.value.id
        vmnic {
          id       = "vmnic0"
          vds_name = "${var.environment}-management-vds"
        }
        vmnic {
          id       = "vmnic1"
          vds_name = "${var.environment}-management-vds"
        }
      }
    }
    
    vds {
      name = "${var.environment}-management-vds"
      portgroup {
        name           = "${var.environment}-management-mgmt-pg"
        transport_type = "MANAGEMENT"
      }
      portgroup {
        name           = "${var.environment}-management-vsan-pg"
        transport_type = "VSAN"
      }
      portgroup {
        name           = "${var.environment}-management-vmotion-pg"
        transport_type = "VMOTION"
      }
    }
    
    vsan_datastore {
      datastore_name       = "${var.environment}-management-vsan-ds"
      failures_to_tolerate = var.management_domain_vsan_ftol
    }
    
    geneve_vlan_id = var.management_domain_geneve_vlan
  }
}

# Workload Domain with Supervisor
resource "vcf_domain" "workload" {
  name = "${var.environment}-workload-domain"
  
  vcenter_configuration {
    name            = var.workload_vcenter.name
    datacenter_name = var.workload_vcenter.datacenter_name
    root_password   = var.workload_vcenter.root_password
    vm_size         = var.workload_vcenter.vm_size
    storage_size    = var.workload_vcenter.storage_size
    ip_address      = var.workload_vcenter.ip_address
    subnet_mask     = var.workload_vcenter.subnet_mask
    gateway         = var.workload_vcenter.gateway
    fqdn            = var.workload_vcenter.fqdn
  }
  
  nsx_configuration {
    vip                        = var.workload_nsx.vip
    vip_fqdn                   = var.workload_nsx.vip_fqdn
    nsx_manager_admin_password = var.workload_nsx.admin_password
    form_factor                = var.workload_nsx.form_factor
    
    dynamic "nsx_manager_node" {
      for_each = var.workload_nsx_managers
      content {
        name        = nsx_manager_node.value.name
        ip_address  = nsx_manager_node.value.ip_address
        fqdn        = nsx_manager_node.value.fqdn
        subnet_mask = nsx_manager_node.value.subnet_mask
        gateway     = nsx_manager_node.value.gateway
      }
    }
    
    # NSX Edge Cluster Configuration
    dynamic "nsx_edge_node" {
      for_each = var.nsx_edge_nodes
      content {
        name        = nsx_edge_node.value.name
        ip_address  = nsx_edge_node.value.ip_address
        fqdn        = nsx_edge_node.value.fqdn
        subnet_mask = nsx_edge_node.value.subnet_mask
        gateway     = nsx_edge_node.value.gateway
      }
    }
  }
  
  cluster {
    name = "${var.environment}-workload-cluster"
    
    dynamic "host" {
      for_each = vcf_host.workload_domain_hosts
      content {
        id = host.value.id
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
      failures_to_tolerate = var.workload_domain_vsan_ftol
    }
    
    geneve_vlan_id = var.workload_domain_geneve_vlan
  }
}

# VCF Automation Service Configuration
resource "vcf_instance" "vcf_automation" {
  count = var.vcf_automation_enabled ? 1 : 0
  
  name        = "${var.environment}-vcf-automation"
  ip_address  = var.vcf_automation_ip
  fqdn        = var.vcf_automation_fqdn
  subnet_mask = var.vcf_automation_subnet_mask
  gateway     = var.vcf_automation_gateway
}

# VCF Operations Service Configuration
resource "vcf_instance" "vcf_operations" {
  count = var.vcf_operations_enabled ? 1 : 0
  
  name        = "${var.environment}-vcf-operations"
  ip_address  = var.vcf_operations_ip
  fqdn        = var.vcf_operations_fqdn
  subnet_mask = var.vcf_operations_subnet_mask
  gateway     = var.vcf_operations_gateway
}

# VCF Operations Collector Configuration
resource "vcf_instance" "vcf_operations_collector" {
  count = var.vcf_operations_collector_enabled ? 1 : 0
  
  name        = "${var.environment}-vcf-operations-collector"
  ip_address  = var.vcf_operations_collector_ip
  fqdn        = var.vcf_operations_collector_fqdn
  subnet_mask = var.vcf_operations_collector_subnet_mask
  gateway     = var.vcf_operations_collector_gateway
}

# Fleet Manager Configuration
resource "vcf_instance" "fleet_manager" {
  count = var.fleet_manager_enabled ? 1 : 0
  
  name        = "${var.environment}-fleet-manager"
  ip_address  = var.fleet_manager_ip
  fqdn        = var.fleet_manager_fqdn
  subnet_mask = var.fleet_manager_subnet_mask
  gateway     = var.fleet_manager_gateway
}

# Supervisor Configuration
resource "vcf_supervisor" "main" {
  count = var.supervisor_enabled ? 1 : 0
  
  name              = "${var.environment}-supervisor"
  management_ip     = var.supervisor_management_ip
  control_plane_ips = var.supervisor_control_plane_ips
  subnet_mask       = var.supervisor_subnet_mask
  gateway           = var.supervisor_gateway
  dns_servers       = var.supervisor_dns_servers
  ntp_servers       = var.supervisor_ntp_servers
  
  workload_domain_id = vcf_domain.workload.id
}

# Supervisor Pools Configuration
resource "vcf_supervisor_pool" "pools" {
  for_each = var.supervisor_pools
  
  name           = each.value.name
  supervisor_id  = vcf_supervisor.main[0].id
  ip_range_start = each.value.ip_range_start
  ip_range_end   = each.value.ip_range_end
  subnet_mask    = each.value.subnet_mask
  gateway        = each.value.gateway
}

