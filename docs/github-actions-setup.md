# GitHub Actions Setup for Provisioned Servers

This guide explains how to set up GitHub Actions to deploy to servers that have been provisioned using the infrastructure automation scripts.

## Overview

After provisioning a server, GitHub Actions needs:
1. SSH access to the server
2. The server's IP address
3. Proper directory structure and permissions

The provisioning process can automatically configure all of this.

## Prerequisites

Before provisioning your server, you need to generate an SSH key pair for GitHub Actions.

### Generate SSH Key for GitHub Actions

```bash
# Generate a new SSH key pair (no passphrase)
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_actions_deploy -N ""

# This creates:
# - ~/.ssh/github_actions_deploy (private key - for GitHub Secrets)
# - ~/.ssh/github_actions_deploy.pub (public key - for server)
```

## Provisioning with GitHub Actions Support

### Option 1: Provide SSH Key During Provisioning

Set the environment variable before provisioning:

```bash
# Export the public key
export GITHUB_ACTIONS_SSH_KEY=$(cat ~/.ssh/github_actions_deploy.pub)

# Provision the server
./scripts/provision-server.sh aws production 54.123.45.67

# The provisioning will:
# ✓ Add the SSH key to the app user (django)
# ✓ Add the SSH key to the ansible user (ubuntu)
# ✓ Create .env template
# ✓ Set up proper permissions
```

### Option 2: Provide SSH Key via Ansible Variable

```bash
cd ansible

ansible-playbook -i "54.123.45.67," \
  -e "deploy_env=production" \
  -e "cloud_provider=aws" \
  -e "github_actions_ssh_key=$(cat ~/.ssh/github_actions_deploy.pub)" \
  playbooks/provision.yml
```

### Option 3: Add SSH Key After Provisioning

If you forgot to add it during provisioning:

```bash
# SSH to the server
ssh ubuntu@54.123.45.67

# Add the key manually
echo "your-public-key-here" >> /home/django/.ssh/authorized_keys
echo "your-public-key-here" >> /home/ubuntu/.ssh/authorized_keys
```

## Configure GitHub Secrets

After provisioning, add these secrets to your GitHub repository:

### For Production Server

Go to: **Repository → Settings → Secrets and variables → Actions → New repository secret**

Add the following secrets:

```
PROD_HOST
Value: 54.123.45.67 (your server IP)

PROD_SSH_KEY
Value: (paste entire private key from ~/.ssh/github_actions_deploy)
```

**Private Key Format:**
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
...
(entire key content)
...
-----END OPENSSH PRIVATE KEY-----
```

### For Staging Server

```
STAGING_HOST
Value: 54.123.45.68

STAGING_SSH_KEY
Value: (same private key or different one)
```

### For Development Server

```
DEV_HOST
Value: 54.123.45.69

DEV_SSH_KEY
Value: (same private key or different one)
```

## Verify GitHub Actions Setup

After provisioning, test the SSH connection:

```bash
# Test SSH connection using the private key
ssh -i ~/.ssh/github_actions_deploy ubuntu@54.123.45.67 "echo 'Connection successful'"

# Should output: Connection successful
```

## GitHub Actions Workflow Example

The repository already includes workflows in `.github/workflows/`. After provisioning and adding secrets, deployments will work automatically.

### Manual Deployment Trigger

```bash
# From GitHub UI:
# Go to Actions → Deploy to Production → Run workflow

# Or push to main branch (if configured for auto-deploy)
git push origin main
```

## Environment File (.env)

After provisioning, a template `.env.template` file is created on the server. You need to populate it with actual values.

### Update .env on Server

```bash
# SSH to the server
ssh ubuntu@54.123.45.67

# Switch to app directory
cd /home/django/django_app

# Edit .env file
nano .env
```

Update these critical values:
```bash
SECRET_KEY=your-actual-secret-key-here
POSTGRES_PASSWORD=your-secure-db-password
ALLOWED_HOSTS=yourdomain.com
SITE_DOMAIN=yourdomain.com
SITE_URL=https://yourdomain.com
```

### Or Update via Ansible

You can also manage .env through Ansible by creating a template in your repository.

## Verify Server is Ready for Deployment

Run the test script to verify everything is configured:

```bash
./scripts/test-provisioning.sh 54.123.45.67 production aws
```

Check that these tests pass:
- ✓ GitHub Actions SSH key configured
- ✓ .env template exists
- ✓ .env file exists
- ✓ App directory writable
- ✓ Ports 22, 80, 443 open (AWS security groups)

## AWS Security Groups

The provisioning automatically configures AWS Security Groups to allow:
- Port 22 (SSH) - for GitHub Actions deployments
- Port 80 (HTTP) - for web traffic (Caddy redirects to HTTPS)
- Port 443 (HTTPS) - for secure web traffic

### Manual Security Group Configuration

If automatic configuration fails, manually configure via AWS Console:

1. Go to **EC2 → Security Groups**
2. Find your instance's security group
3. Add inbound rules:
   - Type: SSH, Port: 22, Source: 0.0.0.0/0
   - Type: HTTP, Port: 80, Source: 0.0.0.0/0
   - Type: HTTPS, Port: 443, Source: 0.0.0.0/0

## Troubleshooting

### GitHub Actions Can't SSH to Server

**Problem:** GitHub Actions deployment fails with "Permission denied (publickey)"

**Solutions:**

1. Verify SSH key is in authorized_keys:
```bash
ssh ubuntu@54.123.45.67 "cat /home/django/.ssh/authorized_keys"
ssh ubuntu@54.123.45.67 "cat /home/ubuntu/.ssh/authorized_keys"
```

2. Verify GitHub Secret has correct private key:
   - Check the secret includes `-----BEGIN OPENSSH PRIVATE KEY-----`
   - Check there are no extra spaces or newlines

3. Test SSH manually:
```bash
ssh -i ~/.ssh/github_actions_deploy ubuntu@54.123.45.67
```

### Port 80/443 Not Accessible

**Problem:** Website not loading

**Solutions:**

1. Check local firewall (UFW):
```bash
ssh ubuntu@54.123.45.67 "sudo ufw status"
```

2. Check AWS Security Group:
```bash
# Get instance ID
INSTANCE_ID=$(ssh ubuntu@54.123.45.67 "curl -s http://169.254.169.254/latest/meta-data/instance-id")

# Check security group
aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].SecurityGroups'

# Get security group rules
SG_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)

aws ec2 describe-security-groups --group-ids $SG_ID
```

3. Re-run AWS security configuration:
```bash
cd ansible
ansible-playbook -i "54.123.45.67," \
  -e "deploy_env=production" \
  -e "cloud_provider=aws" \
  playbooks/provision.yml \
  --tags aws,security
```

### .env File Missing

**Problem:** Application fails to start due to missing environment variables

**Solution:**

1. Check if .env exists:
```bash
ssh ubuntu@54.123.45.67 "ls -la /home/django/django_app/.env"
```

2. Copy from template:
```bash
ssh ubuntu@54.123.45.67 "cp /home/django/django_app/.env.template /home/django/django_app/.env"
```

3. Populate with actual values (see above)

## Integration with Existing Workflows

This boilerplate already has GitHub Actions workflows in `.github/workflows/`:

- `ci.yml` - Runs tests on every push
- `dev_deploy.yml` - Deploys to development server
- `staging_deploy.yml` - Deploys to staging server
- `production_deploy.yml` - Deploys to production server

After provisioning and configuring secrets, these workflows will work automatically.

## Security Best Practices

1. **Use separate SSH keys** for each environment (dev/staging/prod)
2. **Rotate keys regularly** (at least annually)
3. **Never commit** private keys to repository
4. **Use GitHub Environments** with required reviewers for production
5. **Monitor deployments** via GitHub Actions logs
6. **Restrict security groups** to specific IPs if possible (instead of 0.0.0.0/0)

## Complete Setup Checklist

- [ ] Generate SSH key pair for GitHub Actions
- [ ] Export GITHUB_ACTIONS_SSH_KEY environment variable
- [ ] Provision server with `./scripts/provision-server.sh`
- [ ] Verify provisioning with `./scripts/test-provisioning.sh`
- [ ] Add PROD_HOST (or DEV_HOST/STAGING_HOST) to GitHub Secrets
- [ ] Add PROD_SSH_KEY (or DEV_SSH_KEY/STAGING_SSH_KEY) to GitHub Secrets
- [ ] SSH to server and configure .env file
- [ ] Test deployment via GitHub Actions
- [ ] Verify website is accessible
- [ ] Set up monitoring and alerts

---

**Related Documentation:**
- [Infrastructure Documentation](infrastructure.md)
- [Deployment Guide](deployment.md)
- [Disaster Recovery](infrastructure.md#disaster-recovery)
