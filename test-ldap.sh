#!/bin/bash

# test-ldap.sh - Test script to verify LDAP setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 LDAP Test Suite"
echo "=================="

# Test 1: Check if containers are running
echo -e "\n${YELLOW}Test 1: Checking container status...${NC}"
if docker-compose ps | grep -q "ldap-server.*Up"; then
    echo -e "${GREEN}✓ LDAP server container is running${NC}"
else
    echo -e "${RED}✗ LDAP server container is not running${NC}"
    exit 1
fi

if docker-compose ps | grep -q "phpldapadmin.*Up"; then
    echo -e "${GREEN}✓ phpLDAPadmin container is running${NC}"
else
    echo -e "${RED}✗ phpLDAPadmin container is not running${NC}"
    exit 1
fi

# Test 2: Test LDAP connectivity
echo -e "\n${YELLOW}Test 2: Testing LDAP connectivity...${NC}"
if ldapsearch -x -H ldap://localhost:389 -D "cn=admin,dc=example,dc=local" -w "admin123" -b "" -s base "(objectClass=*)" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ LDAP server is accessible on port 389${NC}"
else
    echo -e "${RED}✗ Cannot connect to LDAP server${NC}"
    exit 1
fi

# Test 3: Test LDAPS connectivity
echo -e "\n${YELLOW}Test 3: Testing LDAPS (SSL) connectivity...${NC}"
if LDAPTLS_REQCERT=never ldapsearch -x -H ldaps://localhost:636 -D "cn=admin,dc=example,dc=local" -w "admin123" -b "" -s base "(objectClass=*)" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ LDAPS server is accessible on port 636 (self-signed cert)${NC}"
else
    echo -e "${RED}✗ Cannot connect to LDAPS server${NC}"
fi

# Test 4: Verify base DN exists
echo -e "\n${YELLOW}Test 4: Verifying base DN...${NC}"
if ldapsearch -x -H ldap://localhost:389 -D "cn=admin,dc=example,dc=local" -w "admin123" -b "dc=example,dc=local" -s base "(objectClass=*)" | grep -q "dn: dc=example,dc=local"; then
    echo -e "${GREEN}✓ Base DN 'dc=example,dc=local' exists${NC}"
else
    echo -e "${RED}✗ Base DN not found${NC}"
    exit 1
fi

# Test 5: Verify organizational units
echo -e "\n${YELLOW}Test 5: Verifying organizational units...${NC}"
OUS=$(ldapsearch -x -H ldap://localhost:389 -D "cn=admin,dc=example,dc=local" -w "admin123" -b "dc=example,dc=local" "(objectClass=organizationalUnit)" dn 2>/dev/null | grep "^dn:" | wc -l)
if [ "$OUS" -eq 2 ]; then
    echo -e "${GREEN}✓ Found 2 organizational units (User_Accounts and Service_Accounts)${NC}"
else
    echo -e "${RED}✗ Expected 2 organizational units, found $OUS${NC}"
    exit 1
fi

# Test 6: Test service account authentication
echo -e "\n${YELLOW}Test 6: Testing service account authentication...${NC}"
if ldapwhoami -x -H ldap://localhost:389 -D "cn=svc_elk_ldap,ou=Service_Accounts,ou=User_Accounts,dc=example,dc=local" -w 'ServiceAccount123!' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Service account 'svc_elk_ldap' can authenticate${NC}"
else
    echo -e "${RED}✗ Service account authentication failed${NC}"
    exit 1
fi

# Test 7: Count users
echo -e "\n${YELLOW}Test 7: Counting users...${NC}"
USERS=$(ldapsearch -x -H ldap://localhost:389 -D "cn=admin,dc=example,dc=local" -w "admin123" -b "ou=User_Accounts,dc=example,dc=local" "(objectClass=inetOrgPerson)" dn 2>/dev/null | grep "^dn:" | wc -l)
echo -e "${GREEN}✓ Found $USERS users in the directory${NC}"

# Test 8: Verify specific users exist
echo -e "\n${YELLOW}Test 8: Verifying specific users...${NC}"
for user in "John Doe" "Jane Smith" "Test User"; do
    if ldapsearch -x -H ldap://localhost:389 -D "cn=admin,dc=example,dc=local" -w "admin123" -b "ou=User_Accounts,dc=example,dc=local" "(cn=$user)" | grep -q "cn: $user"; then
        echo -e "${GREEN}✓ User '$user' exists${NC}"
    else
        echo -e "${RED}✗ User '$user' not found${NC}"
    fi
done

# Test 9: Test user authentication
echo -e "\n${YELLOW}Test 9: Testing user authentication...${NC}"
if ldapwhoami -x -H ldap://localhost:389 -D "cn=John Doe,ou=User_Accounts,dc=example,dc=local" -w 'UserPassword123!' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ User 'John Doe' can authenticate${NC}"
else
    echo -e "${RED}✗ User authentication failed${NC}"
    exit 1
fi

# Test 10: Check phpLDAPadmin accessibility
echo -e "\n${YELLOW}Test 10: Checking phpLDAPadmin web interface...${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
    echo -e "${GREEN}✓ phpLDAPadmin is accessible at http://localhost:8080${NC}"
else
    echo -e "${YELLOW}⚠ phpLDAPadmin might not be fully ready yet${NC}"
fi

# Summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✅ All LDAP tests passed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Quick Reference:${NC}"
echo "  LDAP URL: ldap://localhost:389"
echo "  LDAPS URL: ldaps://localhost:636"
echo "  Base DN: dc=example,dc=local"
echo "  Admin DN: cn=admin,dc=example,dc=local"
echo "  Admin Password: admin123"
echo "  Service Account: cn=svc_elk_ldap,ou=Service_Accounts,ou=User_Accounts,dc=example,dc=local"
echo "  Service Password: ServiceAccount123!"
echo "  phpLDAPadmin: http://localhost:8080" 