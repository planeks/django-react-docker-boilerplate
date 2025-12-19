# Server Provisioning Script

Automates complete server setup using Ansible.

## Manual Steps Before Provisioning

1. **Prepare fresh server**
   - Create Ubuntu/Debian server on your cloud provider
   - Note the server IP address
   - Ensure server is accessible via SSH

2. **Configure local environment**
   - Install Ansible: `pip install ansible`
   - Create `ansible/.env.ansible` from template:
     ```bash
     cp ansible/.env.ansible.example ansible/.env.ansible
     ```
   - Edit `.env.ansible` and set missing variables:
     - `DOMAIN_NAME` - Your domain (e.g., `example.com`)
     - `SSL_EMAIL` - Email for SSL certificates
     - `PROJECT_NAME` - Project name

3. **Set up SSH access to server from local environment**
   - Generate SSH key: `ssh-keygen -t rsa`
   - Copy public key to server: `ssh-copy-id user@server_ip`
   - Test connection: `ssh user@server_ip`

4. **Set up repository access**
   - Can be done before or after provisioning
   - If done before: Script will clone and deploy automatically
   - If done after: You'll need to deploy manually
   - Steps: SSH to server → `ssh-keygen -t ed25519` → Add public key to GitHub Deploy keys
## What the Script Does
The script runs automatically from start to finish without pausing:
1. Loads configuration from `ansible/.env.ansible`
2. Generates/configures GitHub Actions SSH key
   - **Note**: Script will display key location (e.g., `~/.ssh/github_actions`)
   - You'll need to add this to GitHub Secrets after provisioning
3. Auto-detects Git repository and branch
4. Runs Ansible playbook that:
   - Updates system packages
   - Installs Docker and Docker Compose
   - Configures firewall and security
   - Sets up monitoring
   - Creates application directories
   - Authorizes GitHub Actions SSH key
   - **Clones repository** and runs initial deployment

## Usage

```bash
./scripts/provision-server.sh <cloud_provider> <environment> <server_ip> [ssh_user] [ssh_key_path]
```

### Examples

**AWS Production:**
```bash
./scripts/provision-server.sh aws production 192.168.0.1
```

**DigitalOcean Development:**
```bash
./scripts/provision-server.sh digitalocean dev 45.55.123.45 root
```

**With custom SSH key:**
```bash
./scripts/provision-server.sh aws production 192.168.0.1 ubuntu ~/.ssh/my-key.pem
```

## Requirements

- `ansible/.env.ansible` configured (see `.env.ansible.example`)
- SSH access to target server
- Ansible installed locally

## After Provisioning

1. **Add GitHub SSH key to repository secrets** (required for deployments)
   - Go to: Repository Settings → Secrets and variables → Actions
   - Create new secret: `PROD_SSH_KEY` (or `DEV_SSH_KEY`, `STAGING_SSH_KEY`)
   - Paste private key content: `cat ~/.ssh/github_actions`
2. **Reboot server if prompted** by script output
3. **Test deployment** via GitHub Actions