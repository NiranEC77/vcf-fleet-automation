#!/bin/bash
# Quick test script to convert tfvars to JSON and optionally validate in Cloud Builder

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

DEBUG_MODE=""
if [ "$1" == "--debug" ] || [ "$1" == "-d" ]; then
    DEBUG_MODE="--debug"
fi

echo -e "${BLUE}VCF Configuration Test Tool${NC}"
echo "================================"
echo ""

# Check if terraform.tfvars exists
TFVARS_FILE="${PROJECT_DIR}/terraform.tfvars"
if [ ! -f "$TFVARS_FILE" ]; then
    echo -e "${YELLOW}Warning: terraform.tfvars not found!${NC}"
    echo "Using terraform.tfvars.example instead..."
    TFVARS_FILE="${PROJECT_DIR}/terraform.tfvars.example"
fi

# Output file
OUTPUT_FILE="${PROJECT_DIR}/vcf-bringup-spec.json"

echo "📖 Source: $(basename $TFVARS_FILE)"
echo "📁 Full path: $TFVARS_FILE"
echo "💾 Output: $(basename $OUTPUT_FILE)"
echo "📊 File size: $(wc -c < "$TFVARS_FILE") bytes"
echo ""

# Show a sample of what's in the file
if [ -n "$DEBUG_MODE" ]; then
    echo -e "${YELLOW}🔍 Checking your terraform.tfvars for key variables:${NC}"
    echo ""
    
    # Check VCF Operations Collector
    if grep -q "vcf_operations_collector_hostname" "$TFVARS_FILE"; then
        echo -n "✓ VCF Ops Collector hostname: "
        grep "vcf_operations_collector_hostname" "$TFVARS_FILE" | head -1 | cut -d'=' -f2 | xargs
    else
        echo -e "${RED}✗ vcf_operations_collector_hostname NOT FOUND${NC}"
    fi
    
    # Check VCF Automation
    if grep -q "vcf_automation_hostname" "$TFVARS_FILE"; then
        echo -n "✓ VCF Automation hostname: "
        grep "vcf_automation_hostname" "$TFVARS_FILE" | head -1 | cut -d'=' -f2 | xargs
    else
        echo -e "${RED}✗ vcf_automation_hostname NOT FOUND${NC}"
    fi
    
    # Check Fleet Manager
    if grep -q "vcf_fleet_manager_hostname" "$TFVARS_FILE"; then
        echo -n "✓ Fleet Manager hostname: "
        grep "vcf_fleet_manager_hostname" "$TFVARS_FILE" | head -1 | cut -d'=' -f2 | xargs
    else
        echo -e "${RED}✗ vcf_fleet_manager_hostname NOT FOUND${NC}"
    fi
    
    echo ""
fi

# Run the conversion
echo -e "${BLUE}Converting tfvars to VCF JSON...${NC}"
python3 "${SCRIPT_DIR}/tfvars-to-json.py" "$TFVARS_FILE" "$OUTPUT_FILE" $DEBUG_MODE

echo ""
echo "================================"
echo -e "${GREEN}✅ Conversion complete!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. Review the generated JSON: cat $OUTPUT_FILE"
echo "2. Upload to Cloud Builder UI for validation:"
echo "   - Open: https://$(grep 'installer_host' $TFVARS_FILE | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')"
echo "   - Navigate to: Bring-up → Upload JSON"
echo "   - Upload: vcf-bringup-spec.json"
echo ""
echo "⚠️  Note: This is a simplified conversion. For full deployment, use 'terraform apply'"

