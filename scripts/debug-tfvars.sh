#!/bin/bash
# Debug script to check what the parser is reading

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TFVARS_FILE="${PROJECT_DIR}/terraform.tfvars"

echo "🔍 VCF Config Debug Tool"
echo "========================"
echo ""

if [ ! -f "$TFVARS_FILE" ]; then
    echo "❌ terraform.tfvars not found at: $TFVARS_FILE"
    exit 1
fi

echo "📁 File: $TFVARS_FILE"
echo "📊 Size: $(wc -c < "$TFVARS_FILE") bytes"
echo "📝 Lines: $(wc -l < "$TFVARS_FILE") lines"
echo ""

# Check for specific variables
echo "🔍 Checking key variables in your tfvars:"
echo ""

check_var() {
    local var_name="$1"
    local value=$(grep "^${var_name}\s*=" "$TFVARS_FILE" | head -1)
    if [ -n "$value" ]; then
        echo "✓ $value"
    else
        echo "✗ $var_name = NOT FOUND"
    fi
}

echo "VCF Operations Collector:"
check_var "vcf_operations_collector_hostname"
check_var "vcf_operations_collector_enabled"

echo ""
echo "VCF Operations:"
check_var "vcf_operations_enabled"
grep -A 5 "vcf_operations_nodes" "$TFVARS_FILE" | head -6

echo ""
echo "VCF Automation:"
check_var "vcf_automation_hostname"
check_var "vcf_automation_enabled"

echo ""
echo "Fleet Manager:"
check_var "vcf_fleet_manager_hostname"
check_var "vcf_fleet_manager_enabled"

echo ""
echo "========================"
echo ""
echo "💡 To see full debug output, run:"
echo "   python3 ${SCRIPT_DIR}/tfvars-to-json.py $TFVARS_FILE output.json --debug"

