#!/bin/bash
# Server Provisioning Script
# Automates the complete setup of a new server from scratch

set -e

CLOUD_PROVIDER=${1:-aws}
ENVIRONMENT=${2:-production}
SERVER_IP=${3}
SSH_USER=${4:root}


if [ -z "$SERVER_IP" ]; then
    echo "Usage: $0 <cloud_provider> <environment> <server_ip> <ssh_user>"
    echo "Example: $0 aws production 192.168.1.100 root"
    exit 1
fi

echo "========================================="
echo "SERVER PROVISIONING"
echo "========================================="
echo "Cloud Provider: $CLOUD_PROVIDER"
echo "Environment: $ENVIRONMENT"
echo "Server IP: $SERVER_IP"
echo "SSH User: $SSH_USER"
echo "========================================="

cd "$(dirname "$0")/../ansible" || exit 1

# Load environment variables from .env.ansible if it exists
if [ -f ".env.ansible" ]; then
    echo -e "\n[Loading environment variables from .env.ansible]"
    set -a  # Automatically export all variables
    source .env.ansible
    set +a
    echo "✓ Environment variables loaded"
else
    echo -e "\n⚠ WARNING: .env.ansible not found"
    echo "Create ansible/.env.ansible with required variables"
    echo "See ansible/.env.ansible.example for template"
    echo ""
    read -p "Continue without .env.ansible? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Provisioning cancelled."
        exit 1
    fi
fi

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
