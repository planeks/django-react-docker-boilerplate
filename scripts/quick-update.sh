#!/bin/bash
set -e

ENVIRONMENT=${1:-staging}
CLOUD_PROVIDER=${2:-aws}

echo "Running quick update for $ENVIRONMENT on $CLOUD_PROVIDER..."

cd ansible
ansible-playbook -i inventory/${CLOUD_PROVIDER}.yml \
  -e "deploy_env=${ENVIRONMENT}" \
  playbooks/deploy-django.yml
