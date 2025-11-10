#!/bin/bash
set -e

CLOUD_PROVIDER=${1:-aws}
RETENTION_DAYS=${2:-30}

echo "Cleaning up backups older than $RETENTION_DAYS days on $CLOUD_PROVIDER..."

cd ansible
ansible-playbook -i inventory/${CLOUD_PROVIDER}.yml \
  -e "retention_days=${RETENTION_DAYS}" \
  playbooks/cleanup-backups.yml
