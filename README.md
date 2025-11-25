# Django React Docker Boilerplate by PLANEKS

📌 Insert here the project description. Also, change the caption of
the README.md file with name of the project.

## ⚡ Simplified Architecture

This boilerplate uses a **clean two-step deployment approach**:

1. **Ansible** = Server Setup (Run Once) - Installs Docker, configures security, sets up Nginx
2. **GitHub Actions** = Application Deployment (Automatic) - Builds, deploys, and monitors your app

```
git push main → GitHub Actions → Auto-deploy with backup & rollback
```

**[📖 Read the Simplified Architecture Guide](docs/simplified-architecture.md)**
**[🚀 Quick Start (15 minutes)](docs/quick-start.md)**

## How to start the project

Follow these steps to start the project via Docker: [Project Creation Guide with Docker](docs/local_setup.md)

Follow these steps to start the project without Docker: [Project Creation Guide no Docker](docs/local_setup_no_docker.md)

## 🏃‍ Running the project in IDEs

Follow these steps to run the project in PyCharm:
[Running in PyCharm Guide](docs/pycharm.md)

Follow these steps to run the project in VSCode:
[Running in VSCode Guide](docs/vscode.md)

## 🖥️ Deploying the project to the server

Follow these steps to deploy the project to the production server:
[Deployment Guide](docs/deployment.md)

## 🏗️ Infrastructure & Server Provisioning

This project includes automated server provisioning and disaster recovery capabilities:

**[Complete Infrastructure Documentation](docs/infrastructure.md)**

### Quick Start - Provision a New Server

```bash
# 1. Generate SSH key for GitHub Actions (if not done)
ssh-keygen -t ed25519 -f ~/.ssh/github_actions_deploy -N ""

# 2. Set environment variables
export GITHUB_ACTIONS_SSH_KEY=$(cat ~/.ssh/github_actions_deploy.pub)
export DOMAIN_NAME=yourapp.com
export DB_PASSWORD=secure_password

# 3. Provision the server
./scripts/provision-server.sh aws production 54.123.45.67

# 4. Test the provisioning (includes AWS security group checks)
./scripts/test-provisioning.sh 54.123.45.67 production aws

# 5. Add secrets to GitHub (PROD_HOST and PROD_SSH_KEY)
# Then deploy via GitHub Actions!
```

**[GitHub Actions Setup Guide](docs/github-actions-setup.md)** - Complete integration instructions

### Key Infrastructure Features

- **Automated Provisioning**: One-command server setup with security hardening
- **Disaster Recovery**: 30-minute restoration target with automated drills
- **Security Updates**: Quarterly updates and critical patches
- **Logging**: Persistent logs with journald across all containers
- **Monitoring**: Node Exporter for metrics collection
- **High Availability**: Failover IP and DNS configuration

### Important Scripts

- `scripts/provision-server.sh` - Provision new servers
- `scripts/dr-drill.sh` - Run disaster recovery drills
- `scripts/security-update.sh` - Apply security updates
- `scripts/health-check.sh` - Check server health
- `scripts/view-logs.sh` - View container logs
- `scripts/test-provisioning.sh` - Validate provisioning

### Ansible Playbooks

- `ansible/playbooks/provision.yml` - Complete server provisioning
- `ansible/playbooks/disaster-recovery.yml` - Restore from backups
- `ansible/playbooks/security-updates.yml` - Apply security patches
- `ansible/playbooks/deploy-django.yml` - Deploy application
- `ansible/playbooks/cleanup-backups.yml` - Remove old backups

See [Infrastructure Documentation](docs/infrastructure.md) for complete details.

## Backup & Disaster Recovery

Follow these steps to backup the project database and media files:
[Backup Guide](docs/backup.md)

**Disaster Recovery**: Automated restoration with 30-minute target
[DR Documentation](docs/infrastructure.md#disaster-recovery)

## Logging

All Docker containers use journald logging for persistent logs across deployments.

**View logs**:
```bash
# View Django logs
./scripts/view-logs.sh django 100

# View PostgreSQL logs
./scripts/view-logs.sh postgres 100

# Follow logs in real-time
./scripts/view-logs.sh django 100 true
```

See [Logging Documentation](docs/infrastructure.md#logging-management) for more details.

📌 If this document does not contain some important information, feel free to make a pull request.

Additional project info located in the [docs/index.md](docs/index.md) file.
