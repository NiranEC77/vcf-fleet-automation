#!/usr/bin/env python3
"""
Convert terraform.tfvars to VCF Cloud Builder JSON format
Usage: ./tfvars-to-json.py [terraform.tfvars] [output.json]
"""

import sys
import json
import re
from pathlib import Path


def parse_tfvars(tfvars_content):
    """Parse terraform.tfvars content into a Python dict"""
    variables = {}
    
    # Simple parser for HCL-like syntax
    # This handles strings, numbers, booleans, lists, and objects
    
    # Remove comments
    lines = []
    for line in tfvars_content.split('\n'):
        # Remove inline comments (but preserve # in strings)
        in_string = False
        clean_line = ""
        for i, char in enumerate(line):
            if char == '"' and (i == 0 or line[i-1] != '\\'):
                in_string = not in_string
            if char == '#' and not in_string:
                break
            clean_line += char
        lines.append(clean_line.strip())
    
    content = '\n'.join(lines)
    
    # Extract variable assignments - improved pattern
    pattern = r'(\w+)\s*=\s*(.+?)(?=\n(?:\w+\s*=|\s*$)|\Z)'
    matches = re.findall(pattern, content, re.DOTALL | re.MULTILINE)
    
    for var_name, var_value in matches:
        var_value = var_value.strip()
        
        try:
            # Parse the value
            if var_value.lower() in ['true', 'false']:
                variables[var_name] = var_value.lower() == 'true'
            elif var_value.lower() == 'null':
                variables[var_name] = None
            elif var_value.startswith('"') and var_value.endswith('"'):
                variables[var_name] = var_value.strip('"')
            elif var_value.startswith('['):
                # List - check if it's a simple list or list of objects
                if '{' in var_value:
                    # Complex list - store as empty for now
                    variables[var_name] = []
                else:
                    variables[var_name] = extract_list(var_value)
            elif var_value.startswith('{'):
                # Object - use simple extraction
                variables[var_name] = extract_object(var_value)
            else:
                # Try as number
                try:
                    if '.' in var_value:
                        variables[var_name] = float(var_value)
                    else:
                        variables[var_name] = int(var_value)
                except ValueError:
                    variables[var_name] = var_value.strip('"')
        except Exception as e:
            # On parse error, skip this variable
            print(f"⚠️  Warning: Could not parse variable '{var_name}': {e}")
            continue
    
    return variables


def extract_list(list_str):
    """Extract list values from HCL format"""
    # Simple list extraction for strings
    items = []
    current = ""
    in_string = False
    in_object = 0
    
    for char in list_str[1:-1]:  # Skip [ and ]
        if char == '"' and (not current or current[-1] != '\\'):
            in_string = not in_string
        elif char == '{' and not in_string:
            in_object += 1
        elif char == '}' and not in_string:
            in_object -= 1
        
        if char == ',' and not in_string and in_object == 0:
            item = current.strip().strip('"')
            if item:
                items.append(item)
            current = ""
        else:
            current += char
    
    if current.strip():
        item = current.strip().strip('"')
        if item:
            items.append(item)
    
    return items


def extract_object(obj_str):
    """Extract object from HCL format - simplified"""
    # For complex objects, we'll just store the string for now
    return obj_str


def convert_to_vcf_json(variables):
    """Convert parsed tfvars to VCF JSON format"""
    
    # Helper function to safely get values
    def safe_get(key, default):
        value = variables.get(key, default)
        if value is None:
            return default
        return value
    
    # Build the VCF JSON spec
    spec = {
        "sddcId": safe_get('instance_id', 'vcf'),
        "vcfInstanceName": safe_get('instance_id', 'vcf'),
        "workflowType": "VCF",
        "version": safe_get('vcf_version', '9.0.1.0'),
        "ceipEnabled": safe_get('ceip_enabled', True),
        "dnsSpec": {
            "nameservers": [safe_get('dns_nameserver', '10.1.1.1')],
            "subdomain": safe_get('dns_domain', 'vcf.lab')
        },
        "ntpServers": safe_get('ntp_servers', ['10.1.1.1']) if isinstance(variables.get('ntp_servers'), list) else ['10.1.1.1'],
    }
    
    # vCenter configuration
    spec["vcenterSpec"] = {
        "vcenterHostname": variables.get('mgmt_vcenter_hostname', 'vcenter.vcf.lab'),
        "rootVcenterPassword": variables.get('mgmt_vcenter_root_password', 'VMware123!'),
        "vmSize": variables.get('mgmt_vcenter_vm_size', 'medium'),
        "storageSize": variables.get('mgmt_vcenter_storage_size', 'lstorage'),
        "adminUserSsoPassword": variables.get('mgmt_vcenter_admin_password', 'VMware123!'),
        "ssoDomain": "vsphere.local",
        "useExistingDeployment": False
    }
    
    # Cluster configuration
    spec["clusterSpec"] = {
        "clusterName": variables.get('mgmt_cluster_name', 'mgmt-cluster'),
        "datacenterName": variables.get('mgmt_datacenter_name', 'mgmt-datacenter')
    }
    
    # vSAN configuration
    spec["datastoreSpec"] = {
        "vsanSpec": {
            "failuresToTolerate": variables.get('mgmt_vsan_failures_to_tolerate', 1),
            "vsanDedup": variables.get('mgmt_vsan_dedup_enabled', True),
            "esaConfig": {
                "enabled": variables.get('mgmt_vsan_esa_enabled', False)
            },
            "datastoreName": variables.get('mgmt_vsan_datastore_name', 'vsan-datastore')
        }
    }
    
    # NSX configuration
    spec["nsxtSpec"] = {
        "nsxtManagerSize": variables.get('mgmt_nsx_manager_size', 'medium'),
        "vipFqdn": variables.get('mgmt_nsx_vip_fqdn', 'nsx-vip.vcf.lab'),
        "useExistingDeployment": False,
        "nsxtAdminPassword": variables.get('mgmt_nsx_admin_password', 'VMware123!'),
        "nsxtAuditPassword": variables.get('mgmt_nsx_audit_password', 'VMware123!'),
        "rootNsxtManagerPassword": variables.get('mgmt_nsx_root_password', 'VMware123!'),
        "skipNsxOverlayOverManagementNetwork": True,
        "transportVlanId": variables.get('mgmt_nsx_transport_vlan_id', 18)
    }
    
    # Note: Host specs, network specs, and DVS specs would need more complex parsing
    # For now, add placeholders
    spec["hostSpecs"] = []
    spec["networkSpecs"] = []
    spec["dvsSpecs"] = []
    
    # VCF Automation
    if variables.get('vcf_automation_enabled', False):
        spec["vcfAutomationSpec"] = {
            "hostname": variables.get('vcf_automation_hostname', 'vcf-automation.vcf.lab'),
            "adminUserPassword": variables.get('vcf_automation_admin_password', 'VMware123!'),
            "ipPool": variables.get('vcf_automation_ip_pool', []),
            "nodePrefix": variables.get('vcf_automation_node_prefix', 'vcfa-appliance'),
            "internalClusterCidr": variables.get('vcf_automation_internal_cluster_cidr', '198.18.0.0/15'),
            "useExistingDeployment": False
        }
    
    # VCF Operations
    if variables.get('vcf_operations_enabled', False):
        ops_nodes = variables.get('vcf_operations_nodes', [])
        ops_hostname = 'vcf-ops.vcf.lab'
        
        # Extract hostname if nodes list is not empty
        if ops_nodes and len(ops_nodes) > 0:
            if isinstance(ops_nodes[0], dict):
                ops_hostname = ops_nodes[0].get('hostname', 'vcf-ops.vcf.lab')
        
        spec["vcfOperationsSpec"] = {
            "nodes": [
                {
                    "hostname": ops_hostname,
                    "rootUserPassword": "VMware123!",
                    "type": "master"
                }
            ],
            "adminUserPassword": variables.get('vcf_operations_admin_password', 'VMware123!'),
            "applianceSize": variables.get('vcf_operations_appliance_size', 'medium'),
            "useExistingDeployment": False,
            "loadBalancerFqdn": variables.get('vcf_operations_load_balancer_fqdn')
        }
    
    # VCF Operations Collector
    if variables.get('vcf_operations_collector_enabled', False):
        spec["vcfOperationsCollectorSpec"] = {
            "applicationSize": variables.get('vcf_operations_collector_appliance_size', 'small'),
            "hostname": variables.get('vcf_operations_collector_hostname', 'vcf-ops-collector.vcf.lab'),
            "applianceSize": variables.get('vcf_operations_collector_appliance_size', 'small'),
            "rootUserPassword": variables.get('vcf_operations_collector_root_password', 'VMware123!'),
            "useExistingDeployment": False
        }
    
    # Fleet Manager
    if variables.get('vcf_fleet_manager_enabled', False):
        spec["vcfOperationsFleetManagementSpec"] = {
            "hostname": variables.get('vcf_fleet_manager_hostname', 'fleet-manager.vcf.lab'),
            "rootUserPassword": variables.get('vcf_fleet_manager_root_password', 'VMware123!'),
            "adminUserPassword": variables.get('vcf_fleet_manager_admin_password', 'VMware123!'),
            "useExistingDeployment": False
        }
    
    # SDDC Manager
    if variables.get('sddc_manager_config_enabled', False):
        spec["sddcManagerSpec"] = {
            "hostname": variables.get('sddc_manager_hostname', 'sddc-manager.vcf.lab'),
            "useExistingDeployment": False,
            "rootPassword": variables.get('sddc_manager_root_password', 'VMware123!'),
            "sshPassword": variables.get('sddc_manager_ssh_password', 'VMware123!'),
            "localUserPassword": variables.get('sddc_manager_local_password', 'VMware123!')
        }
    
    return spec


def main():
    if len(sys.argv) < 2:
        print("Usage: ./tfvars-to-json.py [terraform.tfvars] [output.json]")
        print("\nExample:")
        print("  ./tfvars-to-json.py terraform.tfvars vcf-spec.json")
        sys.exit(1)
    
    tfvars_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else 'vcf-bringup-spec.json'
    
    # Read tfvars file
    print(f"📖 Reading {tfvars_file}...")
    try:
        with open(tfvars_file, 'r') as f:
            tfvars_content = f.read()
    except FileNotFoundError:
        print(f"❌ Error: File '{tfvars_file}' not found!")
        sys.exit(1)
    
    # Parse tfvars
    print("🔄 Parsing terraform variables...")
    variables = parse_tfvars(tfvars_content)
    
    # Convert to VCF JSON
    print("🔧 Converting to VCF JSON format...")
    vcf_spec = convert_to_vcf_json(variables)
    
    # Write output
    print(f"💾 Writing to {output_file}...")
    with open(output_file, 'w') as f:
        json.dump(vcf_spec, f, indent=2)
    
    print(f"✅ Done! VCF JSON spec saved to: {output_file}")
    print(f"\n📋 You can now upload this file to Cloud Builder UI for validation:")
    print(f"   https://{variables.get('installer_host', '10.1.1.191')}/")
    print(f"\n⚠️  Note: Host specs, network specs, and DVS specs need manual addition")
    print(f"   or use the full Terraform deployment instead.")


if __name__ == '__main__':
    main()

