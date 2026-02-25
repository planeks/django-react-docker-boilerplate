# Code quality

This project uses automated linting, formatting, and security scanning across both the Python backend and the React frontend.

## Dependency management

This project uses [Poetry](https://python-poetry.org/) (v1.8.2) to manage Python dependencies.
All dependencies are declared in `src/pyproject.toml` and locked in `src/poetry.lock`.
Three dependency groups are defined: **main**, **dev**, and **docs**.

### Adding a dependency

```bash
$ docker compose -f compose.dev.yml run --rm django add <package>
```

To pin a specific version:

```bash
$ docker compose -f compose.dev.yml run --rm django add "django>=5.1,<5.2"
```

### Updating a dependency

```bash
$ docker compose -f compose.dev.yml exec django poetry update <package>  # update a specific package
$ docker compose -f compose.dev.yml exec django poetry update            # update all packages
$ docker compose -f compose.dev.yml exec django poetry show --outdated   # list outdated packages
```

### Removing a dependency

```bash
$ docker compose -f compose.dev.yml exec django poetry remove <package>
```

> Always commit both `pyproject.toml` and `poetry.lock` after making changes.
> After adding or removing dependencies, rebuild the Docker image: `docker compose -f compose.dev.yml build django`.

## Tools

### Python (backend)

- **Ruff** handles both linting and formatting. Configuration lives in `src/pyproject.toml` under `[tool.ruff]`.
- **pip-audit** scans Python dependencies for known vulnerabilities in CI.

### JavaScript (frontend)

- **ESLint** catches bugs and enforces code style. Config is in `src/frontend/eslint.config.js` (ESLint 9 flat config).
- **Prettier** handles formatting. Config is in `src/frontend/.prettierrc`.
- **Vitest** runs unit tests with jsdom. Config is in `src/frontend/vitest.config.js`.
- **npm audit** scans npm dependencies for known vulnerabilities in CI.

## Running locally

### Backend

```bash
docker compose -f compose.dev.yml exec django ruff check .          # lint
docker compose -f compose.dev.yml exec django ruff check --fix .    # lint and auto-fix
docker compose -f compose.dev.yml exec django ruff format .         # format
docker compose -f compose.dev.yml exec django ruff format --check . # check formatting without changes
```

### Frontend

```bash
docker compose -f compose.dev.yml exec frontend npm run lint          # ESLint
docker compose -f compose.dev.yml exec frontend npm run lint:fix      # ESLint with auto-fix
docker compose -f compose.dev.yml exec frontend npm run format        # Prettier write
docker compose -f compose.dev.yml exec frontend npm run format:check  # Prettier check only
docker compose -f compose.dev.yml exec frontend npm test              # Vitest (single run)
docker compose -f compose.dev.yml exec frontend npm run test:watch    # Vitest (watch mode)
```

## Pre-commit hooks

The project includes a `.pre-commit-config.yaml` that runs Ruff, ESLint, and Prettier automatically before each commit. To set it up:

```bash
pip install pre-commit
pre-commit install
```

After that, every `git commit` will run the hooks on staged files. To run them manually on all files:

```bash
pre-commit run --all-files
```

## CI pipeline

The GitHub Actions CI workflow (`.github/workflows/ci.yml`) runs four jobs:

1. **lint-backend** -- Ruff check, Ruff format check, pip-audit
2. **lint-frontend** -- ESLint, Prettier check, npm audit
3. **test-backend** -- Django tests in Docker (runs after lint-backend passes)
4. **test-frontend** -- Vitest and production build (runs after lint-frontend passes)

Staging and production deploys require CI to pass first.

## Dependabot

Dependabot (`.github/dependabot.yml`) opens weekly pull requests for:

- Python dependencies (`pip` ecosystem, `src/` directory)
- npm dependencies (`npm` ecosystem, `src/frontend/` directory)
- GitHub Actions versions (`github-actions` ecosystem)
