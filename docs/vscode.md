# 🏃‍ Running the Project in VSCode with Docker Compose

Complete VSCode development container setup for Django + Celery + Frontend stack with Docker Compose.

---

## Step 1: Configure VSCode Dev Container

Create `.devcontainer/devcontainer.json` in your project root:

```json
{
  "name": "Django Full Stack Development",
  "dockerComposeFile": "../local.yml",
  "service": "django",
  "workspaceFolder": "/opt/project/src",

  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-python.debugpy",
        "ms-azuretools.vscode-docker",
        "batisteo.vscode-django",
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
        "Vue.volar",
        "mtxr.sqltools",
        "mtxr.sqltools-driver-pg",
        "eamodio.gitlens",
        "editorconfig.editorconfig",
        "usernamehw.errorlens"
      ],

      "settings": {
        "python.defaultInterpreterPath": "/opt/project/src/.venv/bin/python",
        "python.terminal.activateEnvironment": true,
        "python.analysis.typeCheckingMode": "basic",
        "python.linting.enabled": true,
        "python.linting.flake8Enabled": true,
        "python.formatting.provider": "black",
        "python.testing.pytestEnabled": true,
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
          "source.organizeImports": "explicit"
        },
        "files.exclude": {
          "**/__pycache__": true,
          "**/*.pyc": true,
          "**/.pytest_cache": true
        }
      }
    }
  },

  "runServices": [
    "django",
    "celeryworker",
    "celerybeat",
    "flower",
    "redis",
    "postgres",
    "mailhog",
    "mkdocs",
    "frontend"
  ],

  "forwardPorts": [8000, 5555, 5173, 8025, 8050],

  "portsAttributes": {
    "8000": {
      "label": "Django",
      "onAutoForward": "notify"
    },
    "5555": {
      "label": "Flower Dashboard",
      "onAutoForward": "silent"
    },
    "5173": {
      "label": "Frontend (Vite)",
      "onAutoForward": "notify"
    },
    "8025": {
      "label": "Mailhog UI",
      "onAutoForward": "silent"
    },
    "8050": {
      "label": "MkDocs",
      "onAutoForward": "silent"
    }
  },

  "shutdownAction": "stopCompose",

  "postCreateCommand": "echo '🚀 Development container is ready!'",

  "remoteUser": "root"
}
```

**Key Configuration Details:**
- `dockerComposeFile`: Relative path from `.devcontainer` folder to your `local.yml`
- `service`: Specifies which container becomes your development environment (Django in this case)
- `workspaceFolder`: The folder that opens inside the container
- `runServices`: All services that should start when opening the container
- `forwardPorts`: Automatically forwards these ports to your host machine

---

## Step 2: Debugger Configuration

Create `.vscode/launch.json`:

```json
{
  "version": "1.0.0",
  "configurations": [
    {
      "name": "Django: Debug Server",
      "type": "python",
      "request": "launch",
      "program": "${workspaceFolder}/manage.py",
      "args": [
        "runserver",
        "0.0.0.0:8000",
        "--noreload"
      ],
      "django": true,
      "justMyCode": false,
      "console": "integratedTerminal",
      "envFile": "${workspaceFolder}/../.env",
      "python": "${workspaceFolder}/.venv/bin/python"
    },
    {
      "name": "Django: Run Tests",
      "type": "python",
      "request": "launch",
      "program": "${workspaceFolder}/manage.py",
      "args": [
        "test",
        "--keepdb"
      ],
      "django": true,
      "console": "integratedTerminal",
      "envFile": "${workspaceFolder}/../.env",
      "python": "${workspaceFolder}/.venv/bin/python"
    },
    {
      "name": "Celery: Worker",
      "type": "python",
      "request": "launch",
      "module": "celery",
      "args": [
        "-A",
        "config",
        "worker",
        "-l",
        "INFO",
        "-P",
        "solo"
      ],
      "console": "integratedTerminal",
      "envFile": "${workspaceFolder}/../.env",
      "python": "${workspaceFolder}/.venv/bin/python",
      "justMyCode": false
    },
    {
      "name": "Celery: Beat Scheduler",
      "type": "python",
      "request": "launch",
      "module": "celery",
      "args": [
        "-A",
        "config",
        "beat",
        "-l",
        "INFO",
        "--scheduler",
        "django_celery_beat.schedulers:DatabaseScheduler"
      ],
      "console": "integratedTerminal",
      "envFile": "${workspaceFolder}/../.env",
      "python": "${workspaceFolder}/.venv/bin/python"
    },
    {
      "name": "Python: Current File",
      "type": "python",
      "request": "launch",
      "program": "${file}",
      "console": "integratedTerminal",
      "justMyCode": false,
      "envFile": "${workspaceFolder}/../.env",
      "python": "${workspaceFolder}/.venv/bin/python"
    },
    {
      "name": "Django: Shell",
      "type": "python",
      "request": "launch",
      "program": "${workspaceFolder}/manage.py",
      "args": [
        "shell_plus"
      ],
      "django": true,
      "console": "integratedTerminal",
      "envFile": "${workspaceFolder}/../.env",
      "python": "${workspaceFolder}/.venv/bin/python"
    }
  ],
  "compounds": [
    {
      "name": "Full Stack: Django + Celery Worker",
      "configurations": [
        "Django: Debug Server",
        "Celery: Worker"
      ],
      "presentation": {
        "group": "fullstack",
        "order": 1
      }
    },
    {
      "name": "Full Stack: All Services",
      "configurations": [
        "Django: Debug Server",
        "Celery: Worker",
        "Celery: Beat Scheduler"
      ],
      "presentation": {
        "group": "fullstack",
        "order": 2
      }
    }
  ]
}
```

**Debug Configuration Highlights:**
- **Django Server**: Runs with `--noreload` to prevent auto-restart during debugging
- **Celery Worker**: Uses `-P solo` for single-process mode (easier debugging)
- **Celery Beat**: Includes database scheduler for periodic tasks
- **Compound Configurations**: Start multiple debuggers simultaneously
- `justMyCode: false`: Allows stepping into library code

---

## Step 3: Workspace Settings

Create `.vscode/settings.json`:

```json
{
  "python.defaultInterpreterPath": "/opt/project/src/.venv/bin/python",
  "python.terminal.activateEnvironment": true,

  "python.linting.enabled": true,

  "python.formatting.blackArgs": [
    "--line-length=120"
  ],

  "python.testing.pytestEnabled": true,
  "python.testing.pytestArgs": [
    "tests",
    "-v",
    "--tb=short"
  ],
  "python.testing.unittestEnabled": false,

  "python.analysis.typeCheckingMode": "basic",
  "python.analysis.autoImportCompletions": true,
  "python.analysis.diagnosticMode": "workspace",

  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": "explicit"
  },
  "editor.rulers": [120],
  "editor.tabSize": 4,
  "editor.insertSpaces": true,

  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.organizeImports": "explicit"
    }
  },

  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.tabSize": 2
  },

  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.tabSize": 2
  },

  "[markdown]": {
    "editor.wordWrap": "on",
    "editor.quickSuggestions": false
  },

  "files.exclude": {
    "**/__pycache__": true,
    "**/*.pyc": true,
    "**/.pytest_cache": true,
    "**/.mypy_cache": true,
    "**/node_modules": true,
    "**/.venv": false
  },

  "files.watcherExclude": {
    "**/.venv/**": true,
    "**/node_modules/**": true,
    "**/__pycache__/**": true
  },

  "files.associations": {
    "*.html": "html",
    "**/templates/**/*.html": "django-html",
    "**/templates/**/*": "django-txt"
  },

  "emmet.includeLanguages": {
    "django-html": "html"
  },

  "search.exclude": {
    "**/.venv": true,
    "**/node_modules": true,
    "**/migrations": true,
    "**/__pycache__": true,
    "**/staticfiles": true,
    "**/media": true
  },

  "sqltools.connections": [
    {
      "name": "PostgreSQL - Dev",
      "driver": "PostgreSQL",
      "server": "postgres",
      "port": 5432,
      "database": "${env:POSTGRES_DB}",
      "username": "${env:POSTGRES_USER}",
      "password": "${env:POSTGRES_PASSWORD}"
    }
  ],

  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "/bin/bash",
      "icon": "terminal-bash"
    }
  }
}
```

**Settings Breakdown:**
- **Testing**: Pytest configuration with verbose output
- **File Associations**: Django templates recognized properly
- **Database**: SQLTools connection for browsing PostgreSQL

---

## Step 4: Tasks Configuration

Create `.vscode/tasks.json`:

```json
{
  "version": "1.0.0",
  "tasks": [
    {
      "label": "Django: Run Server",
      "type": "shell",
      "command": "${workspaceFolder}/.venv/bin/python",
      "args": [
        "manage.py",
        "runserver",
        "0.0.0.0:8000"
      ],
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "dedicated"
      },
      "group": {
        "kind": "build",
        "isDefault": false
      }
    },
    {
      "label": "Django: Make Migrations",
      "type": "shell",
      "command": "${workspaceFolder}/.venv/bin/python",
      "args": [
        "manage.py",
        "makemigrations"
      ],
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "shared"
      }
    },
    {
      "label": "Django: Migrate",
      "type": "shell",
      "command": "${workspaceFolder}/.venv/bin/python",
      "args": [
        "manage.py",
        "migrate"
      ],
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "shared"
      }
    },
    {
      "label": "Django: Create Superuser",
      "type": "shell",
      "command": "${workspaceFolder}/.venv/bin/python",
      "args": [
        "manage.py",
        "createsuperuser"
      ],
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "shared"
      }
    },
    {
      "label": "Django: Shell Plus",
      "type": "shell",
      "command": "${workspaceFolder}/.venv/bin/python",
      "args": [
        "manage.py",
        "shell_plus"
      ],
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "dedicated"
      }
    },
    {
      "label": "Django: Collect Static",
      "type": "shell",
      "command": "${workspaceFolder}/.venv/bin/python",
      "args": [
        "manage.py",
        "collectstatic",
        "--noinput"
      ],
      "problemMatcher": []
    },
    {
      "label": "Tests: Run All",
      "type": "shell",
      "command": "${workspaceFolder}/.venv/bin/pytest",
      "args": [
        "tests",
        "-v"
      ],
      "problemMatcher": [],
      "group": {
        "kind": "test",
        "isDefault": true
      }
    },
    {
      "label": "Tests: Run with Coverage",
      "type": "shell",
      "command": "${workspaceFolder}/.venv/bin/pytest",
      "args": [
        "tests",
        "--cov=.",
        "--cov-report=html",
        "--cov-report=term"
      ],
      "problemMatcher": []
    },
    {
      "label": "Celery: Start Worker",
      "type": "shell",
      "command": "${workspaceFolder}/.venv/bin/celery",
      "args": [
        "-A",
        "config",
        "worker",
        "-l",
        "INFO"
      ],
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "dedicated"
      }
    },
    {
      "label": "Celery: Start Beat",
      "type": "shell",
      "command": "${workspaceFolder}/.venv/bin/celery",
      "args": [
        "-A",
        "config",
        "beat",
        "-l",
        "INFO"
      ],
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "dedicated"
      }
    },
    {
      "label": "Docker: Rebuild All Services",
      "type": "shell",
      "command": "docker-compose",
      "args": [
        "-f",
        "../local.yml",
        "up",
        "-d",
        "--build"
      ],
      "problemMatcher": []
    },
    {
      "label": "Docker: Stop All Services",
      "type": "shell",
      "command": "docker-compose",
      "args": [
        "-f",
        "../local.yml",
        "down"
      ],
      "problemMatcher": []
    },
    {
      "label": "Docker: View Logs",
      "type": "shell",
      "command": "docker-compose",
      "args": [
        "-f",
        "../local.yml",
        "logs",
        "-f"
      ],
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "dedicated"
      }
    },
    {
      "label": "Code Quality: Format All Python",
      "type": "shell",
      "command": "${workspaceFolder}/.venv/bin/black",
      "args": [
        "."
      ],
      "problemMatcher": []
    }
  ]
}
```

**Available Tasks:**
- **Django Management**: runserver, migrations, superuser creation
- **Testing**: Run tests with/without coverage
- **Celery**: Start worker and beat scheduler
- **Docker**: Rebuild, stop, view logs
- **Code Quality**: Format and lint code

**Usage**: Press `Ctrl+Shift+P` → "Tasks: Run Task" → Select a task

---

## Step 5: Start Development

### Opening in Dev Container

1. **Install VSCode Extension**: "Dev Containers" (`ms-vscode-remote.remote-containers`)

2. **Open Project in Container**:
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Select: **"Dev Containers: Open Folder in Container..."**
   - Choose your project folder
   - VSCode will build and start all Docker Compose services

3. **Wait for Container to Build**:
   - First time takes 3-10 minutes (downloads images, installs dependencies)
   - Subsequent opens take 10-30 seconds

4. **Verify Services are Running**:
   ```bash
   docker-compose -f local.yml ps
   ```

### Quick Access URLs

Once services are running:

- **Django**: http://localhost:8000
- **Flower Dashboard**: http://localhost:5555/flower
- **Frontend (Vite)**: http://localhost:5173
- **Mailhog UI**: http://localhost:8025
- **MkDocs**: http://localhost:8050

---

## Step 6: Common Development Workflows

### Starting Debugger

1. Go to **Run and Debug** panel (`Ctrl+Shift+D`)
2. Select a configuration from dropdown:
   - "Django: Debug Server" - Debug Django app
   - "Full Stack: All Services" - Debug Django + Celery together
3. Press `F5` or click green play button
4. Set breakpoints by clicking left of line numbers

### Running Django Commands

**Option 1: Using Tasks**
- Press `Ctrl+Shift+P` → "Tasks: Run Task"
- Select task (e.g., "Django: Make Migrations")

**Option 2: Using Terminal**
```bash
python manage.py makemigrations
python manage.py migrate
python manage.py createsuperuser
python manage.py shell_plus
```

### Running Tests

**Via Debug Configuration:**
- Select "Django: Run Tests" in debugger
- Press `F5`

**Via Task:**
- `Ctrl+Shift+P` → "Tasks: Run Task" → "Tests: Run All"

**Via Terminal:**
```bash
pytest tests/ -v
pytest tests/ --cov=. --cov-report=html
```

### Database Access

**SQLTools (GUI):**
1. Click SQLTools icon in sidebar
2. Connect to "PostgreSQL - Dev"
3. Browse tables, run queries

**Command Line:**
```bash
# Access Django shell with database
python manage.py shell_plus

# Access PostgreSQL directly
docker-compose -f local.yml exec postgres psql -U <POSTGRES_USER> -d <POSTGRES_DB>
```

### Viewing Logs

**Individual Service:**
```bash
docker-compose -f local.yml logs -f django
docker-compose -f local.yml logs -f celeryworker
```

**All Services:**
- Use Task: "Docker: View Logs"
- Or terminal: `docker-compose -f local.yml logs -f`

### Rebuilding Services

**When Dockerfile changes:**
```bash
docker-compose -f local.yml up -d --build
```

**Complete rebuild:**
```bash
docker-compose -f local.yml down -v
docker-compose -f local.yml up -d --build
```

---

## Step 7: Troubleshooting

### Container Won't Start

**Check Docker is running:**
```bash
docker ps
```

**View container logs:**
```bash
docker-compose -f local.yml logs django
```

**Rebuild from scratch:**
```bash
docker-compose -f local.yml down -v
docker-compose -f local.yml build --no-cache
docker-compose -f local.yml up -d
```

### Python Interpreter Not Found

1. **Reopen in Container**: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"
2. **Manually select interpreter**: `Ctrl+Shift+P` → "Python: Select Interpreter" → `/opt/project/src/.venv/bin/python`

### Port Already in Use

**Find and kill process:**
```bash
# Linux/Mac
sudo lsof -i :8000
sudo kill -9 <PID>

# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

### Debugging Not Working

1. Ensure `--noreload` flag is in debug args (already configured)
2. Check `.env` file exists and is properly loaded
3. Verify breakpoints are in executed code paths
4. Check "Python: Log Level" is set to "Debug" in settings

### Database Connection Issues

**Ensure PostgreSQL is ready:**
```bash
docker-compose -f local.yml exec postgres pg_isready
```

**Check environment variables:**
```bash
echo $POSTGRES_DB
echo $POSTGRES_USER
```

**Reset database:**
```bash
docker-compose -f local.yml down -v
docker-compose -f local.yml up -d postgres
python manage.py migrate
```

### Celery Not Processing Tasks

**Check Redis connection:**
```bash
docker-compose -f local.yml exec redis redis-cli ping
# Should return: PONG
```

**Restart Celery services:**
```bash
docker-compose -f local.yml restart celeryworker celerybeat
```

**View Flower dashboard:**
- Open: http://localhost:5555/flower
- Check worker status and queues

---

## Step 8: Additional Tips

### Using Caddy Locally

To enable Caddy reverse proxy:
```bash
docker-compose -f local.yml --profile dev up -d
```

Access services through Caddy:
- Django: http://localhost/
- Flower: http://localhost/flower

### Hot Reload for Frontend

The frontend service is configured with:
- `CHOKIDAR_USEPOLLING=true` for file watching inside Docker
- Volume mounts for live code updates
- Vite HMR (Hot Module Replacement)

Changes to frontend code automatically refresh the browser.

### Git Integration

**Recommended `.gitignore` additions:**
```gitignore
# VSCode
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json

# Dev Container
.devcontainer/

# Python
__pycache__/
*.py[cod]
.venv/
.pytest_cache/

# Django
*.log
db.sqlite3
media/
staticfiles/

# Docker
*.log
```

### Keyboard Shortcuts

- `F5` - Start Debugging
- `Shift+F5` - Stop Debugging
- `Ctrl+Shift+D` - Open Debug Panel
- `Ctrl+Shift+P` - Command Palette
- `Ctrl+` ` - Toggle Terminal
- `Ctrl+Shift+B` - Run Build Task

### Extensions Recommendations

Create `.vscode/extensions.json`:
```json
{
  "recommendations": [
    "ms-python.python",
    "ms-python.vscode-pylance",
    "ms-azuretools.vscode-docker",
    "batisteo.vscode-django",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint"
  ]
}
```