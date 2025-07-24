#!/bin/bash

# generate-certs.sh - Generate self-signed certificates for LDAPS

echo "🔐 Generating self-signed certificates for LDAPS..."

# Create certs directory
mkdir -p certs

cd certs

# Generate private key
echo "Generating private key..."
openssl genrsa -out ldap.key 2048

# Generate certificate
echo "Generating self-signed certificate..."
openssl req -new -x509 -days 365 -key ldap.key -out ldap.crt \
  -subj "/C=US/ST=State/L=City/O=Example Corp/CN=ldap.example.local"

# Generate CA certificate (same as server cert for self-signed)
cp ldap.crt ca.crt

# Set proper permissions
chmod 600 ldap.key
chmod 644 ldap.crt ca.crt

cd ..

echo "✅ Certificates generated in ./certs/"
echo "   - ldap.key (private key)"
echo "   - ldap.crt (certificate)"
echo "   - ca.crt (CA certificate)" 