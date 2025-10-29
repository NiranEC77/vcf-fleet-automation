# VCF 9 Bootstrap and Management Guide

## 🚀 **VCF 9 Bootstrap Process (New VCF Deployment)**

This guide covers both VCF 9 bootstrap (new deployment) and management (existing VCF) scenarios.

## 📋 **VCF Installation Requirements**

### **Hardware Requirements**
- **Minimum 4 ESXi hosts** for VCF management domain
- **Additional ESXi hosts** for workload domains (recommended 3+ per domain)
- **Shared storage** (vSAN or external storage)
- **Network infrastructure** with proper VLANs and routing

### **Software Requirements**
- **VMware Cloud Builder** (for initial VCF deployment)
- **VCF 9.0.0+** (supports VCF Automation and Operations)
- **Valid VMware licenses**:
  - VCF license
  - ESXi licenses
  - vSAN licenses
  - NSX licenses

### **Network Requirements**
- **Management Network** (VLAN 100)
- **vSAN Network** (VLAN 101)
- **vMotion Network** (VLAN 102)
- **VCF Automation Network** (VLAN 103)
- **VCF Operations Network** (VLAN 104)
- **NSX Overlay Network** (Geneve)

## 🏗️ **VCF 9 Bootstrap Steps (New VCF)**

### **Step 1: Deploy VCF Installer Appliance**
1. **Download VCF 9 Cloud Builder** installer appliance
2. **Deploy Cloud Builder** on a management host
3. **Configure Cloud Builder** with network settings

### **Step 2: Bootstrap VCF Management Domain**
1. **Launch Cloud Builder** web interface
2. **Configure management domain** with 4 ESXi hosts minimum
3. **Bootstrap VCF** which automatically includes:
   - SDDC Manager deployment
   - vCenter Server deployment
   - NSX Manager deployment
   - Management cluster creation
   - **VCF Automation and Operations** (built into VCF 9)

### **Step 2: Verify VCF Installation**
1. **Access SDDC Manager** web interface
2. **Verify management domain** is operational
3. **Test connectivity** to all components
4. **Note SDDC Manager credentials** for Terraform

### **Step 3: Prepare for Terraform Automation**
1. **Gather SDDC Manager details**:
   - IP address or FQDN
   - Username and password
   - API access enabled

2. **Prepare additional ESXi hosts** for workload domains:
   - Install ESXi on additional hosts
   - Configure network connectivity
   - Ensure hosts are accessible from SDDC Manager

## 🏗️ **VCF Management Steps (Existing VCF)**

### **Prerequisites for Existing VCF**
- **VCF environment** already deployed and operational
- **SDDC Manager** running and accessible
- **Management domain** fully configured

### **Step 1: Verify VCF Environment**
1. **Access SDDC Manager** web interface
2. **Verify management domain** is operational
3. **Check VCF Automation/Operations** status
4. **Test API connectivity**

### **Step 2: Prepare for Terraform Management**
1. **Gather SDDC Manager credentials**
2. **Prepare additional ESXi hosts** for workload domains
3. **Configure network settings** for new domains

## 🔧 **VCF Installation Commands**

### **Using VMware Cloud Builder**
```bash
# Download VCF Cloud Builder
# Extract and run the installer
./cloudbuilder-installer.sh

# Follow the Cloud Builder wizard to:
# 1. Configure management domain
# 2. Deploy SDDC Manager
# 3. Complete VCF setup
```

### **Verification Commands**
```bash
# Test SDDC Manager connectivity
curl -k https://<sddc-manager-ip>/v1/sddc-manager/health

# Check VCF status
# Access SDDC Manager web interface
# Navigate to: https://<sddc-manager-ip>
```

## 📊 **VCF 9 Architecture Overview**

### **VCF 9 Bootstrap Process:**
```
1. VCF Installer Appliance (Cloud Builder)
   ↓
2. Bootstrap VCF Management Domain
   ┌─────────────────────────────────────────────────────────────┐
   │              VCF 9 Management Domain                       │
   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
   │  │   ESXi 1    │  │   ESXi 2    │  │   ESXi 3    │        │
   │  │             │  │             │  │             │        │
   │  └─────────────┘  └─────────────┘  └─────────────┘        │
   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
   │  │   ESXi 4    │  │ SDDC Manager│  │ vCenter/NSX │        │
   │  │             │  │ + VCF Auto  │  │ + VCF Ops   │        │
   │  └─────────────┘  └─────────────┘  └─────────────┘        │
   └─────────────────────────────────────────────────────────────┘
                                   │
                                   │ Terraform Provider
                                   │ (This Automation)
                                   ▼
   ┌─────────────────────────────────────────────────────────────┐
   │                VCF Workload Domains                       │
   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
   │  │   ESXi 5    │  │   ESXi 6    │  │   ESXi 7    │        │
   │  │             │  │             │  │             │        │
   │  └─────────────┘  └─────────────┘  └─────────────┘        │
   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
   │  │   ESXi 8    │  │ vCenter/NSX │  │ Supervisor  │        │
   │  │             │  │             │  │ Services    │        │
   │  └─────────────┘  └─────────────┘  └─────────────┘        │
   └─────────────────────────────────────────────────────────────┘
```

### **Key VCF 9 Differences:**
- **VCF Automation and Operations** are built into the management domain
- **No separate installation** required for VCFA/VCFO
- **Bootstrap process** initializes the entire VCF fleet

## ⚠️ **Common Issues and Solutions**

### **Issue: "SDDC Manager not found"**
- **Solution**: Ensure VCF management domain is fully deployed
- **Check**: SDDC Manager web interface is accessible
- **Verify**: Network connectivity and credentials

### **Issue: "No available hosts"**
- **Solution**: Add ESXi hosts to SDDC Manager inventory
- **Check**: Hosts are properly configured and accessible
- **Verify**: Host credentials and network connectivity

### **Issue: "Insufficient licenses"**
- **Solution**: Ensure all required licenses are installed
- **Check**: VCF, ESXi, vSAN, and NSX licenses
- **Verify**: License validity and capacity

## 📚 **Additional Resources**

- [VMware Cloud Foundation Documentation](https://docs.vmware.com/en/VMware-Cloud-Foundation/)
- [VCF Installation Guide](https://docs.vmware.com/en/VMware-Cloud-Foundation/5.2/rn/vmware-cloud-foundation-52-release-notes.html)
- [VCF Terraform Provider Documentation](https://registry.terraform.io/providers/vmware/vcf/latest/docs)

## 🎯 **Next Steps After VCF Installation**

1. **Complete VCF management domain setup**
2. **Verify SDDC Manager is running**
3. **Gather SDDC Manager credentials**
4. **Prepare additional ESXi hosts**
5. **Configure terraform.tfvars** with your VCF details
6. **Run this Terraform automation** to create workload domains

---

**Remember**: This Terraform automation is for **managing existing VCF environments**, not for initial VCF deployment!
