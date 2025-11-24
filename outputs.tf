# VCF Infrastructure Outputs

output "network_pool_id" {
  description = "ID of the created network pool"
  value       = vcf_network_pool.main.id
}

output "management_domain_id" {
  description = "ID of the management domain"
  value       = vcf_domain.management.id
}

output "management_domain_name" {
  description = "Name of the management domain"
  value       = vcf_domain.management.name
}

output "workload_domain_id" {
  description = "ID of the workload domain"
  value       = vcf_domain.workload.id
}

output "workload_domain_name" {
  description = "Name of the workload domain"
  value       = vcf_domain.workload.name
}

output "management_vcenter_ip" {
  description = "Management vCenter IP address"
  value       = var.management_vcenter.ip_address
}

output "workload_vcenter_ip" {
  description = "Workload vCenter IP address"
  value       = var.workload_vcenter.ip_address
}

output "management_nsx_vip" {
  description = "Management NSX VIP address"
  value       = var.management_nsx.vip
}

output "workload_nsx_vip" {
  description = "Workload NSX VIP address"
  value       = var.workload_nsx.vip
}

output "management_esxi_hosts" {
  description = "Management domain ESXi host IP addresses"
  value       = [for host in var.management_domain_esxi_hosts : host.ip_address]
}

output "workload_esxi_hosts" {
  description = "Workload domain ESXi host IP addresses"
  value       = [for host in var.workload_domain_esxi_hosts : host.ip_address]
}

output "nsx_edge_ips" {
  description = "NSX Edge node IP addresses"
  value       = [for edge in var.nsx_edge_nodes : edge.ip_address]
}

output "vcf_automation_ip" {
  description = "VCF Automation IP address"
  value       = var.vcf_automation_enabled ? var.vcf_automation_ip : null
}

output "vcf_operations_ip" {
  description = "VCF Operations IP address"
  value       = var.vcf_operations_enabled ? var.vcf_operations_ip : null
}

output "vcf_operations_collector_ip" {
  description = "VCF Operations Collector IP address"
  value       = var.vcf_operations_collector_enabled ? var.vcf_operations_collector_ip : null
}

output "fleet_manager_ip" {
  description = "Fleet Manager IP address"
  value       = var.fleet_manager_enabled ? var.fleet_manager_ip : null
}

output "supervisor_management_ip" {
  description = "Supervisor management IP address"
  value       = var.supervisor_enabled ? var.supervisor_management_ip : null
}

output "supervisor_control_plane_ips" {
  description = "Supervisor control plane IP addresses"
  value       = var.supervisor_enabled ? var.supervisor_control_plane_ips : []
}

output "supervisor_pools" {
  description = "Supervisor pools configuration"
  value = {
    for name, pool in var.supervisor_pools : name => {
      name           = pool.name
      ip_range_start = pool.ip_range_start
      ip_range_end   = pool.ip_range_end
    }
  }
}

