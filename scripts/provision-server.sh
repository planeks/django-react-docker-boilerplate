#!/bin/bash
# Server Provisioning Script
# Automates the complete setup of a new server from scratch

set -e

CLOUD_PROVIDER=${1:-aws}
ENVIRONMENT=${2:-production}
SERVER_IP=${3}

if [ -z "$SERVER_IP" ]; then
    echo "Usage: $0 <cloud_provider> <environment> <server_ip>"
    echo "Example: $0 aws production 192.168.1.100"
    exit 1
fi

echo "========================================="
echo "SERVER PROVISIONING"
echo "========================================="
echo "Cloud Provider: $CLOUD_PROVIDER"
echo "Environment: $ENVIRONMENT"
echo "Server IP: $SERVER_IP"
echo "========================================="

cd "$(dirname "$0")/../ansible" || exit 1

# Run provisioning playbook
echo -e "\nStarting server provisioning..."
ansible-playbook -i "$SERVER_IP," \
    -e "deploy_env=${ENVIRONMENT}" \
    -e "cloud_provider=${CLOUD_PROVIDER}" \
    -e "auto_reboot=false" \
    playbooks/provision.yml

echo -e "\nProvisioning complete!"
echo "Next steps:"
echo "1. Review the provisioning summary above"
echo "2. If reboot is required, manually reboot the server"
echo "3. Run security-updates.yml for the latest patches"
echo "4. Deploy your application using deploy-django.yml"
