#!/bin/bash

# setup-ldap.sh - Setup script for LDAP Docker environment with SSL

echo "Setting up LDAP Docker environment..."

# Create directory structure
echo "Creating directory structure..."
mkdir -p ldap/{data,config,certs,ldif}

# Generate self-signed certificates
echo "Generating self-signed certificates..."
cd ldap/certs

# Generate CA private key
openssl genrsa -out ca.key 4096

# Generate CA certificate
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/C=US/ST=State/L=City/O=Example Corp/CN=LDAP CA"

# Generate LDAP server private key
openssl genrsa -out ldap.key 4096

# Generate certificate signing request
openssl req -new -key ldap.key -out ldap.csr -subj "/C=US/ST=State/L=City/O=Example Corp/CN=ldap.example.com"

# Sign the certificate with CA
openssl x509 -req -in ldap.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out ldap.crt -days 3650

# Generate DH parameters (this might take a while)
echo "Generating DH parameters (this may take a few minutes)..."
openssl dhparam -out dhparam.pem 2048

# Clean up
rm ldap.csr

# Set proper permissions
chmod 644 *.crt
chmod 600 *.key
chmod 644 dhparam.pem

cd ../..

# Copy LDIF file
echo "Setting up LDIF files..."
cat > ldap/ldif/01-structure.ldif << 'EOF'
# Create root organizational units
dn: ou=User_Accounts,dc=example,dc=local
objectClass: organizationalUnit
ou: User_Accounts

dn: ou=Service_Accounts,ou=User_Accounts,dc=example,dc=local
objectClass: organizationalUnit
ou: Service_Accounts

# Create the service account for LDAP binding
dn: cn=svc_elk_ldap,ou=Service_Accounts,ou=User_Accounts,dc=example,dc=local
objectClass: inetOrgPerson
objectClass: organizationalPerson
objectClass: person
objectClass: top
cn: svc_elk_ldap
sn: Service Account
givenName: ELK LDAP
displayName: ELK LDAP Service Account
uid: svc_elk_ldap
mail: svc_elk_ldap@example.local
userPassword: ServiceAccount123!

# Create some test users
dn: cn=John Doe,ou=User_Accounts,dc=example,dc=local
objectClass: inetOrgPerson
objectClass: organizationalPerson
objectClass: person
objectClass: top
cn: John Doe
sn: Doe
givenName: John
displayName: John Doe
uid: jdoe
mail: john.doe@example.local
userPassword: UserPassword123!

dn: cn=Jane Smith,ou=User_Accounts,dc=example,dc=local
objectClass: inetOrgPerson
objectClass: organizationalPerson
objectClass: person
objectClass: top
cn: Jane Smith
sn: Smith
givenName: Jane
displayName: Jane Smith
uid: jsmith
mail: jane.smith@example.local
userPassword: UserPassword123!
EOF

echo "Setup complete!"
echo ""
echo "To start the LDAP server, run: docker-compose up -d"
echo ""
echo "Connection details:"
echo "  LDAP URL: ldap://localhost:389"
echo "  LDAPS URL: ldaps://localhost:636"
echo "  Base DN: dc=example,dc=local"
echo "  Admin DN: cn=admin,dc=example,dc=local"
echo "  Admin Password: admin123"
echo ""
echo "Service Account for binding:"
echo "  Bind DN: cn=svc_elk_ldap,ou=Service_Accounts,ou=User_Accounts,dc=example,dc=local"
echo "  Password: ServiceAccount123!"
echo ""
echo "phpLDAPadmin interface: http://localhost:8080"
echo "  Login DN: cn=admin,dc=example,dc=local"
echo "  Password: admin123"
