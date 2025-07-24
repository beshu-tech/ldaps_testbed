# LDAP Server with SSL/TLS (LDAPS) in Docker

A complete LDAP server setup with **LDAPS (LDAP over SSL)** support using self-signed certificates. Features automatic directory structure loading and comprehensive testing.

## Features

- ✅ **LDAP** on port 389 (unencrypted)
- ✅ **LDAPS** on port 636 (SSL encrypted with self-signed certificates)
- ✅ **Automatic structure loading** - No manual LDIF imports needed
- ✅ **Pre-configured users and service accounts**
- ✅ **phpLDAPadmin** web interface
- ✅ **Comprehensive test suites**

## Quick Start

### 1. Generate SSL Certificates
```bash
chmod +x generate-certs.sh
./generate-certs.sh
```

### 2. Start the Services
```bash
docker-compose up -d
```

This will:
- Start OpenLDAP with SSL/TLS enabled
- Automatically load the directory structure from `01-structure.ldif`
- Start phpLDAPadmin web interface
- Make both LDAP (389) and LDAPS (636) available

### 3. Verify Everything Works
```bash
chmod +x test-ldap.sh test-ldaps.sh
./test-ldap.sh    # Tests general LDAP functionality
./test-ldaps.sh   # Tests SSL/TLS specific features
```

## Connection Details

### LDAP URLs
- **LDAP (unencrypted):** `ldap://localhost:389`
- **LDAPS (SSL):** `ldaps://localhost:636`

### Base Configuration
- **Base DN:** `dc=example,dc=local`
- **Admin DN:** `cn=admin,dc=example,dc=local`
- **Admin Password:** `admin123`

### Service Account (for applications)
- **Bind DN:** `cn=svc_elk_ldap,ou=Service_Accounts,ou=User_Accounts,dc=example,dc=local`
- **Password:** `ServiceAccount123!`

### Test Users
| User | Username | Password |
|------|----------|----------|
| John Doe | `uid=jdoe` | `UserPassword123!` |
| Jane Smith | `uid=jsmith` | `UserPassword123!` |
| Test User | `uid=testuser` | `TestPassword123!` |

### Web Interface
- **URL:** http://localhost:8080
- **Login DN:** `cn=admin,dc=example,dc=local`
- **Password:** `admin123`

## Directory Structure

The following structure is automatically created:
```
dc=example,dc=local
└── ou=User_Accounts
    ├── ou=Service_Accounts
    │   └── cn=svc_elk_ldap (service account)
    ├── cn=John Doe (test user)
    ├── cn=Jane Smith (test user)
    └── cn=Test User (test user)
```

## Using LDAPS (SSL)

### Connect with self-signed certificate
```bash
# Ignore certificate verification (development only)
LDAPTLS_REQCERT=never ldapsearch -x -H ldaps://localhost:636 \
  -D "cn=admin,dc=example,dc=local" \
  -w "admin123" \
  -b "dc=example,dc=local" \
  "(objectClass=*)"
```

### Trust the certificate permanently (macOS)
```bash
# Export the CA certificate
docker exec ldap-server cat /container/service/slapd/assets/certs/ca.crt > ca.crt

# Add to system keychain
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ca.crt
```

## Example Commands

### Search via LDAPS (encrypted)
```bash
LDAPTLS_REQCERT=never ldapsearch -x -H ldaps://localhost:636 \
  -D "cn=svc_elk_ldap,ou=Service_Accounts,ou=User_Accounts,dc=example,dc=local" \
  -w 'ServiceAccount123!' \
  -b "ou=User_Accounts,dc=example,dc=local" \
  "(objectClass=inetOrgPerson)"
```

### Search via LDAP (unencrypted)
```bash
ldapsearch -x -H ldap://localhost:389 \
  -D "cn=svc_elk_ldap,ou=Service_Accounts,ou=User_Accounts,dc=example,dc=local" \
  -w 'ServiceAccount123!' \
  -b "ou=User_Accounts,dc=example,dc=local" \
  "(objectClass=inetOrgPerson)"
```

### Test authentication
```bash
# Via LDAPS
LDAPTLS_REQCERT=never ldapwhoami -x -H ldaps://localhost:636 \
  -D "cn=John Doe,ou=User_Accounts,dc=example,dc=local" \
  -w 'UserPassword123!'

# Via LDAP
ldapwhoami -x -H ldap://localhost:389 \
  -D "cn=John Doe,ou=User_Accounts,dc=example,dc=local" \
  -w 'UserPassword123!'
```

## Project Files

- **`generate-certs.sh`** - Generates self-signed SSL certificates
- **`docker-compose.yml`** - Container configuration with SSL settings
- **`01-structure.ldif`** - Directory structure and users (auto-loaded)
- **`load-structure.sh`** - Script that loads LDIF (runs automatically)
- **`test-ldap.sh`** - General LDAP functionality tests
- **`test-ldaps.sh`** - SSL/TLS specific tests  
- **`cleanup.sh`** - Removes all containers, data, and certificates

## Troubleshooting

### View container logs
```bash
docker-compose logs -f openldap
```

### Check SSL certificate
```bash
echo | openssl s_client -connect localhost:636 -showcerts
```

### Reset everything
```bash
./cleanup.sh
./generate-certs.sh
docker-compose up -d
```

## How It Works

1. **SSL Certificates**: The `generate-certs.sh` script creates self-signed certificates in the `./certs` directory
2. **Automatic Loading**: The `ldap-loader` container waits for the LDAP server to be healthy, then loads `01-structure.ldif`
3. **Dual Protocol**: Both LDAP (389) and LDAPS (636) are available simultaneously
4. **Health Checks**: Docker health checks ensure the server is ready before loading data

## Security Notes

- This setup uses self-signed certificates suitable for development/testing
- For production, use proper CA-signed certificates
- Default passwords should be changed in production environments
- The `LDAPTLS_REQCERT=never` option should not be used in production

## Clean Up

To completely remove the LDAP environment:
```bash
./cleanup.sh
```

This removes:
- All Docker containers and volumes
- LDAP data directory
- Generated certificates
- Temporary files
