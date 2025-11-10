#!/bin/bash
# Security Update Script
# Applies security updates to servers

set -e

CLOUD_PROVIDER=${1:-aws}
ENVIRONMENT=${2:-production}
AUTO_REBOOT=${3:-false}

echo "========================================="
echo "SECURITY UPDATES"
echo "========================================="
echo "Cloud Provider: $CLOUD_PROVIDER"
echo "Environment: $ENVIRONMENT"
echo "Auto Reboot: $AUTO_REBOOT"
echo "========================================="

cd "$(dirname "$0")/../ansible" || exit 1

ansible-playbook -i inventory/${CLOUD_PROVIDER}.yml \
    -e "deploy_env=${ENVIRONMENT}" \
    playbooks/security-updates.yml

echo -e "\nSecurity updates applied successfully!"
