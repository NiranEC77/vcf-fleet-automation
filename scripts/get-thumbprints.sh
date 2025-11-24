#!/bin/bash
# Helper script to fetch SSL and SSH thumbprints from ESXi hosts and vCenter
# This is OPTIONAL - thumbprints are not required if skip_esx_thumbprint_validation = true

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}VCF Thumbprint Fetcher${NC}"
echo "================================"
echo ""

# Function to get SSL thumbprint (SHA256)
get_ssl_thumbprint() {
    local host=$1
    local port=${2:-443}
    
    echo -n "Fetching SSL thumbprint for ${host}... "
    
    thumbprint=$(echo | openssl s_client -connect "${host}:${port}" -servername "${host}" 2>/dev/null | \
                 openssl x509 -fingerprint -sha256 -noout 2>/dev/null | \
                 cut -d= -f2)
    
    if [ -n "$thumbprint" ]; then
        echo -e "${GREEN}✓${NC}"
        echo "  SSL: $thumbprint"
    else
        echo "Failed"
        return 1
    fi
}

# Function to get SSH thumbprint
get_ssh_thumbprint() {
    local host=$1
    
    echo -n "Fetching SSH thumbprint for ${host}... "
    
    thumbprint=$(ssh-keyscan -t rsa "${host}" 2>/dev/null | \
                ssh-keygen -lf - -E sha256 2>/dev/null | \
                awk '{print $2}' | \
                cut -d: -f2-)
    
    if [ -n "$thumbprint" ]; then
        echo -e "${GREEN}✓${NC}"
        echo "  SSH: SHA256:$thumbprint"
    else
        echo "Failed (optional)"
    fi
}

# Check if host list provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <hostname1> [hostname2] [hostname3] ..."
    echo ""
    echo "Example:"
    echo "  $0 esx9-1.vcf.lab esx9-2.vcf.lab vcsa9-mgmt.vcf.lab"
    echo ""
    echo -e "${YELLOW}Note: With skip_esx_thumbprint_validation=true, thumbprints are NOT required!${NC}"
    exit 1
fi

# Process each host
for host in "$@"; do
    echo ""
    echo "Host: $host"
    echo "---"
    get_ssl_thumbprint "$host" || true
    get_ssh_thumbprint "$host" || true
done

echo ""
echo "================================"
echo -e "${GREEN}Done!${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} If skip_esx_thumbprint_validation=true in terraform.tfvars,"
echo "you do NOT need to add these thumbprints to your configuration."

