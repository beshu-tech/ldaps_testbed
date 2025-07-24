# LDAP Server with SSL/TLS in Docker

This Docker setup provides a complete LDAP server with **LDAPS (LDAP over SSL)** support using self-signed certificates.

## Quick Start

1. **Generate SSL certificates:**
   ```bash
   chmod +x generate-certs.sh
   ./generate-certs.sh
   ```

2. **Start the containers:**
   ```bash
   docker-compose up -d
   ```
   This will:
   - Start the LDAP server with SSL/TLS enabled
   - Automatically load the directory structure
   - Make both LDAP (389) and LDAPS (636) available

3. **Verify the setup:**
   ```bash
   # Run the test suite
   chmod +x test-ldap.sh test-ldaps.sh
   ./test-ldap.sh    # General tests
   ./test-ldaps.sh   # SSL-specific tests
   ```

## Configuration Details

### LDAP Server Information
- **LDAP URL:** `ldap://localhost:389`
- **LDAPS URL:** `ldaps://localhost:636`
- **Base DN:** `dc=example,dc=local`
- **Domain:** `example.local`

### Admin Account
- **Admin DN:** `cn=admin,dc=example,dc=local`
- **Password:** `admin123`

### Service Account (for your application)
- **Bind DN:** `cn=svc_elk_ldap,ou=Service_Accounts,ou=User_Accounts,dc=example,dc=local`
- **Password:** `ServiceAccount123!`

### Directory Structure
```
dc=example,dc=local
└── ou=User_Accounts
    ├── ou=Service_Accounts
    │   └── cn=svc_elk_ldap (service account)
    ├── cn=John Doe (test user)
    ├── cn=Jane Smith (test user)
    └── cn=Test User (test user)
```

### Test Users
- **John Doe:** uid=jdoe, password=UserPassword123!
- **Jane Smith:** uid=jsmith, password=UserPassword123!
- **Test User:** uid=testuser, password=TestPassword123!

## Testing the Connection

### Using LDAPS (SSL - port 636)
```bash
# Test LDAPS connection (self-signed cert)
LDAPTLS_REQCERT=never ldapsearch -x -H ldaps://localhost:636 \
  -D "cn=svc_elk_ldap,ou=Service_Accounts,ou=User_Accounts,dc=example,dc=local" \
  -w "ServiceAccount123!" \
  -b "ou=User_Accounts,dc=example,dc=local" \
  "(objectClass=*)"
```

### Using LDAP (unencrypted - port 389)
```bash
# Test regular LDAP connection
ldapsearch -x -H ldap://localhost:389 \
  -D "cn=svc_elk_ldap,ou=Service_Accounts,ou=User_Accounts,dc=example,dc=local" \
  -w "ServiceAccount123!" \
  -b "ou=User_Accounts,dc=example,dc=local" \
  "(objectClass=*)"
```

### For your Anaphora client configuration:
- **URL:** `ldaps://localhost:636`
- **Bind DN:** `cn=svc_elk_ldap,ou=Service_Accounts,ou=User_Accounts,dc=example,dc=local`
- **Bind credentials:** `ServiceAccount123!`
- **Search base:** `ou=User_Accounts,dc=example,dc=local`
- **Search filter:** `(objectClass=*)`

### Handling Self-Signed Certificates
Since we're using self-signed certificates, your client may need to:
1. Accept the certificate (usually there's a "trust anyway" option)
2. Or import the CA certificate from `ldap/certs/ca.crt`

## Web Interface
Access phpLDAPadmin at: http://localhost:8080
- Login DN: `cn=admin,dc=example,dc=local`
- Password: `admin123`

## Troubleshooting

### Certificate Issues
If you encounter certificate validation errors:
```bash
# View certificate details
openssl s_client -connect localhost:636 -showcerts

# Test without certificate validation
ldapsearch -x -H ldaps://localhost:636 \
  -D "cn=admin,dc=example,dc=local" \
  -w "admin123" \
  -b "dc=example,dc=local" \
  -Z
```

### Container Logs
```bash
# View LDAP server logs
docker-compose logs openldap

# Follow logs in real-time
docker-compose logs -f openldap
```

### Reset Everything
```bash
# Stop and remove containers
docker-compose down

# Remove all data (careful!)
rm -rf ldap/

# Start fresh
./setup-ldap.sh
docker-compose up -d
```

## Security Notes
- This setup uses self-signed certificates suitable for testing
- Default passwords are provided - change them for any non-test environment
- The LDAP admin password and service account passwords should be changed
- Consider using proper CA-signed certificates for production
