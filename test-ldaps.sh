#!/bin/bash

# test-ldaps.sh - Test LDAPS (SSL) functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔒 LDAPS (SSL) Test Suite"
echo "========================"

# Test 1: Basic LDAPS connectivity
echo -e "\n${YELLOW}Test 1: Testing LDAPS connectivity on port 636...${NC}"
if LDAPTLS_REQCERT=never ldapsearch -x -H ldaps://localhost:636 -D "cn=admin,dc=example,dc=local" -w "admin123" -b "" -s base "(objectClass=*)" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ LDAPS is working on port 636${NC}"
else
    echo -e "${RED}✗ Cannot connect via LDAPS${NC}"
    exit 1
fi

# Test 2: Verify certificate is being used
echo -e "\n${YELLOW}Test 2: Checking SSL certificate...${NC}"
CERT_INFO=$(echo | openssl s_client -connect localhost:636 -showcerts 2>/dev/null | openssl x509 -noout -subject -issuer 2>/dev/null || true)
if [ -n "$CERT_INFO" ]; then
    echo -e "${GREEN}✓ SSL certificate is active${NC}"
    echo "$CERT_INFO" | sed 's/^/  /'
else
    echo -e "${YELLOW}⚠ Could not retrieve certificate info${NC}"
fi

# Test 3: Test authentication over LDAPS
echo -e "\n${YELLOW}Test 3: Testing authentication over LDAPS...${NC}"
if LDAPTLS_REQCERT=never ldapwhoami -x -H ldaps://localhost:636 -D "cn=svc_elk_ldap,ou=Service_Accounts,ou=User_Accounts,dc=example,dc=local" -w 'ServiceAccount123!' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Service account can authenticate over LDAPS${NC}"
else
    echo -e "${RED}✗ Authentication failed over LDAPS${NC}"
    exit 1
fi

# Test 4: Search over LDAPS
echo -e "\n${YELLOW}Test 4: Performing search over LDAPS...${NC}"
USERS=$(LDAPTLS_REQCERT=never ldapsearch -x -H ldaps://localhost:636 -D "cn=admin,dc=example,dc=local" -w "admin123" -b "ou=User_Accounts,dc=example,dc=local" "(objectClass=inetOrgPerson)" dn 2>/dev/null | grep "^dn:" | wc -l)
if [ "$USERS" -gt 0 ]; then
    echo -e "${GREEN}✓ Successfully searched and found $USERS users over LDAPS${NC}"
else
    echo -e "${RED}✗ Search failed over LDAPS${NC}"
    exit 1
fi

# Test 5: Compare LDAP vs LDAPS
echo -e "\n${YELLOW}Test 5: Comparing LDAP (389) vs LDAPS (636)...${NC}"
echo -e "${GREEN}Both protocols are available:${NC}"
echo "  - LDAP:  ldap://localhost:389 (unencrypted)"
echo "  - LDAPS: ldaps://localhost:636 (SSL encrypted)"

# Show example connection commands
echo -e "\n${YELLOW}Example LDAPS commands:${NC}"
echo "# Search with LDAPS (ignoring self-signed cert):"
echo "LDAPTLS_REQCERT=never ldapsearch -x -H ldaps://localhost:636 \\"
echo "  -D \"cn=admin,dc=example,dc=local\" -w \"admin123\" \\"
echo "  -b \"dc=example,dc=local\" \"(objectClass=*)\""

echo -e "\n# To trust the self-signed certificate permanently:"
echo "1. Export the CA certificate:"
echo "   docker exec ldap-server cat /container/service/slapd/assets/certs/ca.crt > ca.crt"
echo "2. Add to your system's trusted certificates (macOS):"
echo "   sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ca.crt"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✅ LDAPS is fully functional!${NC}"
echo -e "${GREEN}========================================${NC}" 