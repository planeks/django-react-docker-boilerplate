#!/bin/bash
# Unified Ansible Playbook Runner
# Simplifies running Ansible playbooks with common configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Show usage
usage() {
    cat << EOF
Usage: $0 <playbook> [OPTIONS]

Runs an Ansible playbook with automatic environment loading.

ARGUMENTS:
  playbook              Path to playbook (relative to ansible/playbooks/)
                        Examples: provision.yml, security-updates.yml

OPTIONS:
  -i, --inventory      Inventory file (default: aws.yml)
  -e, --extra-vars     Extra variables (can be used multiple times)
  -h, --help           Show this help message

EXAMPLES:
  # Run provisioning
  $0 provision.yml -i digitalocean.yml -e "deploy_env=production"

  # Run security updates
  $0 security-updates.yml -e "deploy_env=staging"

  # Run disaster recovery test
  $0 disaster-recovery.yml -i aws.yml -e "deploy_env=production"

  # Cleanup backups
  $0 cleanup-backups.yml -e "retention_days=30"

ENVIRONMENT:
  Automatically loads ansible/.env.ansible if present.
  See ansible/.env.ansible.example for template.

EOF
    exit 0
}

# Parse arguments
PLAYBOOK=""
INVENTORY="aws.yml"
EXTRA_VARS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -i|--inventory)
            INVENTORY="$2"
            shift 2
            ;;
        -e|--extra-vars)
            EXTRA_VARS+=("-e" "$2")
            shift 2
            ;;
        *)
            if [ -z "$PLAYBOOK" ]; then
                PLAYBOOK="$1"
            else
                echo -e "${RED}Error: Unknown argument '$1'${NC}"
                usage
            fi
            shift
            ;;
    esac
done

# Validate playbook
if [ -z "$PLAYBOOK" ]; then
    echo -e "${RED}Error: Playbook required${NC}"
    usage
fi

# Navigate to ansible directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/../ansible" || exit 1

# Check if playbook exists
if [ ! -f "playbooks/$PLAYBOOK" ]; then
    echo -e "${RED}Error: Playbook 'playbooks/$PLAYBOOK' not found${NC}"
    exit 1
fi

# Load environment variables
if [ -f ".env.ansible" ]; then
    echo -e "${GREEN}[Loading environment from .env.ansible]${NC}"
    set -a  # Automatically export all variables
    source .env.ansible
    set +a
    echo -e "${GREEN}✓ Environment loaded${NC}\n"
else
    echo -e "${YELLOW}⚠ WARNING: .env.ansible not found${NC}"
    echo "Create ansible/.env.ansible with required variables"
    echo "See ansible/.env.ansible.example for template"

    if [[ "$INVENTORY" == "digitalocean.yml" ]] || [[ "$INVENTORY" == "aws.yml" ]]; then
        echo -e "${YELLOW}Note: Cloud inventory requires API credentials in .env.ansible${NC}"
    fi
    echo ""
fi

# Display execution info
echo "========================================="
echo "Running Ansible Playbook"
echo "========================================="
echo "Playbook: $PLAYBOOK"
echo "Inventory: $INVENTORY"
if [ ${#EXTRA_VARS[@]} -gt 0 ]; then
    echo "Extra vars: ${EXTRA_VARS[*]}"
fi
echo "========================================="
echo ""

# Run ansible-playbook
ansible-playbook \
    -i "inventory/$INVENTORY" \
    "${EXTRA_VARS[@]}" \
    "playbooks/$PLAYBOOK"

echo -e "\n${GREEN}✓ Playbook executed successfully!${NC}"
