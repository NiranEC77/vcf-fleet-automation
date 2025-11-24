# VCF Infrastructure Deployment
# Terraform configuration for VMware Cloud Foundation

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
# Points to the VCF Installer/SDDC Manager endpoint
provider "vcf" {
  sddc_manager_host     = var.sddc_manager_host
  sddc_manager_username = var.sddc_manager_username
  sddc_manager_password = var.sddc_manager_password
}

# ============================================================================
# MANAGEMENT DOMAIN - Bootstrap VCF Instance
# ============================================================================

resource "vcf_instance" "management_domain" {
  instance_id          = var.instance_id
  management_pool_name = var.management_pool_name

  skip_esx_thumbprint_validation = var.skip_esx_thumbprint_validation
  ceip_enabled                   = var.ceip_enabled
  fips_enabled                   = var.fips_enabled
  version                        = var.vcf_version

  # DNS Configuration
  dns {
    domain               = var.dns_domain
    name_server          = var.dns_nameserver
    secondary_name_server = var.dns_secondary_nameserver
  }

  # NTP Servers
  ntp_servers = var.ntp_servers

  # vCenter Configuration
  vcenter {
    vcenter_hostname      = var.mgmt_vcenter_hostname
    root_vcenter_password = var.mgmt_vcenter_root_password
    vm_size               = var.mgmt_vcenter_vm_size
    storage_size          = var.mgmt_vcenter_storage_size
    ssl_thumbprint        = var.mgmt_vcenter_ssl_thumbprint
  }

  # Cluster Configuration
  cluster {
    cluster_name      = var.mgmt_cluster_name
    datacenter_name   = var.mgmt_datacenter_name
    cluster_evc_mode  = var.mgmt_cluster_evc_mode
  }

  # vSAN Configuration
  vsan {
    datastore_name       = var.mgmt_vsan_datastore_name
    failures_to_tolerate = var.mgmt_vsan_failures_to_tolerate
    vsan_dedup           = var.mgmt_vsan_dedup_enabled
    esa_enabled          = var.mgmt_vsan_esa_enabled
  }

  # ESXi Hosts
  dynamic "host" {
    for_each = var.mgmt_esxi_hosts
    content {
      hostname = host.value.hostname
      credentials {
        username = host.value.username
        password = host.value.password
      }
      ssl_thumbprint = host.value.ssl_thumbprint
      ssh_thumbprint = host.value.ssh_thumbprint
    }
  }

  # Network Specifications
  dynamic "network" {
    for_each = var.mgmt_networks
    content {
      network_type             = network.value.network_type
      vlan_id                  = network.value.vlan_id
      mtu                      = network.value.mtu
      subnet                   = network.value.subnet
      subnet_mask              = network.value.subnet_mask
      gateway                  = network.value.gateway
      port_group_key           = network.value.port_group_key
      teaming_policy           = network.value.teaming_policy
      active_uplinks           = network.value.active_uplinks
      standby_uplinks          = network.value.standby_uplinks

      dynamic "include_ip_address_ranges" {
        for_each = network.value.ip_ranges
        content {
          start_ip_address = include_ip_address_ranges.value.start
          end_ip_address   = include_ip_address_ranges.value.end
        }
      }
    }
  }

  # DVS (Distributed Virtual Switch) Configuration
  dynamic "dvs" {
    for_each = var.mgmt_dvs_configs
    content {
      dvs_name = dvs.value.name
      mtu      = dvs.value.mtu
      networks = dvs.value.networks

      dynamic "vmnic_mapping" {
        for_each = dvs.value.vmnic_mappings
        content {
          vmnic  = vmnic_mapping.value.vmnic
          uplink = vmnic_mapping.value.uplink
        }
      }

      # NSX-T Switch Configuration (for overlay DVS)
      dynamic "nsxt_switch_config" {
        for_each = dvs.value.nsx_switch_config != null ? [dvs.value.nsx_switch_config] : []
        content {
          dynamic "transport_zones" {
            for_each = nsxt_switch_config.value.transport_zones
            content {
              transport_type = transport_zones.value.transport_type
              name           = transport_zones.value.name
            }
          }
        }
      }

      # NSX Teaming Policies
      dynamic "nsx_teaming" {
        for_each = dvs.value.nsx_teamings
        content {
          policy          = nsx_teaming.value.policy
          active_uplinks  = nsx_teaming.value.active_uplinks
          standby_uplinks = nsx_teaming.value.standby_uplinks
        }
      }
    }
  }

  # NSX Manager Configuration
  dynamic "nsx" {
    for_each = var.mgmt_nsx_enabled ? [1] : []
    content {
      nsx_manager_size          = var.mgmt_nsx_manager_size
      root_nsx_manager_password = var.mgmt_nsx_root_password
      nsx_admin_password        = var.mgmt_nsx_admin_password
      nsx_audit_password        = var.mgmt_nsx_audit_password
      vip_fqdn                  = var.mgmt_nsx_vip_fqdn
      transport_vlan_id         = var.mgmt_nsx_transport_vlan_id

      dynamic "nsx_manager" {
        for_each = var.mgmt_nsx_managers
        content {
          hostname = nsx_manager.value.hostname
        }
      }

      # NSX IP Address Pool for TEP
      dynamic "ip_address_pool" {
        for_each = var.mgmt_nsx_ip_pool != null ? [var.mgmt_nsx_ip_pool] : []
        content {
          name        = ip_address_pool.value.name
          description = ip_address_pool.value.description

          dynamic "subnet" {
            for_each = ip_address_pool.value.subnets
            content {
              cidr    = subnet.value.cidr
              gateway = subnet.value.gateway

              dynamic "ip_address_pool_range" {
                for_each = subnet.value.ip_ranges
                content {
                  start = ip_address_pool_range.value.start
                  end   = ip_address_pool_range.value.end
                }
              }
            }
          }
        }
      }
    }
  }

  # VCF Automation Configuration
  dynamic "automation" {
    for_each = var.vcf_automation_enabled ? [1] : []
    content {
      hostname              = var.vcf_automation_hostname
      ip_pool               = var.vcf_automation_ip_pool
      node_prefix           = var.vcf_automation_node_prefix
      internal_cluster_cidr = var.vcf_automation_internal_cluster_cidr
      admin_user_password   = var.vcf_automation_admin_password
    }
  }

  # VCF Operations Configuration
  dynamic "operations" {
    for_each = var.vcf_operations_enabled ? [1] : []
    content {
      appliance_size      = var.vcf_operations_appliance_size
      admin_user_password = var.vcf_operations_admin_password
      load_balancer_fqdn  = var.vcf_operations_load_balancer_fqdn

      dynamic "node" {
        for_each = var.vcf_operations_nodes
        content {
          hostname          = node.value.hostname
          type              = node.value.type
          root_user_password = node.value.root_password
        }
      }
    }
  }

  # VCF Operations Collector Configuration
  dynamic "operations_collector" {
    for_each = var.vcf_operations_collector_enabled ? [1] : []
    content {
      hostname          = var.vcf_operations_collector_hostname
      appliance_size    = var.vcf_operations_collector_appliance_size
      root_user_password = var.vcf_operations_collector_root_password
    }
  }

  # VCF Operations Fleet Management Configuration
  dynamic "operations_fleet_management" {
    for_each = var.vcf_fleet_manager_enabled ? [1] : []
    content {
      hostname            = var.vcf_fleet_manager_hostname
      root_user_password  = var.vcf_fleet_manager_root_password
      admin_user_password = var.vcf_fleet_manager_admin_password
    }
  }

  # SDDC Manager Configuration
  dynamic "sddc_manager" {
    for_each = var.sddc_manager_config_enabled ? [1] : []
    content {
      hostname           = var.sddc_manager_hostname
      root_user_password = var.sddc_manager_root_password
      ssh_password       = var.sddc_manager_ssh_password
      local_user_password = var.sddc_manager_local_password
    }
  }
}

# ============================================================================
# WORKLOAD DOMAIN
# ============================================================================

resource "vcf_domain" "workload" {
  count = var.workload_domain_enabled ? 1 : 0

  name     = var.workload_domain_name
  org_name = var.workload_domain_org_name

  # vCenter Configuration for Workload Domain
  vcenter_configuration {
    name            = var.workload_vcenter_name
    datacenter_name = var.workload_datacenter_name
    root_password   = var.workload_vcenter_root_password
    vm_size         = var.workload_vcenter_vm_size
    storage_size    = var.workload_vcenter_storage_size
    ip_address      = var.workload_vcenter_ip
    subnet_mask     = var.workload_vcenter_subnet_mask
    gateway         = var.workload_vcenter_gateway
    fqdn            = var.workload_vcenter_fqdn
  }

  # SSO Domain Configuration
  sso {
    domain_name     = var.workload_sso_domain_name
    domain_password = var.workload_sso_domain_password
  }

  # NSX Configuration for Workload Domain
  dynamic "nsx_configuration" {
    for_each = var.workload_nsx_enabled ? [1] : []
    content {
      nsx_manager_admin_password = var.workload_nsx_admin_password
      nsx_manager_audit_password = var.workload_nsx_audit_password
      vip                        = var.workload_nsx_vip
      vip_fqdn                   = var.workload_nsx_vip_fqdn
      form_factor                = var.workload_nsx_form_factor

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
    }
  }

  # Cluster Configuration for Workload Domain
  dynamic "cluster" {
    for_each = var.workload_clusters
    content {
      name                    = cluster.value.name
      cluster_image_id        = cluster.value.cluster_image_id
      evc_mode                = cluster.value.evc_mode
      high_availability_enabled = cluster.value.high_availability_enabled
      geneve_vlan_id          = cluster.value.geneve_vlan_id

      # vSAN Datastore
      dynamic "vsan_datastore" {
        for_each = cluster.value.vsan_datastore != null ? [cluster.value.vsan_datastore] : []
        content {
          datastore_name                = vsan_datastore.value.datastore_name
          failures_to_tolerate          = vsan_datastore.value.failures_to_tolerate
          dedup_and_compression_enabled = vsan_datastore.value.dedup_and_compression_enabled
          esa_enabled                   = vsan_datastore.value.esa_enabled
        }
      }

      # Hosts in Cluster
      dynamic "host" {
        for_each = cluster.value.host_ids
        content {
          id = host.value

          dynamic "vmnic" {
            for_each = cluster.value.vmnic_mappings
            content {
              id       = vmnic.value.vmnic_id
              vds_name = vmnic.value.vds_name
              uplink   = vmnic.value.uplink
            }
          }
        }
      }

      # VDS Configuration
      dynamic "vds" {
        for_each = cluster.value.vds_configs
        content {
          name          = vds.value.name
          is_used_by_nsx = vds.value.is_used_by_nsx

          dynamic "portgroup" {
            for_each = vds.value.portgroups
            content {
              name            = portgroup.value.name
              transport_type  = portgroup.value.transport_type
              active_uplinks  = portgroup.value.active_uplinks
            }
          }
        }
      }

      # IP Address Pool for NSX TEP
      dynamic "ip_address_pool" {
        for_each = cluster.value.ip_address_pool != null ? [cluster.value.ip_address_pool] : []
        content {
          name        = ip_address_pool.value.name
          description = ip_address_pool.value.description

          dynamic "subnet" {
            for_each = ip_address_pool.value.subnets
            content {
              cidr    = subnet.value.cidr
              gateway = subnet.value.gateway

              dynamic "ip_address_pool_range" {
                for_each = subnet.value.ip_ranges
                content {
                  start = ip_address_pool_range.value.start
                  end   = ip_address_pool_range.value.end
                }
              }
            }
          }
        }
      }
    }
  }

  depends_on = [vcf_instance.management_domain]
}
