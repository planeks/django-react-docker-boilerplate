# Quick Start Guide

Get your Django + React application deployed in 15 minutes.

## 🚀 Overview

This boilerplate uses a **simple two-step approach**:
1. **Ansible** sets up your server (run once)
2. **GitHub Actions** deploys your code (automatic)

## Prerequisites

- A fresh Ubuntu server (DigitalOcean, AWS, Hetzner, etc.)
- GitHub repository (fork this repo)
- 15 minutes ⏱️

## Step 1: Configure Your Server (5 minutes)

### 1.1 Get a Server

Create a new server with:
- **OS**: Ubuntu 22.04 LTS
- **RAM**: Minimum 2GB (4GB recommended)
- **Storage**: Minimum 20GB
- **Provider**: DigitalOcean, AWS, Hetzner, Linode, etc.

### 1.2 Add Server to Inventory

```bash
# Clone this repository
git clone YOUR_REPO_URL
cd django-react-docker-boilerplate

# Copy and edit the inventory
cd ansible
cp inventory/production.yml.example inventory/production.yml
nano inventory/production.yml
```

Update with your server IP:

```yaml
all:
  hosts:
    production:
      ansible_host: YOUR_SERVER_IP  # ← Change this
      ansible_user: root            # or ubuntu
      ansible_python_interpreter: /usr/bin/python3
```

### 1.3 Configure Variables

```bash
# Copy environment file
cp .env.ansible.example .env.ansible
nano .env.ansible
```

Set your configuration:

```bash
# Required
APP_USER=appuser
PROJECT_NAME=django_app
DOMAIN=your-domain.com

# Optional (defaults are fine for testing)
DEPLOY_ENV=production
GIT_REPO_URL=https://github.com/YOUR_USERNAME/YOUR_REPO
GIT_BRANCH=main
```

## Step 2: Provision Server (5 minutes)

Run the Ansible playbook to set up your server:

```bash
# From the ansible directory
ansible-playbook -i inventory/production.yml playbooks/server-setup.yml
```

This will:
- ✅ Install Docker & Docker Compose
- ✅ Configure firewall and security
- ✅ Set up Nginx with SSL
- ✅ Create application user and directories
- ✅ **Generate SSH keys for GitHub Actions**
- ✅ Display setup instructions

**Important**: The playbook will pause and show you:
1. The private SSH key to add to GitHub
2. The exact URL to add it
3. Required GitHub Secrets

## Step 3: Configure GitHub (3 minutes)

### 3.1 Add GitHub Secrets

The Ansible output will show something like:

```
========================================
✓ GitHub Actions SSH Key Created!
========================================

STEP 1: Add to GitHub Secrets
─────────────────────────────────────────
Go to: https://github.com/YOUR_REPO/settings/secrets/actions

Name:  PROD_HOST
Value: 123.45.67.89

Name:  PROD_SSH_KEY
Value: (copy the PRIVATE KEY below)

┌─────────────────────────────────────────┐
│ PRIVATE KEY - Add to GitHub Secrets    │
└─────────────────────────────────────────┘
-----BEGIN OPENSSH PRIVATE KEY-----
...key content here...
-----END OPENSSH PRIVATE KEY-----
```

1. Click the GitHub URL shown
2. Click "New repository secret"
3. Add `PROD_HOST` with your server IP
4. Add `PROD_SSH_KEY` with the entire private key (including BEGIN/END lines)

### 3.2 Add Deploy Key

The Ansible output also shows a **deploy key**:

```
========================================
SSH Deploy Key Generated
========================================

Public Key:
ssh-rsa AAAAB3NzaC1yc2EAAAA...

Next Steps:
1. Copy the public key above
2. Add it to your Git repository:
   - GitHub: Settings → Deploy keys → Add deploy key
```

1. Go to your repo: `https://github.com/YOUR_REPO/settings/keys`
2. Click "Add deploy key"
3. Paste the public key
4. Enable **read-only** access
5. Click "Add key"

## Step 4: Initial Deployment (2 minutes)

### 4.1 SSH into Server

```bash
ssh appuser@YOUR_SERVER_IP
```

### 4.2 Clone Repository

```bash
cd ~/projects/django_app
git clone YOUR_REPO_URL .
```

### 4.3 Create .env File

```bash
cp .env.example .env
nano .env
```

Set your secrets:

```bash
# Django
SECRET_KEY=your-super-secret-key-change-this
DEBUG=False
ALLOWED_HOSTS=your-domain.com,www.your-domain.com

# Database
POSTGRES_DB=django_db
POSTGRES_USER=django_user
POSTGRES_PASSWORD=strong-password-here

# Redis
REDIS_PASSWORD=another-strong-password
```

### 4.4 First Deploy

```bash
# Build and start containers
docker compose -f compose.prod.yml build
docker compose -f compose.prod.yml up -d

# Run migrations
docker compose -f compose.prod.yml exec django poetry run python manage.py migrate

# Create superuser
docker compose -f compose.prod.yml exec django poetry run python manage.py createsuperuser

# Collect static files
docker compose -f compose.prod.yml exec django poetry run python manage.py collectstatic --noinput
```

### 4.5 Verify

Visit your site:
- **Frontend**: https://your-domain.com
- **API**: https://your-domain.com/api/
- **Admin**: https://your-domain.com/admin/

## Step 5: Enable Auto-Deployment ✨

**You're done!** Future deployments are automatic:

```bash
# Just push to main
git add .
git commit -m "My awesome changes"
git push origin main

# GitHub Actions will automatically:
# 1. Run tests
# 2. Build Docker images
# 3. Backup database
# 4. Deploy to server
# 5. Run migrations
# 6. Collect static files
# 7. Health checks
# 8. Rollback if anything fails
```

Watch the deployment:
- Go to: `https://github.com/YOUR_REPO/actions`
- See live logs of your deployment

## What Just Happened?

### Server Setup (Ansible - One Time)

```
Ansible connected to your server and:
├── Installed Docker
├── Configured firewall (UFW)
├── Set up fail2ban (security)
├── Installed and configured Nginx
├── Set up SSL with Let's Encrypt
├── Created application user (appuser)
├── Created project directories
├── Generated SSH keys for CI/CD
└── Added public key for deployments
```

### Auto-Deployment (GitHub Actions - Every Push)

```
On every git push to main:
├── Run tests (pytest)
├── Backup database
├── Pull latest code
├── Build Docker images
├── Start containers
├── Run migrations
├── Collect static files
├── Health checks
└── Rollback if anything fails
```

## Common Tasks

### View Logs

```bash
# All services
docker compose -f compose.prod.yml logs -f

# Just Django
docker compose -f compose.prod.yml logs -f django

# Last 100 lines
docker compose -f compose.prod.yml logs --tail=100
```

### Run Django Commands

```bash
# Run migrations
docker compose -f compose.prod.yml exec django poetry run python manage.py migrate

# Create superuser
docker compose -f compose.prod.yml exec django poetry run python manage.py createsuperuser

# Django shell
docker compose -f compose.prod.yml exec django poetry run python manage.py shell

# Custom management command
docker compose -f compose.prod.yml exec django poetry run python manage.py YOUR_COMMAND
```

### Database Backup

```bash
# Backup
docker compose -f compose.prod.yml exec postgres \
  pg_dump -U postgres -Fc postgres > backup.dump

# Restore
docker compose -f compose.prod.yml exec -T postgres \
  pg_restore -U postgres -d postgres < backup.dump
```

### Restart Services

```bash
# Restart all
docker compose -f compose.prod.yml restart

# Restart specific service
docker compose -f compose.prod.yml restart django

# Rebuild and restart
docker compose -f compose.prod.yml up -d --build
```

## Troubleshooting

### Deployment Failed

1. Check GitHub Actions logs:
   - Go to: `https://github.com/YOUR_REPO/actions`
   - Click on the failed workflow
   - View the logs

2. Check server logs:
   ```bash
   ssh appuser@YOUR_SERVER_IP
   cd ~/projects/django_app
   docker compose -f compose.prod.yml logs --tail=100
   ```

3. Check container status:
   ```bash
   docker compose -f compose.prod.yml ps
   ```

### Can't Access Website

1. Check Nginx status:
   ```bash
   ssh appuser@YOUR_SERVER_IP
   sudo systemctl status nginx
   ```

2. Check containers:
   ```bash
   docker compose -f compose.prod.yml ps
   ```

3. Check firewall:
   ```bash
   sudo ufw status
   # Should show: 22, 80, 443 open
   ```

### GitHub Actions Can't Connect

1. Verify GitHub Secrets:
   - Go to: `https://github.com/YOUR_REPO/settings/secrets/actions`
   - Verify `PROD_HOST` and `PROD_SSH_KEY` exist

2. Test SSH connection:
   ```bash
   ssh -i ~/.ssh/github_actions appuser@YOUR_SERVER_IP
   ```

3. Check authorized_keys:
   ```bash
   ssh appuser@YOUR_SERVER_IP
   cat ~/.ssh/authorized_keys
   ```

## Next Steps

Now that you're up and running:

1. **Customize your application**
   - Edit Django models
   - Add React components
   - Create API endpoints

2. **Set up staging environment**
   - Create staging server
   - Add `STAGING_HOST` and `STAGING_SSH_KEY` secrets
   - Push to `staging` branch

3. **Enable monitoring**
   ```bash
   ansible-playbook -i inventory/production.yml playbooks/server-setup.yml --tags monitoring
   ```

4. **Read the detailed docs**
   - [Simplified Architecture](simplified-architecture.md)
   - [SSH Key Setup](ssh-key-setup.md)
   - [Deployment Guide](deployment.md)

## Architecture Summary

```
┌──────────────┐
│     You      │
│  (Developer) │
└──────┬───────┘
       │
       │ git push main
       ▼
┌──────────────────┐
│  GitHub Actions  │
│    (CI/CD)       │
│                  │
│  ✓ Tests         │
│  ✓ Build         │
│  ✓ Backup        │
│  ✓ Deploy        │
│  ✓ Migrate       │
│  ✓ Health Check  │
└────────┬─────────┘
         │
         │ SSH (secure)
         ▼
┌──────────────────┐
│   Your Server    │
│  (Provisioned    │
│   by Ansible)    │
│                  │
│  Docker          │
│  ├─ Django       │
│  ├─ React        │
│  ├─ PostgreSQL   │
│  ├─ Redis        │
│  └─ Nginx        │
└──────────────────┘
```

## Support

Need help?
- 📖 Read the [full documentation](simplified-architecture.md)
- 🐛 [Open an issue](https://github.com/YOUR_REPO/issues)
- 💬 [Start a discussion](https://github.com/YOUR_REPO/discussions)

**Enjoy your new deployment pipeline! 🎉**
