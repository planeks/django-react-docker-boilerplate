# Simplified Architecture Guide

This project uses a **clean separation** between infrastructure and application deployment.

## 🎯 Philosophy

**Ansible = Infrastructure Setup (Run Once)**
**GitHub Actions = Application Deployment (Run Often)**

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Development Flow                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  git push main  │
                    └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ GitHub Actions  │
                    │   (CI/CD)       │
                    └─────────────────┘
                              │
                ┌─────────────┼─────────────┐
                ▼             ▼             ▼
           ┌────────┐   ┌─────────┐   ┌────────┐
           │  Test  │   │  Build  │   │ Deploy │
           └────────┘   └─────────┘   └────────┘
                                            │
                                            ▼
                                   ┌────────────────┐
                                   │  Your Server   │
                                   │ (provisioned   │
                                   │  by Ansible)   │
                                   └────────────────┘
```

## What Ansible Does (One-Time Setup)

Ansible sets up the server infrastructure. You run this **once** when:
- Setting up a new server
- Adding a new environment
- Major infrastructure changes needed

### Ansible Handles:

✅ **Security**
- Firewall configuration (UFW)
- Fail2ban
- SSH hardening
- Security updates

✅ **Docker Installation**
- Docker Engine
- Docker Compose
- Docker user permissions

✅ **Web Server**
- Nginx installation
- SSL/TLS certificates (Let's Encrypt)
- Reverse proxy configuration

✅ **User Setup**
- Application user creation
- Directory structure
- Permissions

✅ **GitHub Actions Integration**
- SSH key generation
- SSH key deployment
- Repository access

✅ **Monitoring** (Optional)
- Prometheus
- Grafana
- Node exporter

### Running Ansible (Server Setup)

```bash
# One-time server setup
cd ansible
ansible-playbook -i inventory/production.yml playbooks/server-setup.yml
```

## What GitHub Actions Does (Every Deployment)

GitHub Actions handles **all application deployments**. This runs **automatically** on:
- Push to main (production)
- Push to staging
- Push to development
- Manual workflow trigger

### GitHub Actions Handles:

✅ **Pre-Deployment**
- Run tests
- Backup database
- Tag current Docker images
- Save current git commit

✅ **Deployment**
- Pull latest code
- Build Docker images
- Start containers
- Run migrations
- Collect static files

✅ **Health Checks**
- Container status check
- Django health check
- Database connectivity
- HTTP endpoint check

✅ **Rollback** (On Failure)
- Restore previous git commit
- Restart previous Docker images
- Database restore available

✅ **Cleanup**
- Remove old Docker images
- Clean up old backups
- Prune unused volumes

### GitHub Actions Workflow

```yaml
# Automatically triggered on git push
1. CI Tests
   └─ Run pytest
   └─ Linting
   └─ Type checks

2. Build
   └─ Build Docker images

3. Deploy
   └─ Backup current state
   └─ Pull latest code
   └─ Deploy containers
   └─ Run migrations
   └─ Health checks

4. Rollback (if needed)
   └─ Restore previous state
   └─ Notify team
```

## Key Benefits

### 1. **Simplicity**
- Ansible is lightweight (just server setup)
- All deployment logic in one place (GitHub Actions)
- Easy to understand and debug

### 2. **Visibility**
- See deployment logs in GitHub UI
- Track deployment history
- Review what changed in each deploy

### 3. **Safety**
- Automatic backups before deploy
- Automatic rollback on failure
- Health checks prevent bad deploys

### 4. **Speed**
- Fast iterations (no Ansible re-runs)
- Parallel builds
- Cached Docker layers

### 5. **Standard Workflow**
- Familiar to most developers
- Git-based (GitOps)
- Industry best practices

## Getting Started

### Step 1: Provision Server (One Time)

```bash
# 1. Create your server (DigitalOcean, AWS, etc.)

# 2. Add server to inventory
nano ansible/inventory/production.yml

# 3. Run server setup
cd ansible
ansible-playbook -i inventory/production.yml playbooks/server-setup.yml

# 4. Note the GitHub secrets displayed
#    Add these to: GitHub → Settings → Secrets and variables → Actions
```

### Step 2: Initial Code Deployment

```bash
# SSH into server
ssh appuser@YOUR_SERVER_IP

# Clone repository
cd ~/projects
git clone YOUR_REPO_URL django-react-docker-boilerplate
cd django-react-docker-boilerplate

# Create .env file
cp .env.example .env
nano .env
# Fill in your secrets

# First deployment (manual)
docker compose -f compose.prod.yml build
docker compose -f compose.prod.yml up -d
docker compose -f compose.prod.yml exec django poetry run python manage.py migrate
docker compose -f compose.prod.yml exec django poetry run python manage.py createsuperuser
```

### Step 3: Future Deployments (Automatic)

```bash
# Just push to main!
git push origin main

# GitHub Actions will:
# 1. Run tests
# 2. Build images
# 3. Backup database
# 4. Deploy to server
# 5. Run migrations
# 6. Health checks
# 7. Rollback if anything fails
```

## Deployment Script

The deployment is handled by `scripts/deploy.sh` which includes:

```bash
#!/bin/bash
# Automated deployment with safety features

1. Pre-deployment checks
   ├─ Docker running?
   ├─ Compose file exists?
   └─ Git repository clean?

2. Backup
   ├─ Save current commit
   ├─ Backup database
   └─ Tag Docker images

3. Deploy
   ├─ Pull latest code
   ├─ Build Docker images
   ├─ Start containers
   └─ Run migrations

4. Health checks
   ├─ Containers running?
   ├─ Django responding?
   └─ Database connected?

5. Rollback (if needed)
   ├─ Restore git commit
   ├─ Restart old images
   └─ Notify team
```

## Manual Operations

### Manual Deployment

```bash
ssh appuser@YOUR_SERVER
cd ~/projects/django-react-docker-boilerplate
./scripts/deploy.sh compose.prod.yml main $(pwd)
```

### Rollback to Previous Version

```bash
# Check backup directory
ls -lt backups/

# Rollback git
git checkout $(cat backups/last_known_good_commit)

# Restart containers
docker compose -f compose.prod.yml up -d --force-recreate

# Restore database (if needed)
docker compose -f compose.prod.yml exec -T postgres pg_restore \
  -U postgres -d postgres < backups/db_backup_TIMESTAMP.dump
```

### View Logs

```bash
# All services
docker compose -f compose.prod.yml logs -f

# Specific service
docker compose -f compose.prod.yml logs -f django

# Last 100 lines
docker compose -f compose.prod.yml logs --tail=100 django
```

### Database Operations

```bash
# Backup database
docker compose -f compose.prod.yml exec postgres \
  pg_dump -U postgres -Fc postgres > backup.dump

# Restore database
docker compose -f compose.prod.yml exec -T postgres \
  pg_restore -U postgres -d postgres < backup.dump

# Access PostgreSQL shell
docker compose -f compose.prod.yml exec postgres psql -U postgres
```

## Troubleshooting

### Deployment Failed

```bash
# 1. Check GitHub Actions logs
#    GitHub → Actions → Failed workflow → View logs

# 2. SSH into server and check logs
ssh appuser@YOUR_SERVER
cd ~/projects/django-react-docker-boilerplate
docker compose -f compose.prod.yml logs --tail=100

# 3. Check container status
docker compose -f compose.prod.yml ps

# 4. Rollback if needed
./scripts/deploy.sh  # Will auto-rollback on failure
```

### Ansible Provisioning Failed

```bash
# 1. Check Ansible verbose output
ansible-playbook -vvv -i inventory/production.yml playbooks/server-setup.yml

# 2. Run specific role
ansible-playbook -i inventory/production.yml playbooks/server-setup.yml --tags docker

# 3. Check server directly
ssh root@YOUR_SERVER
systemctl status docker
systemctl status nginx
```

### GitHub Actions Can't Connect

```bash
# 1. Verify secrets are set correctly
#    GitHub → Settings → Secrets → Actions

# 2. Test SSH connection locally
ssh -i ~/.ssh/github_actions appuser@YOUR_SERVER

# 3. Check authorized_keys on server
ssh root@YOUR_SERVER
cat /home/appuser/.ssh/authorized_keys
```

## Directory Structure

```
project/
├── ansible/                  # Infrastructure as Code
│   ├── playbooks/
│   │   ├── server-setup.yml  # ← Server provisioning (run once)
│   │   ├── security-updates.yml
│   │   └── cleanup-backups.yml
│   └── roles/
│       ├── common/           # Basic server setup
│       ├── docker/           # Docker installation
│       ├── nginx/            # Web server
│       ├── ssl/              # SSL certificates
│       └── github_actions/   # CI/CD setup
│
├── .github/workflows/        # Application deployment
│   ├── production_deploy.yml # ← Auto-deploy to prod
│   ├── staging_deploy.yml
│   ├── deploy-reusable.yml   # ← Core deployment logic
│   └── ci.yml
│
├── scripts/
│   └── deploy.sh             # ← Deployment script (backup + rollback)
│
├── docker/                   # Docker configurations
├── backend/                  # Django app
├── frontend/                 # React app
└── docs/                     # Documentation
```

## Comparison: Old vs New

### Old Way (Complex)

```
Developer pushes code
     ↓
GitHub Actions starts
     ↓
Calls Ansible playbook
     ↓
Ansible connects to server
     ↓
Ansible runs ALL deployment logic
     ↓
Hard to debug
```

### New Way (Simple)

```
Developer pushes code
     ↓
GitHub Actions starts
     ↓
SSH into server
     ↓
Run deploy.sh script
     ↓
Auto-backup + Deploy + Health check
     ↓
Auto-rollback if fails
     ↓
Easy to debug
```

## Best Practices

1. **Always test in staging first**
   ```bash
   git push origin staging  # Test here first
   git push origin main     # Deploy to production
   ```

2. **Keep .env secrets secure**
   - Never commit .env
   - Use GitHub Secrets for CI/CD
   - Rotate secrets regularly

3. **Monitor deployments**
   - Watch GitHub Actions logs
   - Set up Slack/Discord notifications
   - Monitor server resources

4. **Regular backups**
   - Automated before each deploy
   - Manual backups before major changes
   - Test restore procedure regularly

5. **Keep infrastructure code in version control**
   - All Ansible configs in git
   - All GitHub Actions workflows in git
   - Document infrastructure changes

## Next Steps

- ✅ **[Quick Start Guide](quick-start.md)** - Get started in 5 minutes
- ✅ **[SSH Key Setup](ssh-key-setup.md)** - Configure deployment keys
- ✅ **[Deployment Guide](deployment.md)** - Detailed deployment docs
- ✅ **[Monitoring Setup](monitoring.md)** - Set up monitoring

## Support

Having issues? Check:
1. [Troubleshooting Guide](troubleshooting.md)
2. [GitHub Issues](https://github.com/YOUR_REPO/issues)
3. [Discussions](https://github.com/YOUR_REPO/discussions)
