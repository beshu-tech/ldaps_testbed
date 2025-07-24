#!/bin/bash

# Wait for LDAP to be ready
echo "Waiting for LDAP server to be ready..."
until ldapsearch -x -H ldap://openldap:389 -D "cn=admin,dc=example,dc=local" -w "admin123" -b "dc=example,dc=local" -s base "(objectClass=*)" > /dev/null 2>&1; do
    echo -n "."
    sleep 1
done
echo " Ready!"

# Load the structure
echo "Loading LDAP structure..."
ldapadd -x -H ldap://openldap:389 -D "cn=admin,dc=example,dc=local" -w "admin123" -f /ldif/01-structure.ldif

echo "LDAP structure loaded successfully!" 