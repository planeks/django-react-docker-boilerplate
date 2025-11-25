#!/bin/bash
# Server Provisioning Script
# Automates the complete setup of a new server from scratch

set -e

CLOUD_PROVIDER=${1:-aws}
ENVIRONMENT=${2:-production}
SERVER_IP=${3}
SSH_USER=${4:-}  # Optional: Override ANSIBLE_REMOTE_USER from .env.ansible

if [ -z "$SERVER_IP" ]; then
    echo "Usage: $0 <cloud_provider> <environment> <server_ip> [ssh_user]"
    echo "Example: $0 aws production 192.168.1.100"
    echo "Example: $0 aws production 192.168.1.100 ubuntu"
    echo ""
    echo "Note: ssh_user overrides ANSIBLE_REMOTE_USER from .env.ansible"
    exit 1
fi

echo "========================================="
echo "SERVER PROVISIONING"
echo "========================================="
echo "Cloud Provider: $CLOUD_PROVIDER"
echo "Environment: $ENVIRONMENT"
echo "Server IP: $SERVER_IP"
if [ -n "$SSH_USER" ]; then
    echo "SSH User: $SSH_USER (from command line)"
else
    echo "SSH User: Will use ANSIBLE_REMOTE_USER from .env.ansible or default"
fi
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
    echo "Provisioning cancelled."
    exit 1
fi

# Run provisioning playbook
echo -e "\nStarting server provisioning..."

# Build ansible-playbook command
ANSIBLE_CMD="ansible-playbook -i $SERVER_IP,"
ANSIBLE_CMD="$ANSIBLE_CMD -e deploy_env=${ENVIRONMENT}"
ANSIBLE_CMD="$ANSIBLE_CMD -e cloud_provider=${CLOUD_PROVIDER}"
ANSIBLE_CMD="$ANSIBLE_CMD -e auto_reboot=false"

# Pass critical environment variables as extra vars (since group_vars won't load with comma-separated inventory)
if [ -n "$APP_USER" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD -e app_user=${APP_USER}"
    echo "→ Using APP_USER: $APP_USER"
fi

if [ -n "$ANSIBLE_REMOTE_USER" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD -e ansible_user=${ANSIBLE_REMOTE_USER}"
    echo "→ Using ANSIBLE_REMOTE_USER: $ANSIBLE_REMOTE_USER"
fi

# Override ansible_user if SSH_USER is provided from command line
if [ -n "$SSH_USER" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD -e ansible_user=${SSH_USER}"
    echo "→ Overriding SSH user with: $SSH_USER"
fi

# Pass other environment variables that might be needed
for var in DOMAIN_NAME SSL_EMAIL DB_PASSWORD GIT_REPO_URL GIT_BRANCH PROJECT_NAME; do
    if [ -n "${!var}" ]; then
        # Convert to lowercase with underscores for Ansible variable names
        ansible_var=$(echo "$var" | tr '[:upper:]' '[:lower:]')
        ANSIBLE_CMD="$ANSIBLE_CMD -e ${ansible_var}=${!var}"
    fi
done

ANSIBLE_CMD="$ANSIBLE_CMD playbooks/provision.yml"

# Execute the command
eval $ANSIBLE_CMD

echo -e "\nProvisioning complete!"
echo "Next steps:"
echo "1. Review the provisioning summary above"
echo "2. If reboot is required, manually reboot the server"
echo "3. Run security-updates.yml for the latest patches"
echo "4. Deploy your application using deploy-django.yml"
