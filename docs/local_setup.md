## How to create the project

### This file shows how to start project locally. It should become available at http://127.0.0.1:8000/

Download the last version of the boiler plate from the repository: https://github.com/planeks/django-react-docker-boilerplate

You can download the ZIP archive and unpack it to the directory, or clone the repository (but do not forget to clean the Git history in that case).

## 🐳 Install Docker and Docker Compose

For the local computer we recommend using Docker Desktop. 
You can download it from the official site: https://www.docker.com/products/docker-desktop

There are versions for Windows, Linux and Mac OS.

For the server installation you need the Docker Engine and Docker Compose. 
Use the following commands to install Docker on Ubuntu Linux:

```shell
# Add Docker's official GPG key:
$ sudo apt-get update
$ sudo apt-get install ca-certificates curl
$ sudo install -m 0755 -d /etc/apt/keyrings
$ sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
$ sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
$ echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

> If you are using another Linux distribution, please, check the official documentation: https://docs.docker.com/engine/install/

Test if Docker is installed correctly:

```shell
$ sudo systemctl status docker
```

Add the current user to the `docker` group (to avoid using `sudo`):

```shell
$ sudo usermod -aG docker ${USER}
```

## 🔨Setup the project locally

You need to run the project locally during the development. First of all, copy the `dev.env` file to the `.env` file in the same directory.

```shell
$ cp dev.env .env
```

Open the `.env` file in your editor and specify the settings:

```shell
PYTHONENCODING=utf8
DEBUG=1
CONFIGURATION=dev
DJANGO_LOG_LEVEL=INFO
SECRET_KEY="<secret_key>"
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=db
POSTGRES_USER=dbuser
POSTGRES_PASSWORD=dbpassword
REDIS_URL=redis://redis:6379/0
SITE_URL=http://myproject.local:8000
EMAIL_HOST=mailhog
EMAIL_PORT=1025
CADDY_PASSWORD=<here should be hash of a password>
```

📌 Generate the secret key for the project and paste it to the `.env` file.
Also, generate the reasonably good password for the database user.

We strongly recommend creating some local domain in your `/etc/hosts` file to work with the project :

```
127.0.0.1   myproject.local
```

We specify the following volume in the application container:

- `/data` -> `data/dev`

> If you use Linux and Docker Engine for the local development you need to
> setup proper permissions for the volume. It is important if you want to
> use Docker without `sudo`. Check the `init_production_volumes.sh` script
> and the "Deploying the project to the server" section for more details,
> and adapt it for your needs.

You need to edit `Dockerfile`, `entrypoint` and `compose.dev.yml` files if you need to add other directories to the container and define them as volumes.

Use the following command to build the containers:

```shell
$ newgrp docker
$ docker compose -f compose.dev.yml build
```

Use the next command to run the project in detached mode:

```shell
$ docker compose -f compose.dev.yml up -d
```

Use the following command to run `bash` inside the container if you want to run a management command like Django interactive shell.

```shell
$ docker compose -f compose.dev.yml exec django bash
```

Or, you can run the temporary container:

```shell
$ docker compose -f compose.dev.yml run --rm django bash
```

To start tests, run:

```shell
$ docker compose -f compose.dev.yml run --rm django test
```