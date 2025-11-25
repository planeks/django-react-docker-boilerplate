# Infrastructure Documentation

## Table of Contents
- [Overview](#overview)
- [Server Provisioning](#server-provisioning)
- [Disaster Recovery](#disaster-recovery)
- [Security Updates](#security-updates)
- [Logging Management](#logging-management)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Maintenance Procedures](#maintenance-procedures)

## Overview

This project uses Infrastructure-as-Code (IaC) principles with Ansible to automate server provisioning, configuration, and disaster recovery. All infrastructure is version-controlled, repeatable, and documented.

### Architecture

- **Cloud Providers**: AWS and DigitalOcean supported
- **Configuration Management**: Ansible
- **Container Orchestration**: Docker Compose
- **Web Server**: Caddy (automatic HTTPS)
- **Database**: PostgreSQL
- **Cache**: Redis
- **Task Queue**: Celery
- **Logging**: Journald (systemd journal)
- **Monitoring**: Node Exporter (optional), Promtail (optional)

### Infrastructure Components

1. **Common Role**: Base system configuration, security hardening, firewall rules
2. **Docker Role**: Docker installation and configuration with journald logging
3. **SSL Role**: SSL certificate management (Let's Encrypt or Caddy automatic)
4. **Monitoring Role**: Metrics and log collection agents
5. **Failover Role**: High availability configuration
6. **Django Role**: Application deployment

---

## Server Provisioning

### Quick Start

Provision a new server from scratch:

```bash
./scripts/provision-server.sh aws production 192.168.1.100
```

Or use Ansible directly:

```bash
cd ansible
ansible-playbook -i "192.168.1.100," \
  -e "deploy_env=production" \
  -e "cloud_provider=aws" \
  playbooks/provision.yml
```

### What Gets Configured

The provisioning process configures:

1. **System Updates**: Latest security patches (production only)
2. **Security Hardening**:
   - SSH hardening (no root login, no password auth)
   - UFW firewall (ports 22, 80, 443)
   - Fail2ban intrusion prevention
   - Automatic security updates
3. **Cloud Security** (AWS):
   - Security Groups configured for ports 22, 80, 443
   - Inbound rules allowing web traffic
4. **Docker**: Latest stable version with journald logging
5. **SSL Certificates**: Caddy handles this automatically
6. **Directory Structure**: Application directories with correct permissions
7. **Monitoring Agents**: Node Exporter for metrics
8. **User Setup**: Application user with proper permissions
9. **GitHub Actions Integration**:
   - SSH keys configured for automated deployments
   - .env template created
   - Proper directory permissions for CI/CD

### Environment Variables

Set these environment variables before provisioning:

```bash
# Required for server setup
export DOMAIN_NAME=yourapp.com
export SSL_EMAIL=admin@yourapp.com
export DB_PASSWORD=secure_password

# Required for GitHub Actions integration
export GITHUB_ACTIONS_SSH_KEY=$(cat ~/.ssh/github_actions_deploy.pub)

# Optional (for app deployment during provisioning)
export GIT_REPO_URL=git@github.com:youruser/yourrepo.git
export GIT_BRANCH=main
export DJANGO_ADMIN_USER=admin
export DJANGO_ADMIN_PASSWORD=secure_password
export DJANGO_ADMIN_EMAIL=admin@yourapp.com

# AWS specific
export AWS_REGION=us-east-1
```

**Important:** The `GITHUB_ACTIONS_SSH_KEY` is crucial for enabling automated deployments. See [GitHub Actions Setup](github-actions-setup.md) for details.

### Supported Environments

- **development**: Development servers (minimal security, no auto-updates)
- **staging**: Staging environment (full security, testing)
- **production**: Production servers (maximum security, auto-updates optional)

### Tags

Run specific parts of provisioning using tags:

```bash
# Only security configuration
ansible-playbook playbooks/provision.yml --tags security

# Only Docker setup
ansible-playbook playbooks/provision.yml --tags docker

# Only monitoring
ansible-playbook playbooks/provision.yml --tags monitoring
```

---

## Disaster Recovery

### Overview

The disaster recovery (DR) system is designed to restore services from backups within 30 minutes. Regular DR drills ensure this target is met.

### Running a DR Drill

Automated DR drill (recommended):

```bash
./scripts/dr-drill.sh aws staging full
```

Options:
- `full`: Complete restoration (database + media files)
- `database-only`: Database restoration only
- `validation-only`: Dry run to validate backups

Manual DR execution:

```bash
cd ansible
export BACKUP_TIMESTAMP=2025-11-07-120000
ansible-playbook -i inventory/aws.yml \
  -e "deploy_env=staging" \
  -e "backup_timestamp=$BACKUP_TIMESTAMP" \
  playbooks/disaster-recovery.yml
```

### DR Process Steps

1. **Validation**: Checks prerequisites and variables
2. **Backup Download**: Downloads database and media backups from cloud storage
3. **Safety Backup**: Creates backup of current state
4. **Database Restore**: Drops and recreates database, restores from backup
5. **Media Restore**: Restores media files
6. **Application Start**: Starts all containers
7. **Health Checks**: Verifies application health
8. **Reporting**: Generates DR report with metrics

### DR Drill Schedule

**Required Frequency**: Quarterly (every 3 months)

**Recommended Schedule**:
- January (Q1)
- April (Q2)
- July (Q3)
- October (Q4)

Set up cron job for automated drills:

```bash
# Run DR drill first Monday of each quarter at 2 AM
0 2 1-7 1,4,7,10 1 /path/to/scripts/dr-drill.sh aws staging database-only
```

### DR Reports

DR reports are saved to `docs/dr-reports/` and include:

- Duration (seconds and minutes)
- Success/failure status
- Target compliance (30-minute goal)
- Component status (database, media, health checks)
- Recommendations

### DR Metrics

**Target**: 30 minutes for full restoration

**Components**:
- Backup download: ~5-10 minutes
- Database restore: ~5-15 minutes (depends on size)
- Media restore: ~5-10 minutes (depends on size)
- Application startup: ~2-5 minutes
- Health verification: ~1-2 minutes

**Optimization Tips**:
- Use faster network connections
- Optimize backup size
- Consider incremental backups
- Keep media files lean

---

## Security Updates

### Quarterly Security Updates

Apply security updates every quarter:

```bash
./scripts/security-update.sh aws production
```

Or use Ansible:

```bash
cd ansible
ansible-playbook -i inventory/aws.yml \
  -e "deploy_env=production" \
  playbooks/security-updates.yml
```

### What Gets Updated

- All system packages
- Security patches
- Kernel updates (requires reboot)
- Docker packages
- System libraries

### Critical Patches

For critical security vulnerabilities, apply immediately:

```bash
# Update specific environment
ansible-playbook -i inventory/aws.yml \
  -e "deploy_env=production" \
  playbooks/security-updates.yml

# Check if reboot is required
ssh user@server 'test -f /var/run/reboot-required && echo "Reboot required" || echo "No reboot needed"'
```

### Update Schedule

**Recommended Schedule**:
- **Quarterly**: Full system updates (kernel, all packages)
- **Monthly**: Security-only updates
- **Immediate**: Critical CVE patches

---

## Logging Management

### Overview

All Docker containers use journald logging driver, ensuring logs persist across container restarts and deployments.

### Viewing Logs

#### View container logs:

```bash
# View last 100 lines for django container
./scripts/view-logs.sh django 100

# Follow logs in real-time
./scripts/view-logs.sh django 100 true

# Using journalctl directly
journalctl -u docker.service -n 100 | grep django

# Follow all Docker logs
journalctl -u docker.service -f
```

#### View logs for specific containers:

```bash
# Django application
journalctl -u docker.service | grep django

# PostgreSQL
journalctl -u docker.service | grep postgres

# Redis
journalctl -u docker.service | grep redis

# Caddy web server
journalctl -u docker.service | grep caddy

# Celery worker
journalctl -u docker.service | grep celeryworker
```

### Log Retention

**Default Policy**:
- journald retains logs based on disk space (default: 10% of disk)
- Older logs are automatically rotated

**Configure retention**:

Edit `/etc/systemd/journald.conf`:

```ini
[Journal]
SystemMaxUse=1G          # Maximum disk space
SystemMaxFileSize=100M   # Maximum file size
MaxRetentionSec=7day     # Keep logs for 7 days
```

Apply changes:

```bash
sudo systemctl restart systemd-journald
```

### Log Analysis

#### Search logs by time:

```bash
# Logs from last hour
journalctl -u docker.service --since "1 hour ago"

# Logs from specific date
journalctl -u docker.service --since "2025-11-07 10:00:00"

# Logs between two times
journalctl -u docker.service --since "2025-11-07 10:00:00" --until "2025-11-07 11:00:00"
```

#### Search logs by pattern:

```bash
# Find errors
journalctl -u docker.service | grep -i error

# Find warnings
journalctl -u docker.service | grep -i warning

# Find specific message
journalctl -u docker.service | grep "database connection"
```

### Export Logs

```bash
# Export to file
journalctl -u docker.service --since "1 day ago" > logs.txt

# Export JSON format
journalctl -u docker.service -o json > logs.json
```

---

## Monitoring

### Node Exporter

Node Exporter collects system metrics (CPU, memory, disk, network).

**Default Port**: 9100

**Check status**:

```bash
sudo systemctl status node_exporter
curl http://localhost:9100/metrics
```

### Promtail (Optional)

Promtail ships logs to Loki (if configured).

**Configuration**: `/etc/promtail/config.yml`

**Check status**:

```bash
sudo systemctl status promtail
```

### Health Checks

Run automated health checks:

```bash
./scripts/health-check.sh
```

Checks:
- Docker service status
- Container health
- Disk space usage
- Memory usage
- System load
- Network ports
- Firewall status

---

## Troubleshooting

### Common Issues

#### 1. Container won't start

```bash
# Check logs
journalctl -u docker.service | grep <container_name>

# Check container status
docker ps -a

# Restart container
docker compose -f compose.prod.yml restart <service_name>
```

#### 2. High disk usage

```bash
# Check disk usage
df -h

# Clean old Docker images
docker image prune -f

# Clean old logs
sudo journalctl --vacuum-time=7d
```

#### 3. Database connection issues

```bash
# Check PostgreSQL logs
journalctl -u docker.service | grep postgres

# Check database container
docker ps | grep postgres

# Test connection
docker compose -f compose.prod.yml exec django python manage.py dbshell
```

#### 4. SSL certificate issues

Caddy handles SSL automatically. If issues occur:

```bash
# Check Caddy logs
journalctl -u docker.service | grep caddy

# Verify domain DNS
dig yourapp.com

# Check Caddy configuration
docker compose -f compose.prod.yml exec caddy caddy validate --config /etc/caddy/Caddyfile
```

### Debug Mode

Enable verbose logging:

```bash
# Edit .env file
DEBUG=1
DJANGO_LOG_LEVEL=DEBUG

# Restart services
docker compose -f compose.prod.yml restart
```

---

## Maintenance Procedures

### Weekly

- [ ] Review application logs for errors
- [ ] Check disk space usage
- [ ] Verify backup completion

### Monthly

- [ ] Apply security updates
- [ ] Review and clean old Docker images
- [ ] Test backup restoration
- [ ] Review firewall logs

### Quarterly

- [ ] Full system updates (kernel, all packages)
- [ ] **Disaster Recovery Drill** (mandatory)
- [ ] Security audit
- [ ] Performance review
- [ ] Documentation updates

### Annually

- [ ] SSL certificate renewal (automatic with Caddy)
- [ ] Infrastructure review
- [ ] Capacity planning
- [ ] Update dependencies

---

## Backup Management

### Cleanup Old Backups

Remove backups older than 30 days:

```bash
cd ansible
ansible-playbook -i inventory/aws.yml \
  -e "retention_days=30" \
  playbooks/cleanup-backups.yml
```

Or use the script:

```bash
./scripts/cleanup-backups.sh aws 30
```

---

## Quick Reference

### Important Paths

- Application: `/home/django/django_app/`
- Logs: `journalctl -u docker.service`
- Docker Compose: `/home/django/django_app/compose.prod.yml`
- Backups: S3/Spaces bucket defined in environment

### Important Commands

```bash
# View running containers
docker ps

# View all containers
docker ps -a

# View logs
journalctl -u docker.service -f

# Restart application
cd /home/django/django_app && docker compose -f compose.prod.yml restart

# Health check
./scripts/health-check.sh

# Provision new server
./scripts/provision-server.sh <cloud> <env> <ip>

# Run DR drill
./scripts/dr-drill.sh <cloud> <env> <type>

# Security updates
./scripts/security-update.sh <cloud> <env>
```

### Support

For issues:
1. Check logs: `journalctl -u docker.service`
2. Run health check: `./scripts/health-check.sh`
3. Review documentation
4. Contact infrastructure team

---

**Last Updated**: November 2025
**Maintained By**: Infrastructure Team
