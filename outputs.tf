# VCF Infrastructure Outputs

# ============================================================================
# Management Domain Outputs
# ============================================================================

output "management_domain_id" {
  description = "Management domain (VCF instance) ID"
  value       = var.deploy_management_domain && var.use_cloud_builder ? vcf_instance.management_domain[0].id : null
}

output "management_domain_status" {
  description = "Management domain deployment status"
  value       = var.deploy_management_domain && var.use_cloud_builder ? vcf_instance.management_domain[0].status : null
}

output "management_domain_creation_timestamp" {
  description = "Management domain creation timestamp"
  value       = var.deploy_management_domain && var.use_cloud_builder ? vcf_instance.management_domain[0].creation_timestamp : null
}

output "management_vcenter_hostname" {
  description = "Management vCenter hostname"
  value       = var.mgmt_vcenter_hostname
}

output "management_esxi_hosts" {
  description = "Management domain ESXi hostnames"
  value       = [for host in var.mgmt_esxi_hosts : host.hostname]
}

output "management_nsx_vip" {
  description = "Management NSX VIP FQDN"
  value       = var.mgmt_nsx_enabled ? var.mgmt_nsx_vip_fqdn : null
}

output "vcf_automation_hostname" {
  description = "VCF Automation hostname"
  value       = var.vcf_automation_enabled ? var.vcf_automation_hostname : null
}

output "vcf_automation_ips" {
  description = "VCF Automation IP addresses"
  value       = var.vcf_automation_enabled ? var.vcf_automation_ip_pool : []
}

output "vcf_operations_hostname" {
  description = "VCF Operations hostname"
  value       = var.vcf_operations_enabled && length(var.vcf_operations_nodes) > 0 ? var.vcf_operations_nodes[0].hostname : null
}

output "vcf_operations_collector_hostname" {
  description = "VCF Operations Collector hostname"
  value       = var.vcf_operations_collector_enabled ? var.vcf_operations_collector_hostname : null
}

output "vcf_fleet_manager_hostname" {
  description = "VCF Fleet Manager hostname"
  value       = var.vcf_fleet_manager_enabled ? var.vcf_fleet_manager_hostname : null
}

output "sddc_manager_hostname" {
  description = "SDDC Manager hostname"
  value       = var.sddc_manager_config_enabled ? var.sddc_manager_hostname : var.sddc_manager_host
}

# ============================================================================
# Workload Domain Outputs
# ============================================================================

output "workload_domain_id" {
  description = "Workload domain ID"
  value       = var.workload_domain_enabled ? vcf_domain.workload[0].id : null
}

output "workload_domain_name" {
  description = "Workload domain name"
  value       = var.workload_domain_enabled ? vcf_domain.workload[0].name : null
}

output "workload_domain_status" {
  description = "Workload domain status"
  value       = var.workload_domain_enabled ? vcf_domain.workload[0].status : null
}

output "workload_domain_type" {
  description = "Workload domain type"
  value       = var.workload_domain_enabled ? vcf_domain.workload[0].type : null
}

output "workload_vcenter_ip" {
  description = "Workload vCenter IP address"
  value       = var.workload_domain_enabled ? var.workload_vcenter_ip : null
}

output "workload_vcenter_fqdn" {
  description = "Workload vCenter FQDN"
  value       = var.workload_domain_enabled ? var.workload_vcenter_fqdn : null
}

output "workload_nsx_vip" {
  description = "Workload NSX VIP address"
  value       = var.workload_domain_enabled && var.workload_nsx_enabled ? var.workload_nsx_vip : null
}

output "workload_nsx_vip_fqdn" {
  description = "Workload NSX VIP FQDN"
  value       = var.workload_domain_enabled && var.workload_nsx_enabled ? var.workload_nsx_vip_fqdn : null
}

output "workload_nsx_manager_ips" {
  description = "Workload NSX Manager IP addresses"
  value       = var.workload_domain_enabled && var.workload_nsx_enabled ? [for mgr in var.workload_nsx_managers : mgr.ip_address] : []
}

output "workload_cluster_names" {
  description = "Workload domain cluster names"
  value       = var.workload_domain_enabled ? [for cluster in var.workload_clusters : cluster.name] : []
}

output "workload_sso_domain" {
  description = "Workload SSO domain name"
  value       = var.workload_domain_enabled ? var.workload_sso_domain_name : null
}

# ============================================================================
# Summary Output
# ============================================================================

output "deployment_summary" {
  description = "Summary of VCF deployment"
  value = {
    management_domain = {
      instance_id       = var.instance_id
      vcenter_hostname  = var.mgmt_vcenter_hostname
      nsx_vip          = var.mgmt_nsx_enabled ? var.mgmt_nsx_vip_fqdn : null
      automation_enabled = var.vcf_automation_enabled
      operations_enabled = var.vcf_operations_enabled
      fleet_manager_enabled = var.vcf_fleet_manager_enabled
    }
    workload_domain = var.workload_domain_enabled ? {
      name             = var.workload_domain_name
      vcenter_ip       = var.workload_vcenter_ip
      vcenter_fqdn     = var.workload_vcenter_fqdn
      nsx_vip          = var.workload_nsx_enabled ? var.workload_nsx_vip : null
      cluster_count    = length(var.workload_clusters)
    } : null
  }
}
