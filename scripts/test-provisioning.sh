#!/bin/bash
# Test Provisioning Script
# Validates that a freshly provisioned server meets all requirements

CLOUD_PROVIDER=${1:-aws}
ENVIRONMENT=${2:-production}
SERVER_IP=${3}
SERVER_USER=${4:root}

if [ -z "$SERVER_IP" ]; then
    echo "Usage: $0 [cloud_provider] [environment] <server_ip>  [server_user]"
    echo "Example: $0 aws production 192.168.1.100 root"
    exit 1
fi

echo "========================================="
echo "PROVISIONING VALIDATION TEST"
echo "========================================="
echo "Server: $SERVER_IP"
echo "Environment: $ENVIRONMENT"
echo "Cloud Provider: $CLOUD_PROVIDER"
echo "========================================="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to run test
run_test() {
    local test_name=$1
    local command=$2

    echo -e "\n[Testing] $test_name..."

    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test SSH connectivity
echo -e "\n${YELLOW}=== Connectivity Tests ===${NC}"
run_test "SSH connectivity" "echo 'Connected'"

# Test security configurations
echo -e "\n${YELLOW}=== Security Tests ===${NC}"
run_test "UFW firewall enabled" "sudo ufw status | grep -q 'Status: active'"
run_test "Fail2ban running" "sudo systemctl is-active fail2ban"
run_test "SSH root login disabled" "sudo grep -q '^PermitRootLogin no' /etc/ssh/sshd_config"
run_test "SSH password auth disabled" "sudo grep -q '^PasswordAuthentication no' /etc/ssh/sshd_config"

# Test Docker installation
echo -e "\n${YELLOW}=== Docker Tests ===${NC}"
run_test "Docker installed" "docker --version"
run_test "Docker service running" "sudo systemctl is-active docker"
run_test "Docker Compose installed" "docker compose version"
run_test "Docker daemon configured" "test -f /etc/docker/daemon.json"
run_test "Journald logging configured" "sudo grep -q journald /etc/docker/daemon.json"

# Test user configuration
echo -e "\n${YELLOW}=== User Configuration Tests ===${NC}"
run_test "App user exists" "id ubuntu"
run_test "App user in docker group" "groups ubuntu | grep -q docker"
run_test "Django group (GID 1024) exists" "getent group django | grep -q 1024"
run_test "App user in django group" "groups ubuntu | grep -q django"
run_test "Projects directory exists" "test -d /home/ubuntu/projects"

# Test directory structure
echo -e "\n${YELLOW}=== Directory Structure Tests ===${NC}"
run_test "Project directory exists" "test -d /home/ubuntu/projects/django-react-docker-boilerplate"
run_test "Logs volume directory exists" "test -d /home/ubuntu/projects/django-react-docker-boilerplate/logs"
run_test "Media volume directory exists" "test -d /home/ubuntu/projects/django-react-docker-boilerplate/media"
run_test "Static volume directory exists" "test -d /home/ubuntu/projects/django-react-docker-boilerplate/staticfiles"

# Test monitoring
echo -e "\n${YELLOW}=== Monitoring Tests ===${NC}"
if run_test "Node Exporter installed" "test -f /usr/local/bin/node_exporter"; then
    run_test "Node Exporter service running" "sudo systemctl is-active node_exporter"
    run_test "Node Exporter responding" "curl -s http://localhost:9100/metrics | grep -q node_"
fi

# Test network (local)
echo -e "\n${YELLOW}=== Network Tests (Local) ===${NC}"
run_test "Port 22 open (SSH)" "sudo netstat -tuln | grep -q ':22 '"
run_test "Port 80 available (HTTP)" "! sudo netstat -tuln | grep -q ':80 ' || docker ps | grep -q caddy"
run_test "Port 443 available (HTTPS)" "! sudo netstat -tuln | grep -q ':443 ' || docker ps | grep -q caddy"

# Test cloud firewall (AWS Security Groups)
if [ "$CLOUD_PROVIDER" = "aws" ] && command -v aws &> /dev/null; then
    echo -e "\n${YELLOW}=== AWS Security Group Tests ===${NC}"

    INSTANCE_ID=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$SERVER_IP "curl -s http://169.254.169.254/latest/meta-data/instance-id" 2>/dev/null || echo "")

    if [ -n "$INSTANCE_ID" ]; then
        echo "Instance ID: $INSTANCE_ID"

        # Check security group rules
        SG_ID=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "")

        if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
            echo "Security Group: $SG_ID"

            # Check if port 22 is open
            if aws ec2 describe-security-groups --group-ids "$SG_ID" --query "SecurityGroups[0].IpPermissions[?FromPort==\`22\`]" --output text | grep -q "22"; then
                echo -e "${GREEN}✓ PASS${NC}: Port 22 (SSH) open in security group"
                ((TESTS_PASSED++))
            else
                echo -e "${RED}✗ FAIL${NC}: Port 22 (SSH) not open in security group"
                ((TESTS_FAILED++))
            fi

            # Check if port 80 is open
            if aws ec2 describe-security-groups --group-ids "$SG_ID" --query "SecurityGroups[0].IpPermissions[?FromPort==\`80\`]" --output text | grep -q "80"; then
                echo -e "${GREEN}✓ PASS${NC}: Port 80 (HTTP) open in security group"
                ((TESTS_PASSED++))
            else
                echo -e "${RED}✗ FAIL${NC}: Port 80 (HTTP) not open in security group"
                ((TESTS_FAILED++))
            fi

            # Check if port 443 is open
            if aws ec2 describe-security-groups --group-ids "$SG_ID" --query "SecurityGroups[0].IpPermissions[?FromPort==\`443\`]" --output text | grep -q "443"; then
                echo -e "${GREEN}✓ PASS${NC}: Port 443 (HTTPS) open in security group"
                ((TESTS_PASSED++))
            else
                echo -e "${RED}✗ FAIL${NC}: Port 443 (HTTPS) not open in security group"
                ((TESTS_FAILED++))
            fi
        else
            echo -e "${YELLOW}⚠ SKIP${NC}: Could not retrieve security group ID"
        fi
    else
        echo -e "${YELLOW}⚠ SKIP${NC}: Not an AWS instance or cannot retrieve instance ID"
    fi
fi

# Test GitHub Actions setup
echo -e "\n${YELLOW}=== GitHub Actions Setup Tests ===${NC}"
run_test ".env template exists" "test -f /home/ubuntu/projects/django-react-docker-boilerplate/.env.template"
run_test ".env file exists" "test -f /home/ubuntu/projects/django-react-docker-boilerplate/.env"
run_test "App directory writable by ubuntu user" "test -w /home/ubuntu/projects/django-react-docker-boilerplate"

# Test essential packages
echo -e "\n${YELLOW}=== Package Tests ===${NC}"
run_test "Git installed" "git --version"
run_test "Curl installed" "curl --version"
run_test "Python3 installed" "python3 --version"
run_test "Pip3 installed" "pip3 --version"

# Test system configuration
echo -e "\n${YELLOW}=== System Configuration Tests ===${NC}"
run_test "Unattended upgrades configured" "test -f /etc/apt/apt.conf.d/50unattended-upgrades"
run_test "Timezone configured" "timedatectl status"

# Generate report
echo -e "\n========================================="
echo -e "TEST RESULTS"
echo -e "========================================="
echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"
echo -e "Total: $((TESTS_PASSED + TESTS_FAILED))"

SUCCESS_RATE=$((TESTS_PASSED * 100 / (TESTS_PASSED + TESTS_FAILED)))
echo -e "Success Rate: ${SUCCESS_RATE}%"
echo -e "========================================="

# Save report
REPORT_FILE="provisioning-test-$(date +%Y%m%d-%H%M%S).txt"
cat > "/tmp/$REPORT_FILE" <<EOF
Provisioning Validation Report
==============================
Date: $(date)
Server: $SERVER_IP
Environment: $ENVIRONMENT

Results:
--------
Passed: $TESTS_PASSED
Failed: $TESTS_FAILED
Success Rate: ${SUCCESS_RATE}%

Status: $([ $TESTS_FAILED -eq 0 ] && echo "READY FOR PRODUCTION" || echo "ISSUES FOUND - REVIEW REQUIRED")
EOF

echo -e "\nReport saved to /tmp/$REPORT_FILE"

# Exit with appropriate code
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed! Server is properly provisioned.${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed. Please review the failures above.${NC}"
    exit 1
fi