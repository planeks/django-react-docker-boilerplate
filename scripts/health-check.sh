#!/bin/bash
# Server Health Check Script
# Checks the health of all critical services

set -e

echo "========================================="
echo "SERVER HEALTH CHECK"
echo "========================================="
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="

# Check Docker
echo -e "\n[Docker Service]"
if systemctl is-active --quiet docker; then
    echo "✓ Docker is running"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo "✗ Docker is not running"
fi

# Check disk space
echo -e "\n[Disk Space]"
df -h / | tail -1 | awk '{print "Used: " $3 " / " $2 " (" $5 ")"}'
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo "⚠ WARNING: Disk usage above 80%"
fi

# Check memory
echo -e "\n[Memory]"
free -h | grep Mem | awk '{print "Used: " $3 " / " $2}'

# Check system load
echo -e "\n[System Load]"
uptime | awk -F'load average:' '{print "Load Average:" $2}'

# Check Docker container health
echo -e "\n[Container Health]"
docker ps --filter "health=unhealthy" --format "{{.Names}}: {{.Status}}" | while read line; do
    if [ -n "$line" ]; then
        echo "✗ $line"
    fi
done

UNHEALTHY=$(docker ps --filter "health=unhealthy" -q | wc -l)
if [ "$UNHEALTHY" -eq 0 ]; then
    echo "✓ All containers are healthy"
fi

# Check critical ports
echo -e "\n[Network Ports]"
for port in 80 443 22; do
    if netstat -tuln | grep -q ":$port "; then
        echo "✓ Port $port is open"
    else
        echo "✗ Port $port is not listening"
    fi
done

# Check firewall
echo -e "\n[Firewall]"
if systemctl is-active --quiet ufw; then
    echo "✓ UFW is active"
    ufw status | grep "Status:"
else
    echo "⚠ UFW is not active"
fi

echo -e "\n========================================="
echo "Health check complete"
echo "========================================="
