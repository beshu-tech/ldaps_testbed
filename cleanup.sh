#!/bin/bash

# cleanup.sh - Clean up LDAP Docker environment

echo "🧹 Cleaning up LDAP environment..."

# Stop and remove containers
docker-compose down -v

# Remove data directories and certificates
rm -rf ldap/ ldif/ certs/

echo "✅ Cleanup complete!" 