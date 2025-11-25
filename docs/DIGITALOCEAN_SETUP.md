# DigitalOcean Setup Guide

This guide explains how to configure DigitalOcean API access for dynamic inventory in Ansible.

## Prerequisites

- A DigitalOcean account
- DigitalOcean droplets with appropriate tags (see Tagging section)
- Community DigitalOcean Ansible collection installed

## Step 1: Install Ansible Collection

If you haven't already, install the DigitalOcean collection:

```bash
ansible-galaxy collection install community.digitalocean
```

## Step 2: Generate API Token

1. Log in to [DigitalOcean](https://cloud.digitalocean.com/)
2. Navigate to **API** in the left sidebar (or go to https://cloud.digitalocean.com/account/api/tokens)
3. Click **Generate New Token**
4. Name: `ansible-dynamic-inventory` (or any descriptive name)
5. Scopes: Select **Read** (write access not required for inventory)
6. Expiration: Choose based on your security policy (recommended: 90 days)
7. Click **Generate Token**
8. **IMPORTANT**: Copy the token immediately - it won't be shown again!

## Step 3: Configure Environment Variable

Add the API token to your `ansible/.env.ansible` file:

```bash
# Navigate to the ansible directory
cd ansible

# If .env.ansible doesn't exist, copy from example
cp .env.ansible.example .env.ansible

# Edit the file and add your token
nano .env.ansible  # or use your preferred editor
```

Add this line to `.env.ansible`:

```bash
# DigitalOcean API Token
DO_API_TOKEN=dop_v1_your_actual_token_here
```

**Security Note**: The `.env.ansible` file is gitignored to prevent accidentally committing secrets.

## Step 4: Tag Your Droplets

The dynamic inventory uses tags to organize hosts. Tag your droplets appropriately:

### Required Tags

- **Environment**: `production`, `staging`, `development`
- **Role**: `web`, `database`, `cache`, etc.

### How to Tag Droplets

1. In DigitalOcean console, go to your droplet
2. Click on **Tags** section
3. Add tags like: `production`, `web`, `django`

### Example Tagging Scheme

```
Production Web Server:
  Tags: production, web, django

Staging Database:
  Tags: staging, database, postgres
```

## Step 5: Test the Configuration

Verify the inventory works:

```bash
# Test inventory parsing
ansible-inventory -i inventory/digitalocean.yml --list

# Test connectivity to all hosts
ansible all -i inventory/digitalocean.yml -m ping
```

## Using the Inventory

Once configured, you can use the DigitalOcean inventory with any script:

```bash
# Run security updates
./scripts/security-update.sh digitalocean production true

# Quick deployment
./scripts/quick-update.sh production digitalocean

# Backup cleanup
./scripts/cleanup-backups.sh digitalocean 30
```

## Troubleshooting

### Error: HTTP 401 Unauthorized

This means the API token is invalid or not loaded:

1. Verify token is correct in `ansible/.env.ansible`
2. Check token hasn't expired in DigitalOcean console
3. Ensure script properly sources `.env.ansible` (recent scripts do this automatically)
4. Manually test: `export DO_API_TOKEN=your_token && ansible-inventory -i inventory/digitalocean.yml --list`

### Error: No inventory was parsed

Possible causes:

1. **Collection not installed**: Run `ansible-galaxy collection install community.digitalocean`
2. **Token not loaded**: Make sure `.env.ansible` exists and contains `DO_API_TOKEN`
3. **Invalid YAML**: Check `inventory/digitalocean.yml` syntax

### Empty Inventory (No Hosts Found)

1. Verify droplets exist in your DigitalOcean account
2. Check droplets are in the correct region
3. Ensure droplets are powered on
4. Verify API token has read permissions

## Dynamic Inventory Features

The inventory automatically organizes hosts by:

- **Tags**: Access via `tag_production`, `tag_web`, etc.
- **Region**: Access via `region_nyc1`, `region_sfo2`, etc.
- **Individual hosts**: Access by name or ID

### Example Playbook Usage

```yaml
---
- name: Update production web servers
  hosts: tag_production:&tag_web  # Intersection of tags
  tasks:
    - name: Ensure app is up to date
      ansible.builtin.git:
        repo: "{{ git_repo_url }}"
        dest: /home/{{ app_user }}/projects/{{ project_name }}
        version: main
```

## Security Best Practices

1. **Use read-only tokens** - Inventory only needs read access
2. **Rotate tokens regularly** - Set expiration dates
3. **Never commit tokens** - Always use `.env.ansible` (gitignored)
4. **Limit token scope** - Only grant necessary permissions
5. **Use separate tokens** - Different tokens for different purposes (inventory vs provisioning)

## Related Documentation

- [DigitalOcean API Documentation](https://docs.digitalocean.com/reference/api/)
- [Community DigitalOcean Collection](https://docs.ansible.com/ansible/latest/collections/community/digitalocean/index.html)
- [Ansible Dynamic Inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html)
