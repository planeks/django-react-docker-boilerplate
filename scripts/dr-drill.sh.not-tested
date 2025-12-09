#!/bin/bash
# Disaster Recovery Drill Script
# This script automates DR testing to ensure backups can be restored within the 30-minute target

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CLOUD_PROVIDER=${1:-aws}
ENVIRONMENT=${2:-staging}
DRILL_TYPE=${3:-full}  # full | database-only | validation-only

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}DISASTER RECOVERY DRILL${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Cloud Provider: $CLOUD_PROVIDER"
echo "Environment: $ENVIRONMENT"
echo "Drill Type: $DRILL_TYPE"
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${GREEN}========================================${NC}"

# Change to ansible directory
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
    if [ "$CLOUD_PROVIDER" = "digitalocean" ] || [ "$CLOUD_PROVIDER" = "aws" ]; then
        echo "Note: ${CLOUD_PROVIDER} dynamic inventory requires API credentials in .env.ansible"
    fi
fi

# Get the most recent backup timestamp
echo -e "\n${YELLOW}Finding most recent backup...${NC}"
if [ "$CLOUD_PROVIDER" = "aws" ]; then
    BACKUP_TIMESTAMP=$(aws s3 ls s3://$BACKUP_BUCKET/backups/ | grep db- | tail -1 | awk '{print $4}' | sed 's/db-//; s/.sql.gz//')
else
    # DigitalOcean Spaces
    BACKUP_TIMESTAMP=$(s3cmd ls s3://$BACKUP_BUCKET/backups/ | grep db- | tail -1 | awk '{print $4}' | sed 's/db-//; s/.sql.gz//')
fi

if [ -z "$BACKUP_TIMESTAMP" ]; then
    echo -e "${RED}ERROR: No backups found!${NC}"
    exit 1
fi

echo -e "${GREEN}Using backup: $BACKUP_TIMESTAMP${NC}"

# Run the disaster recovery playbook
echo -e "\n${YELLOW}Starting disaster recovery playbook...${NC}"
START_TIME=$(date +%s)

if [ "$DRILL_TYPE" = "validation-only" ]; then
    # Only validate, don't actually restore
    ansible-playbook -i inventory/${CLOUD_PROVIDER}.yml \
        -e "deploy_env=${ENVIRONMENT}" \
        -e "backup_timestamp=${BACKUP_TIMESTAMP}" \
        -e "restore_media=false" \
        -e "create_safety_backup=false" \
        playbooks/disaster-recovery.yml \
        --check
else
    # Full restoration
    ansible-playbook -i inventory/${CLOUD_PROVIDER}.yml \
        -e "deploy_env=${ENVIRONMENT}" \
        -e "backup_timestamp=${BACKUP_TIMESTAMP}" \
        -e "restore_media=$([ "$DRILL_TYPE" = "full" ] && echo true || echo false)" \
        -e "create_safety_backup=true" \
        playbooks/disaster-recovery.yml
fi

DR_EXIT_CODE=$?
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
DURATION_MINUTES=$(echo "scale=2; $DURATION / 60" | bc)

# Generate drill report
REPORT_FILE="dr-drill-report-$(date +%Y%m%d-%H%M%S).txt"

cat > "/tmp/$REPORT_FILE" <<EOF
========================================
DISASTER RECOVERY DRILL REPORT
========================================
Date: $(date '+%Y-%m-%d %H:%M:%S')
Cloud Provider: $CLOUD_PROVIDER
Environment: $ENVIRONMENT
Drill Type: $DRILL_TYPE
Backup Timestamp: $BACKUP_TIMESTAMP

RESULTS:
--------
Exit Code: $DR_EXIT_CODE
Status: $([ $DR_EXIT_CODE -eq 0 ] && echo "SUCCESS" || echo "FAILED")
Duration: $DURATION_MINUTES minutes ($DURATION seconds)
Target: 30 minutes
Target Met: $([ $DURATION -le 1800 ] && echo "YES" || echo "NO")

RECOMMENDATIONS:
----------------
EOF

# Add recommendations based on results
if [ $DR_EXIT_CODE -ne 0 ]; then
    cat >> "/tmp/$REPORT_FILE" <<EOF
- CRITICAL: Drill failed. Review logs immediately.
- Check backup integrity and accessibility.
- Verify all required credentials and permissions.
EOF
elif [ $DURATION -gt 1800 ]; then
    cat >> "/tmp/$REPORT_FILE" <<EOF
- WARNING: Drill exceeded 30-minute target.
- Consider optimizing backup download speed.
- Review database restore process for bottlenecks.
- Check network bandwidth and latency.
EOF
else
    cat >> "/tmp/$REPORT_FILE" <<EOF
- SUCCESS: All systems operational.
- Continue quarterly drills to maintain readiness.
- Document any process improvements discovered.
EOF
fi

cat >> "/tmp/$REPORT_FILE" <<EOF

========================================
EOF

# Display report
echo ""
cat "/tmp/$REPORT_FILE"

# Save report to project directory
cp "/tmp/$REPORT_FILE" "../docs/dr-reports/$REPORT_FILE"

# Send notification (optional - configure webhook or email)
if command -v curl &> /dev/null && [ -n "${SLACK_WEBHOOK_URL}" ]; then
    STATUS_EMOJI=$([ $DR_EXIT_CODE -eq 0 ] && echo ":white_check_mark:" || echo ":x:")
    curl -X POST "$SLACK_WEBHOOK_URL" \
        -H 'Content-Type: application/json' \
        -d "{\"text\":\"$STATUS_EMOJI DR Drill $([[ $DR_EXIT_CODE -eq 0 ]] && echo 'PASSED' || echo 'FAILED'): $DURATION_MINUTES min (Target: 30 min)\"}" \
        2>/dev/null || true
fi

# Exit with appropriate code
if [ $DR_EXIT_CODE -eq 0 ]; then
    echo -e "\n${GREEN}DR Drill completed successfully!${NC}"
    exit 0
else
    echo -e "\n${RED}DR Drill failed!${NC}"
    exit 1
fi
