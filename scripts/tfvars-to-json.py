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
                # Remove quotes but preserve all content including special chars
                variables[var_name] = var_value[1:-1]
            elif var_value.startswith('['):
                # List - check if it's a simple list or list of objects
                if '{' in var_value:
                    # Complex list of objects
                    variables[var_name] = extract_list_of_objects(var_value)
                else:
                    # Simple list
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
    escape_next = False
    
    for i, char in enumerate(list_str[1:-1]):  # Skip [ and ]
        if escape_next:
            current += char
            escape_next = False
            continue
            
        if char == '\\':
            escape_next = True
            current += char
            continue
            
        if char == '"' and not escape_next:
            in_string = not in_string
            current += char
        elif char == '{' and not in_string:
            in_object += 1
            current += char
        elif char == '}' and not in_string:
            in_object -= 1
            current += char
        elif char == ',' and not in_string and in_object == 0:
            item = current.strip()
            # Remove quotes but preserve content
            if item.startswith('"') and item.endswith('"'):
                item = item[1:-1]
            if item:
                items.append(item)
            current = ""
        else:
            current += char
    
    if current.strip():
        item = current.strip()
        if item.startswith('"') and item.endswith('"'):
            item = item[1:-1]
        if item:
            items.append(item)
    
    return items


def extract_object(obj_str):
    """Extract object from HCL format"""
    # Parse simple key-value pairs
    obj = {}
    obj_str = obj_str.strip()
    if not obj_str.startswith('{'):
        return obj_str
    
    # Remove outer braces
    content = obj_str[1:-1].strip()
    
    # Simple key = value extraction
    lines = content.split('\n')
    for line in lines:
        line = line.strip()
        if '=' in line and not line.startswith('#'):
            parts = line.split('=', 1)
            if len(parts) == 2:
                key = parts[0].strip()
                value = parts[1].strip().rstrip(',')
                
                # Parse value
                if value.startswith('"') and value.endswith('"'):
                    obj[key] = value[1:-1]
                elif value.lower() in ['true', 'false']:
                    obj[key] = value.lower() == 'true'
                elif value.lower() == 'null':
                    obj[key] = None
                else:
                    try:
                        obj[key] = int(value) if '.' not in value else float(value)
                    except:
                        obj[key] = value
    
    return obj


def extract_list_of_objects(list_str):
    """Extract a list of objects from HCL format"""
    objects = []
    current_obj = ""
    brace_count = 0
    in_string = False
    
    # Remove outer brackets
    content = list_str.strip()[1:-1]
    
    for char in content:
        if char == '"' and (not current_obj or current_obj[-1] != '\\'):
            in_string = not in_string
        
        if not in_string:
            if char == '{':
                brace_count += 1
            elif char == '}':
                brace_count -= 1
        
        current_obj += char
        
        # End of object
        if brace_count == 0 and current_obj.strip():
            obj_str = current_obj.strip().rstrip(',')
            if obj_str.startswith('{'):
                parsed = extract_object(obj_str)
                if isinstance(parsed, dict) and parsed:
                    objects.append(parsed)
            current_obj = ""
    
    return objects


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
    nsx_managers = variables.get('mgmt_nsx_managers', [])
    nsx_manager_nodes = []
    
    if isinstance(nsx_managers, list) and nsx_managers:
        for mgr in nsx_managers:
            if isinstance(mgr, dict):
                nsx_manager_nodes.append({
                    "hostname": mgr.get('hostname', mgr.get('name', 'nsx-mgmt-01'))
                })
    
    # If no managers configured, add a default
    if not nsx_manager_nodes:
        nsx_manager_nodes.append({"hostname": "nsx-mgmt-01"})
    
    spec["nsxtSpec"] = {
        "nsxtManagerSize": safe_get('mgmt_nsx_manager_size', 'medium'),
        "nsxtManagers": nsx_manager_nodes,
        "vipFqdn": safe_get('mgmt_nsx_vip_fqdn', 'nsx-vip.vcf.lab'),
        "useExistingDeployment": False,
        "nsxtAdminPassword": safe_get('mgmt_nsx_admin_password', 'VMware123!'),
        "nsxtAuditPassword": safe_get('mgmt_nsx_audit_password', 'VMware123!'),
        "rootNsxtManagerPassword": safe_get('mgmt_nsx_root_password', 'VMware123!'),
        "skipNsxOverlayOverManagementNetwork": True,
        "transportVlanId": safe_get('mgmt_nsx_transport_vlan_id', 18)
    }
    
    # Add NSX IP pool if configured
    nsx_ip_pool = variables.get('mgmt_nsx_ip_pool')
    if nsx_ip_pool and isinstance(nsx_ip_pool, dict):
        subnets = nsx_ip_pool.get('subnets', [])
        if subnets and len(subnets) > 0:
            subnet = subnets[0] if isinstance(subnets[0], dict) else {}
            ip_ranges = subnet.get('ip_ranges', [])
            pool_ranges = []
            
            if isinstance(ip_ranges, list):
                for r in ip_ranges:
                    if isinstance(r, dict):
                        pool_ranges.append({
                            "start": r.get('start', ''),
                            "end": r.get('end', '')
                        })
            
            spec["nsxtSpec"]["ipAddressPoolSpec"] = {
                "name": nsx_ip_pool.get('name', 'tep-pool'),
                "description": nsx_ip_pool.get('description', 'NSX TEP IP Pool'),
                "subnets": [{
                    "cidr": subnet.get('cidr', ''),
                    "gateway": subnet.get('gateway', ''),
                    "ipAddressPoolRanges": pool_ranges
                }]
            }
    
    # ESXi Host Specs
    mgmt_hosts = variables.get('mgmt_esxi_hosts', [])
    if isinstance(mgmt_hosts, list) and mgmt_hosts:
        spec["hostSpecs"] = []
        for host in mgmt_hosts:
            if isinstance(host, dict):
                host_spec = {
                    "hostname": host.get('hostname', ''),
                    "credentials": {
                        "username": host.get('username', 'root'),
                        "password": host.get('password', '')
                    }
                }
                # Add SSL thumbprint if provided and not empty
                ssl_thumb = host.get('ssl_thumbprint', '').strip()
                if ssl_thumb:
                    host_spec["sslThumbprint"] = ssl_thumb
                
                spec["hostSpecs"].append(host_spec)
    
    # Network Specs
    mgmt_networks = variables.get('mgmt_networks', [])
    if isinstance(mgmt_networks, list) and mgmt_networks:
        spec["networkSpecs"] = []
        for network in mgmt_networks:
            if isinstance(network, dict):
                net_spec = {
                    "networkType": network.get('network_type', ''),
                    "subnet": network.get('subnet', ''),
                    "gateway": network.get('gateway', ''),
                    "subnetMask": network.get('subnet_mask', ''),
                    "vlanId": str(network.get('vlan_id', '0')),
                    "mtu": network.get('mtu', 1500),
                    "teamingPolicy": network.get('teaming_policy', 'loadbalance_loadbased'),
                    "activeUplinks": network.get('active_uplinks', ['uplink1', 'uplink2']),
                    "standbyUplinks": network.get('standby_uplinks', []),
                    "portGroupKey": network.get('port_group_key', '')
                }
                
                # Add IP ranges if present
                ip_ranges = network.get('ip_ranges', [])
                if isinstance(ip_ranges, list) and ip_ranges:
                    net_spec["includeIpAddressRanges"] = []
                    for ip_range in ip_ranges:
                        if isinstance(ip_range, dict):
                            net_spec["includeIpAddressRanges"].append({
                                "startIpAddress": ip_range.get('start', ''),
                                "endIpAddress": ip_range.get('end', '')
                            })
                
                spec["networkSpecs"].append(net_spec)
    
    # DVS Specs
    mgmt_dvs = variables.get('mgmt_dvs_configs', [])
    if isinstance(mgmt_dvs, list) and mgmt_dvs:
        spec["dvsSpecs"] = []
        for dvs in mgmt_dvs:
            if isinstance(dvs, dict):
                dvs_spec = {
                    "dvsName": dvs.get('name', ''),
                    "networks": dvs.get('networks', []),
                    "mtu": dvs.get('mtu', 9000),
                    "vmnicsToUplinks": []
                }
                
                # Add vmnic mappings
                vmnic_mappings = dvs.get('vmnic_mappings', [])
                if isinstance(vmnic_mappings, list):
                    for mapping in vmnic_mappings:
                        if isinstance(mapping, dict):
                            dvs_spec["vmnicsToUplinks"].append({
                                "id": mapping.get('vmnic', ''),
                                "uplink": mapping.get('uplink', '')
                            })
                
                # Add NSX switch config if present
                nsx_config = dvs.get('nsx_switch_config')
                if nsx_config and isinstance(nsx_config, dict):
                    transport_zones = nsx_config.get('transport_zones', [])
                    if transport_zones:
                        dvs_spec["nsxtSwitchConfig"] = {
                            "transportZones": transport_zones
                        }
                
                # Add NSX teamings if present
                nsx_teamings = dvs.get('nsx_teamings', [])
                if isinstance(nsx_teamings, list) and nsx_teamings:
                    dvs_spec["nsxTeamings"] = nsx_teamings
                
                spec["dvsSpecs"].append(dvs_spec)
    
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
    
    # Show what was parsed
    print(f"   ✓ Found {len(variables)} variables")
    
    # Show key values
    if 'mgmt_esxi_hosts' in variables:
        hosts = variables['mgmt_esxi_hosts']
        if isinstance(hosts, list):
            print(f"   ✓ ESXi Hosts: {len(hosts)} hosts")
    
    if 'mgmt_networks' in variables:
        networks = variables['mgmt_networks']
        if isinstance(networks, list):
            print(f"   ✓ Networks: {len(networks)} networks")
    
    if 'mgmt_dvs_configs' in variables:
        dvs = variables['mgmt_dvs_configs']
        if isinstance(dvs, list):
            print(f"   ✓ DVS Configs: {len(dvs)} switches")
    
    # Convert to VCF JSON
    print("🔧 Converting to VCF JSON format...")
    vcf_spec = convert_to_vcf_json(variables)
    
    # Write output
    print(f"💾 Writing to {output_file}...")
    with open(output_file, 'w') as f:
        json.dump(vcf_spec, f, indent=2)
    
    # Show summary
    print(f"✅ Done! VCF JSON spec saved to: {output_file}")
    print(f"\n📊 Generated spec includes:")
    print(f"   • {len(vcf_spec.get('hostSpecs', []))} ESXi hosts")
    print(f"   • {len(vcf_spec.get('networkSpecs', []))} networks")
    print(f"   • {len(vcf_spec.get('dvsSpecs', []))} distributed switches")
    print(f"   • {len(vcf_spec.get('nsxtSpec', {}).get('nsxtManagers', []))} NSX managers")
    
    if vcf_spec.get('vcfAutomationSpec'):
        print(f"   • VCF Automation: Enabled")
    if vcf_spec.get('vcfOperationsSpec'):
        print(f"   • VCF Operations: Enabled")
    if vcf_spec.get('vcfOperationsCollectorSpec'):
        print(f"   • VCF Ops Collector: Enabled")
    if vcf_spec.get('vcfOperationsFleetManagementSpec'):
        print(f"   • Fleet Manager: Enabled")
    
    print(f"\n📋 Upload to Cloud Builder for validation:")
    print(f"   https://{variables.get('installer_host', '10.1.1.191')}/")
    print(f"   Navigate to: Bring-up → Upload JSON")


if __name__ == '__main__':
    main()

