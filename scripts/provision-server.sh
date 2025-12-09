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
ANSIBLE_CMD="$ANSIBLE_CMD -e deploy_app=true"

# Pass critical environment variables as extra vars (since group_vars won't load with comma-separated inventory)
if [ -n "$APP_USER" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD -e app_user='${APP_USER}'"
    echo "→ Using APP_USER: $APP_USER"
fi

if [ -n "$ANSIBLE_REMOTE_USER" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD -e ansible_user='${ANSIBLE_REMOTE_USER}'"
    echo "→ Using ANSIBLE_REMOTE_USER: $ANSIBLE_REMOTE_USER"
fi

# Override ansible_user if SSH_USER is provided from command line
if [ -n "$SSH_USER" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD -e ansible_user='${SSH_USER}'"
    echo "→ Overriding SSH user with: $SSH_USER"
fi

# Handle GitHub Actions SSH key - auto-generate if not provided
echo -e "\n[GitHub Actions SSH Key Setup]"
SSH_KEY_DIR="$HOME/.ssh"
SSH_KEY_FILE="$SSH_KEY_DIR/github_actions"

if [ -z "$GITHUB_ACTIONS_SSH_KEY" ]; then
    echo "GITHUB_ACTIONS_SSH_KEY not set in .env.ansible"

    # Check if key already exists
    if [ -f "$SSH_KEY_FILE.pub" ]; then
        echo "✓ Found existing key at $SSH_KEY_FILE.pub"
        echo "→ Using existing SSH key for GitHub Actions"
        GITHUB_ACTIONS_SSH_KEY=$(cat "$SSH_KEY_FILE.pub" | tr -d '\n' | xargs)
    else
        echo "→ Generating new SSH key pair for GitHub Actions..."
        mkdir -p "$SSH_KEY_DIR"
        ssh-keygen -t ed25519 -C "github-actions" -f "$SSH_KEY_FILE" -N "" -q
        echo "✓ Generated new SSH key pair at $SSH_KEY_FILE"
        GITHUB_ACTIONS_SSH_KEY=$(cat "$SSH_KEY_FILE.pub" | tr -d '\n' | xargs)
    fi

    # Export for use in this session
    export GITHUB_ACTIONS_SSH_KEY

    echo ""
    echo "========================================="
    echo "⚠️  IMPORTANT: GitHub Secret Required"
    echo "========================================="
    echo ""
    echo "Add this PRIVATE key to GitHub Secrets:"
    echo "Repository: Settings > Secrets and variables > Actions"
    echo "Secret name: PROD_SSH_KEY"
    echo ""
    echo "Private key location: $SSH_KEY_FILE"
    echo ""
    echo "To view the private key:"
    echo "  cat $SSH_KEY_FILE"
    echo ""
    echo "To copy to clipboard (if xclip installed):"
    echo "  cat $SSH_KEY_FILE | xclip -selection clipboard"
    echo "========================================="
    echo ""
else
    echo "✓ GITHUB_ACTIONS_SSH_KEY is set (length: ${#GITHUB_ACTIONS_SSH_KEY})"
    # Ensure it's exported even if loaded from .env.ansible
    export GITHUB_ACTIONS_SSH_KEY
fi

# ============================================================================
# Auto-detect Git Repository Configuration
# ============================================================================
# If GIT_REPO_URL is not set in environment, auto-detect from current repository
# This allows deployment to work out of the box when run from within a git repo

echo -e "\n[Git Repository Configuration]"

if [ -z "$GIT_REPO_URL" ]; then
    # Try to auto-detect from git remote
    if git remote get-url origin &>/dev/null; then
        DETECTED_URL=$(git remote get-url origin 2>/dev/null | sed -E 's#.*/git/([^/]+/[^/]+).*#git@github.com:\1.git#')
        if [ -n "$DETECTED_URL" ] && [[ "$DETECTED_URL" =~ ^git@github\.com:.+\.git$ ]]; then
            GIT_REPO_URL="$DETECTED_URL"
            echo "→ Auto-detected GIT_REPO_URL: $GIT_REPO_URL"
        else
            echo "⚠ Could not auto-detect valid GitHub URL from git remote"
        fi
    else
        echo "⚠ Not in a git repository, skipping auto-detection"
    fi
fi

if [ -z "$GIT_BRANCH" ]; then
    # Try to auto-detect current branch
    if git rev-parse --abbrev-ref HEAD &>/dev/null; then
        GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        echo "→ Auto-detected GIT_BRANCH: $GIT_BRANCH"
    else
        GIT_BRANCH="main"
        echo "→ Using default GIT_BRANCH: $GIT_BRANCH"
    fi
fi

# Display final git configuration
if [ -n "$GIT_REPO_URL" ]; then
    echo "✓ Repository URL: $GIT_REPO_URL"
    echo "✓ Branch: $GIT_BRANCH"
    echo "→ Application will be deployed during provisioning"
else
    echo "⚠ GIT_REPO_URL not configured"
    echo "→ Server will be provisioned but app deployment will be skipped"
    echo "→ Set GIT_REPO_URL in .env.ansible or run from within git repository"
fi

# ============================================================================
# Pass Environment Variables to Ansible
# ============================================================================

echo -e "\n[Checking other environment variables]"
for var in DOMAIN_NAME SSL_EMAIL DB_PASSWORD GIT_REPO_URL GIT_BRANCH PROJECT_NAME; do
    if [ -n "${!var}" ]; then
        echo "✓ $var is set"
    fi
done

echo -e "\n[Passing variables to Ansible]"
for var in DOMAIN_NAME SSL_EMAIL DB_PASSWORD GIT_REPO_URL GIT_BRANCH PROJECT_NAME; do
    if [ -n "${!var}" ]; then
        # Convert to lowercase with underscores for Ansible variable names
        ansible_var=$(echo "$var" | tr '[:upper:]' '[:lower:]')
        ANSIBLE_CMD="$ANSIBLE_CMD -e ${ansible_var}='${!var}'"
    fi
done

# Note: GITHUB_ACTIONS_SSH_KEY is passed via environment variable (exported above)
# to avoid shell quoting issues with long strings containing spaces

ANSIBLE_CMD="$ANSIBLE_CMD playbooks/provision.yml"

# Display command (mask sensitive values)
echo -e "\n[Ansible Command]"
MASKED_CMD=$(echo "$ANSIBLE_CMD" | sed -E "s/(db_password)='[^']*'/\1='***'/g")
echo "$MASKED_CMD"
echo ""
echo "Note: GITHUB_ACTIONS_SSH_KEY is passed via environment (not shown)"

# Execute the command
eval $ANSIBLE_CMD

echo -e "\n========================================="
echo "✅ Provisioning complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Review the provisioning summary above"
echo "2. If application was deployed, verify it's running:"
echo "   - Visit: http://$SERVER_IP"
echo "   - Check logs: ssh $SSH_USER@$SERVER_IP 'cd ~/projects/django_app && docker compose logs'"
echo "3. If reboot is required, manually reboot the server"
echo "4. Run security-updates.yml for the latest patches"
echo ""
