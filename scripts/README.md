# VCF Automation Scripts

Helper scripts for VCF deployment and testing.

## 🧪 test-config.sh

Quick wrapper to convert your Terraform configuration to VCF JSON format for testing.

**Usage:**
```bash
./scripts/test-config.sh
```

**What it does:**
1. Reads your `terraform.tfvars` (or falls back to example)
2. Converts to VCF JSON format
3. Saves as `vcf-bringup-spec.json`
4. Shows next steps for validation

**When to use:**
- ✅ Before running `terraform apply` to catch config errors
- ✅ To test different network/host configurations quickly
- ✅ To validate in Cloud Builder UI with visual feedback

---

## 🔧 tfvars-to-json.py

Python script that converts Terraform variables to VCF JSON specification.

**Usage:**
```bash
./scripts/tfvars-to-json.py terraform.tfvars output.json
```

**Arguments:**
- `terraform.tfvars` - Input file (your Terraform variables)
- `output.json` - Output file (VCF JSON spec)

**Example:**
```bash
# Convert current config
./scripts/tfvars-to-json.py terraform.tfvars vcf-spec.json

# Convert example config
./scripts/tfvars-to-json.py terraform.tfvars.example test-spec.json
```

**Converts:**
- ✅ Basic VCF settings (instance ID, version, CEIP)
- ✅ DNS and NTP configuration
- ✅ vCenter configuration (management)
- ✅ NSX configuration
- ✅ vSAN datastore settings
- ✅ VCF services (Automation, Operations, Fleet Manager)
- ✅ SDDC Manager settings

**Limitations:**
- Host specs need manual addition (complex nested structures)
- Network specs need manual addition
- DVS specs need manual addition

For complete deployment, use `terraform apply` instead!

---

## 🔍 get-thumbprints.sh

Fetch SSL and SSH thumbprints from ESXi hosts and vCenter servers.

**Usage:**
```bash
./scripts/get-thumbprints.sh <hostname1> [hostname2] [hostname3]
```

**Example:**
```bash
./scripts/get-thumbprints.sh \
    esx-01a.site-a.vcf.lab \
    esx-02a.site-a.vcf.lab \
    vc-mgmt-a.site-a.vcf.lab
```

**Note:** With `skip_esx_thumbprint_validation = true`, thumbprints are **NOT required**!

---

## Workflow Example

### Test-First Approach

```bash
# 1. Edit your configuration
vim terraform.tfvars

# 2. Generate JSON for testing
./scripts/test-config.sh

# 3. Upload vcf-bringup-spec.json to Cloud Builder UI
# https://10.1.1.191/ → Bring-up → Upload JSON

# 4. Review validation results in UI

# 5. Fix any issues in terraform.tfvars

# 6. Repeat steps 2-5 until validation passes

# 7. Deploy with Terraform
terraform apply
```

### Direct Deployment Approach

```bash
# 1. Edit configuration
vim terraform.tfvars

# 2. Deploy directly
terraform plan
terraform apply

# 3. Monitor in Cloud Builder UI
# https://10.1.1.191/ → Bring-up → Status
```

Both approaches work! The test-first approach gives you more visibility during validation.

