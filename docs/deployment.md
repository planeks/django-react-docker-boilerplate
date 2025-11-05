## 🖥️ Deploying the project to the server

📌 Modify this section according to the project needs.

### Configure main user

We strongly recommend deploying the project with an unprivileged user instead of `root`.

> The next paragraph describes how to create new unprivileged users to the system. If you use AWS EC2 for example, it is possible that you already have such kind of user in your system by default. It can be named `ubuntu`. If such a user already exists you do not need to create another one.

You can create the user (for example `appuser`) with the following command:

```shell
$ adduser appuser
```

You will be asked for the password for the user. You can use [https://www.random.org/passwords/](https://www.random.org/passwords/) to generate new passwords.

Add the new user `appuser` to the `sudo` group:

```bash
$ usermod -aG sudo appuser
```

Now the user can run a command with superuser privileges if it is necessary.

Usually, you shouldn't log in to the server with a password.
You should use the ssh key. If you don't have one yet you can create
it easily on your local computer with the following command:

```bash
$ ssh-keygen -t rsa
```

> The command works on Linux and Mac OS. If you are using Windows you can use
> PuTTYgen to generate the key.

You can find the content of your public key with the next command:

```bash
$ cat ~/.ssh/id_rsa.pub
```

Now, go to the server and temporarily switch to the new user:

```bash
$ su - appuser
```

Now you will be in your new user's home directory.

Create a new directory called `.ssh` and restrict its permissions with the following commands:

```bash
$ mkdir ~/.ssh
$ chmod 700 ~/.ssh
```

Now open a file in `.ssh` called `authorized_keys` with a text editor. We will use `nano` to edit the file:

```bash
$ nano ~/.ssh/authorized_keys
```

> If your server installation does not contain `nano` then you can use `vi`. Just remember `vi` has different modes for editing text and running commands. Use `i` key to switch to the *insert mode*, insert enough text, and then use `Esc` to switch back to the *command mode*. Press `:` to activate the command line and type `wq` command to save file and exit. If you want to exit without saving the file just use `q!` command.

Now insert your public key (which should be in your clipboard) by pasting it into the editor. Hit `CTRL-x` to exit the file, then `y` to save the changes that you made, then `ENTER` to confirm the file name (in the case if you use `nano` of course).

Now restrict the permissions of the `authorized_keys` file with this command:

```bash
$ chmod 600 ~/.ssh/authorized_keys
```

Type this command once to return to the root user:

```bash
$ exit
```

Now your public key is installed, and you can use SSH keys to log in as your user.

Type `exit` again to logout from `the` server console and try to log in again as `appuser` and test the key based login:

```bash
$ ssh appuser@XXX.XXX.XXX.XXX
```

If you added public key authentication to your user, as described above, your private key will be used as authentication. Otherwise, you will be prompted for your user's password.

Remember, if you need to run a command with root privileges, type `sudo` before it like this:

```bash
$ sudo command_to_run
```

### Install dependencies

We also recommend to install a necessary software:

```bash
$ sudo apt install -y git wget tmux htop mc nano build-essential
```

🐳 Install Docker and Docker Compose as it was described above.

And add your user to the group:

```bash
$ sudo usermod -aG docker "$USER"
```

Create a new group on the host machine with `gid 1024` . It will be important for allowing to setup correct non-root permissions to the volumes.

```bash
$ sudo addgroup --gid 1024 django
```

> NOTE. If you cannot use the GID 1024 for any reason, you can choose other value but edit the `Dockerfile` as well.

And add your user to the group:

```bash
$ sudo usermod -aG django ${USER}
$ newgrp django
```

### Generate deploy key

Now, we need to create SSH key for deploy code from the remote repository
(if you use GitHub, Bitbucket, GitLub, etc.).

    $ ssh-keygen -t rsa

Show the public key:

    $ cat ~/.ssh/id_rsa.pub

Then go to the project's settings of your project on source code hosting (if you use Bitbucket than go to "Access keys" section, if GitHub than search "Deploy keys" section) and add the key there.

> It is a list of keys which allows the read-only access to the repository. It is very important that such kind of keys does not affect our user quota. Also, it allows doing not use the keys of our developers.

### Clone the project

Create the directory for projects and clone the source code:

```bash
$ mkdir ~/projects
$ cd ~/projects
$ git clone <git_remote_url>
```

📌 Use your own correct Git remote directory URL.

Go inside the project directory and do the next to create initial volumes:

```bash
$ source ./init_production_volumes.sh
```

Then you need to create the `.env` file with proper settings. You can use the `prod.env` as a template to create it

```shell
$ cp prod.env .env
```

Open the `.env` file in your editor and change the settings as you need:

```shell
PYTHONENCODING=utf8
COMPOSE_IMAGES_PREFIX=newprojectname
DEBUG=0
CONFIGURATION=prod
DJANGO_LOG_LEVEL=INFO
SECRET_KEY="<secret_key>"
ALLOWED_HOSTS=example.com
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=db
POSTGRES_USER=dbuser
POSTGRES_PASSWORD=<db_password>
REDIS_URL=redis://redis:6379/0
SITE_DOMAIN=example.com
SITE_URL=https://example.com
EMAIL_HOST=
EMAIL_PORT=25
EMAIL_HOST_USER=<email_user>
EMAIL_HOST_PASSWORD=<email_password>
SENTRY_DSN=<sentry_dsn>
CELERY_FLOWER_USER=flower
CELERY_FLOWER_PASSWORD=<flower_password>
CADDY_PASSWORD=<here should be hash of a password>
```

> ⚠️ Generate strong secret key and passwords. It is very important.

Change the necessary settings. Please check the `ALLOWED_HOSTS` settings that should
contain the correct domain name. Also, you need to change the `SITE_DOMAIN` value that is using with configuring Caddy. It should be the value of the site domain. The value `COMPOSE_IMAGES_PREFIX` can be the same as for `dev` configuration. It is a prefix for the container images.

Now you can run the containers:

```bash
$ docker compose -f compose.prod.yml build
$ docker compose -f compose.prod.yml up -d
```

# GitHub Actions Setup Guide

## Overview

This guide will help you set up GitHub Actions workflows for a Django/React application with three environments: Development, Staging, and Production.

## Create Workflow Files

Project already contains following directory structure:

```
.github/workflows/
├── ci.yml                    # CI tests for backend and frontend
├── deploy-reusable.yml       # Reusable deployment workflow
├── dev_deploy.yml            # Development deployment
├── staging_deploy.yml        # Staging deployment
└── production_deploy.yml     # Production deployment
```

## 2. Set Up Environments

Navigate to your repository on GitHub:

1. Go to **Settings** → **Environments**
2. Create three environments:
   - `dev`
   - `staging`
   - `production`

### Production Environment Protection

For the **production** environment:
1. Click on the `production` environment
2. Enable **"Required reviewers"**
3. Add team members who should approve production deployments
4. Optionally set a **wait timer** (e.g., 5 minutes) before deployment

## 3. Configure Secrets

For each environment, add the required secrets:

### Development Environment (`dev`)

Go to **Settings → Environments → dev → Secrets**

Add the following secrets:
- **`DEV_HOST`** - Your development server IP address or hostname
- **`DEV_SSH_KEY`** - SSH private key for accessing the dev server
- [Optional] **`DEV_HEALTH_URL`** - e.g., `https://dev.yourapp.com/`

### Staging Environment (`staging`)

Go to **Settings → Environments → staging → Secrets**

Add the following secrets:
- **`STAGING_HOST`** - Your staging server IP address or hostname
- **`STAGING_SSH_KEY`** - SSH private key for accessing the staging server
- [Optional] **`STAGING_HEALTH_URL`** - e.g., `https://staging.yourapp.com/`

### Production Environment (`production`)

Go to **Settings → Environments → production → Secrets**

Add the following secrets:
- **`PROD_HOST`** - Your production server IP address or hostname
- **`PROD_SSH_KEY`** - SSH private key for accessing the production server
- [Optional] **`PROD_HEALTH_URL`** - e.g., `https://yourapp.com/`

### Generating SSH Keys

If you need to generate SSH keys for GitHub:
**Note**: make sure to **not** use a passphrase for the key.

```bash
# Generate a new SSH key pair
ssh-keygen -t ed25519 -C "github-actions" -f github_actions_key

# Copy the public key to your server
ssh-copy-id -i github_actions_key.pub appuser@your-server

# Copy the private key content to GitHub Secrets
cat github_actions_key
```

## 4. Set Up Your Servers

Ensure each server (dev, staging, production) has:

### Prerequisites

- Docker and Docker Compose installed
- Git installed
- User `appuser` created with sudo privileges
- You followed steps above in this document

## 5. How Deployments Work

### Development Deployment

**Trigger:** Push to `develop` branch

**Process:**
1. Runs CI
2. Checks out code
3. Deploys to dev server using `compose.dev.yml`
4. Runs database migrations

**Command to trigger manually:**
```bash
git push origin develop
```

Or use **Actions** → **Deploy to Development** → **Run workflow**

### Staging (Production) Deployment

**Trigger:** Push to `staging (main)` branch

**Process:**
1. Runs CI tests (backend and frontend)
2. Deploys to the server using `compose.prod.yml`
3. Runs database migrations
4. Collects static files

**Command to trigger manually:**
```bash
git push origin staging (main)
```

Or use **Actions** → **Deploy to Staging (Production)** → **Run workflow**

## 6. Branch Strategy

The workflow is designed for this Git branching strategy:

```
develop  → Development environment
   ↓
staging  → Staging environment (merge develop here)
   ↓
 main    → Production environment (merge staging here)
```

## 6. Monitoring Deployments

### View Workflow Runs

1. Go to **Actions** tab in your repository
2. Select a workflow from the left sidebar
3. Click on a specific run to see details

### Deployment Status

You can monitor:
- Build logs
- Test results
- Deployment status
- Health check results

### Troubleshooting

If a deployment fails:
1. Check the workflow logs in the **Actions** tab
2. SSH into the server and check:
   ```bash
   cd ~/projects/django-react-docker-boilerplate
   docker compose -f compose.prod.yml logs
   ```
3. Verify secrets are correctly set in GitHub
4. Ensure server has proper permissions and resources

## Security Best Practices

1. ✅ Never commit secrets or SSH keys to the repository
2. ✅ Use environment-specific secrets
3. ✅ Rotate SSH keys regularly
4. ✅ Enable branch protection rules for `main` and `staging`
5. ✅ Require pull request reviews before merging
6. ✅ Use required reviewers for production deployments

## Conclusion

Your CI/CD pipeline is now set up! 🚀

For any issues or questions, refer to:
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- Your project's specific requirements