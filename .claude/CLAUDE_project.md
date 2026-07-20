# CLAUDE.md — django-react-docker-boilerplate (PLANEKS)

> Project-specific layer for repos forked from [`planeks/django-react-docker-boilerplate`](https://github.com/planeks/django-react-docker-boilerplate).
> Layered on top of the base, Python, Django, React, and architecture standards.
>
> **Rule of thumb: everything runs inside Docker.** Don't install Python/Node/Postgres/Redis on the host. If a command needs Django, the DB, Poetry, or npm — wrap it in `docker compose -f compose.dev.yml ...`.

---

## Stack

**Backend**

- **Python** 3.12 (`src/.python-version` = 3.12.1, Ruff targets `py312`; `pyproject.toml` declares `^3.10` for compatibility)
- **Django** 5.1 · **DRF** 3.15 · **drf-spectacular** (OpenAPI) · **djangorestframework-simplejwt** (JWT)
- **PostgreSQL** (`psycopg2`) · **Redis** 6 (cache + Celery broker/result backend)
- **Celery** 5.3 + **celery-redbeat** · **Flower**
- **Gunicorn** (prod) · **Uvicorn** · **Whitenoise** · **Sentry SDK**
- **Poetry** 1.8.2 (in-project venv at `/opt/project/src/.venv`) · **Ruff** · **pytest** + **pytest-django** · **pre-commit**
- **MkDocs Material** for project docs · **MailHog** for local email · **Caddy** as reverse proxy

**Frontend**

- **React** 18.3, **plain JSX — no TypeScript** in this boilerplate
- **Vite** 5 (manifest-based, served into Django templates via `{% vite_asset %}`)
- **npm** (`package-lock.json`) · **ESLint 9** flat config · **Prettier** · **Vitest** + Testing Library + jsdom
- `react-i18next`, `@sentry/react`, FontAwesome

**Infra:** Ansible provisioning, GitHub Actions CI/CD (dev/staging/production).

### Documented deviations from the shared templates

Follow these over the generic rules above — they reflect what this repo actually is:

| Template says | This repo does | Why |
|---|---|---|
| React: TypeScript-first | Plain JSX (`.jsx`) | Boilerplate ships JS. Don't migrate a project to TS unilaterally — propose it first. |
| React: `eslint-config-airbnb` | ESLint 9 flat config: `js.recommended` + `react` + `react-hooks` | Flat-config migration; airbnb config has no stable flat build. |
| React: feature-first `src/features/...` | Flat `src/frontend/src/` (App, setup/, locales/) | Starter is tiny. **Adopt the feature-first layout as soon as a second feature appears.** |
| Django: apps under `apps/<app>/` | Apps at `src/<app>/` (`accounts`, `core`, `frontend`) | Boilerplate layout. Keep it. |
| Django: API routes `/api/v1/<app>/` | `/api/...` (no version segment yet) | Add versioning when the API gets a real external consumer. |
| Python: Black/isort/flake8 | **Ruff only** (lint + format) | Single tool, config in `src/pyproject.toml`. |

---

## First-time setup

1. **Rename the placeholder** `NEWPROJECTNAME` across the repo (IDE-wide find & replace) — notably `src/config/settings/base.py`, `src/config/urls.py`, templates. Also set `COMPOSE_PROJECT_NAME` in `.env`.
2. **Create `.env`** and generate a fresh `SECRET_KEY`:
   ```bash
   cp dev.env .env
   ```
3. **Add a local domain** to `/etc/hosts` matching `SITE_URL` from `.env`:
   ```
   127.0.0.1  <project>.local
   ```
4. **Build and start:**
   ```bash
   docker compose -f compose.dev.yml build
   docker compose -f compose.dev.yml up -d
   ```
   The `dev` entrypoint runs `migrate` automatically on start.
5. **Create a superuser:**
   ```bash
   docker compose -f compose.dev.yml run --rm django manage createsuperuser
   ```
6. **Install pre-commit on the host** (one-time): `pip install pre-commit && pre-commit install`

---

## Services & ports

Defined in `compose.dev.yml`; all share `./.env`.

| Service | Port | Purpose |
|---|---|---|
| `django` | 8000 | Django dev server (hot reload) |
| `frontend` | 5173 | Vite dev server (HMR) |
| `celeryworker` | — | Celery worker (healthcheck: `celery -A config inspect ping`) |
| `celerybeat` | — | Celery beat (redbeat scheduler) |
| `flower` | 5555 | Celery monitoring UI (`/flower` prefix) |
| `redis` | — | Cache + broker |
| `postgres` | — | Database (`./data/dev_postgres`, backups in `./data/dev_backups`) |
| `mailhog` | 8025 | SMTP capture; app sends to `mailhog:1025` |
| `mkdocs` | 8050 | Live project docs |
| `caddy` | 80/443 | Reverse proxy — **profile `dev`**, off by default |

Bind mounts: `./src` → `/opt/project/src` (live code), `./data/dev` → `/data`. **Edit files on the host**, never inside the container.

`compose.prod.yml` mirrors this without MailHog, with gunicorn, Caddy always on, `frontend` under profile `build` (build-only, not a long-running service), and named volumes for `static`/`media`/`docs`.

---

## Common commands

There is **no Makefile and no `docker-compose.yml`** — always pass `-f compose.dev.yml` explicitly.

### Container lifecycle

```bash
docker compose -f compose.dev.yml build            # after Dockerfile / pyproject / package.json changes
docker compose -f compose.dev.yml up -d
docker compose -f compose.dev.yml logs -f django   # or frontend / celeryworker / celerybeat
docker compose -f compose.dev.yml stop
docker compose -f compose.dev.yml down
docker compose -f compose.dev.yml down -v          # DESTRUCTIVE: wipes volumes/DB — ask before running
docker compose -f compose.dev.yml --profile dev up -d caddy   # optional local HTTPS proxy
```

### The `django` entrypoint

`docker/django/entrypoint` dispatches on the first argument and runs everything as `appuser` via `gosu` + `poetry run`. **Prefer these over raw `python manage.py`:**

| Command | Does |
|---|---|
| `dev` | migrate + Django dev server (default in compose) |
| `prod` | migrate + collectstatic + gunicorn |
| `manage <cmd>` | `python manage.py <cmd>` |
| `shell` | `manage.py shell` |
| `test` | sets `DJANGO_SETTINGS_MODULE=config.settings.test`, runs `pytest` |
| `add <pkg>` | `poetry add` |
| `celery` / `celery-dev` | Celery entry points |
| `bash` / `python` / `help` | escape hatches |

```bash
docker compose -f compose.dev.yml exec django bash        # shell in a running container
docker compose -f compose.dev.yml run --rm django bash    # one-off, container removed after
```

### Django management & migrations

```bash
RUN="docker compose -f compose.dev.yml run --rm django"

$RUN manage makemigrations
$RUN manage migrate
$RUN manage createsuperuser
$RUN manage showmigrations
$RUN manage shell_plus          # django-extensions
$RUN manage clear_cache         # project command in src/core/
```

Review every generated migration before committing. CI fails a PR whose branch introduces a **duplicate migration number** for an app — rebase and renumber rather than editing history on the server.

### Backend deps (Poetry, inside the container)

```bash
docker compose -f compose.dev.yml run --rm django add <package>
docker compose -f compose.dev.yml run --rm django add "django>=5.1,<5.2"
docker compose -f compose.dev.yml exec django poetry add --group dev <package>
docker compose -f compose.dev.yml exec django poetry show --outdated
docker compose -f compose.dev.yml build django     # rebuild after any dep change
```

Commit **both** `src/pyproject.toml` and `src/poetry.lock`. Never `pip install`.

### Backend lint / format (Ruff only)

```bash
RUN="docker compose -f compose.dev.yml exec django"
$RUN ruff check .            # lint
$RUN ruff check --fix .      # autofix
$RUN ruff format .           # format
$RUN ruff format --check .   # CI-style verify
```

Config in `src/pyproject.toml`: line length **120**, `target-version = py312`, `select = ["ALL"]` with a documented ignore list, per-file ignores for `config/settings/*`, tests, `core/middleware.py`, `config/urls.py`; `migrations` and `frontend/node_modules` excluded. Don't disable rules ad-hoc — propose an ignore-list change via PR.

> Known drift: `.pre-commit-config.yaml` pins ruff `v0.15.1` while `pyproject.toml` pins `^0.6.7`. If the hook and the container disagree on formatting, that's why — flag it, don't paper over it with `# noqa`.

### Backend tests (pytest)

```bash
RUN="docker compose -f compose.dev.yml run --rm django"

$RUN test                                       # full suite (sets test settings for you)
$RUN bash -c "pytest -x accounts/"              # subset — must export settings yourself:
$RUN bash -c "DJANGO_SETTINGS_MODULE=config.settings.test pytest -k auth"
```

Use `pytest`, not `manage.py test`. There is no `pytest.ini`/`conftest.py` — the test settings module comes from the entrypoint. App tests live in `src/<app>/tests/`; API tests in `src/<app>/api/tests.py` (match what `accounts/` already does).

### Frontend

Everything lives in `src/frontend/`; npm scripts run in the `frontend` container.

```bash
RUN="docker compose -f compose.dev.yml exec frontend"

$RUN npm run lint          # eslint
$RUN npm run lint:fix
$RUN npm run format        # prettier write
$RUN npm run format:check
$RUN npm test              # vitest run
$RUN npm run test:watch
$RUN npm run build         # vite build → src/frontend/dist (+ .vite/manifest.json)
```

Adding a package: `docker compose -f compose.dev.yml exec frontend npm install <pkg>`, then rebuild the image. Commit `package.json` **and** `package-lock.json`.

### Django ↔ React integration

`src/frontend/` is **both a Django app and the Vite project**:

- `src/frontend/templatetags/vite_tags.py` exposes `{% vite_asset 'src/index.jsx' %}`, which reads `src/frontend/dist/.vite/manifest.json` in production and points at the Vite dev server in development.
- `src/frontend/views.py` renders `templates/frontend/index.html` — the SPA shell.
- Vite `base` is `/static/` on build so Whitenoise/Caddy serve the hashed assets.

So: **don't add a separate static pipeline, and don't hardcode asset paths in templates** — go through `vite_asset`. Frontend env vars must be prefixed `VITE_` to reach the browser (`VITE_SENTRY_DSN`, `VITE_DEV_SERVER_HOST`).

### Database

```bash
docker compose -f compose.dev.yml exec postgres psql -U $POSTGRES_USER -d $POSTGRES_DB

# maintenance scripts baked into the postgres image
docker compose -f compose.prod.yml exec -T postgres backup
docker compose -f compose.prod.yml exec -T postgres backups            # list
docker compose -f compose.prod.yml exec -T postgres restore <file>
docker compose -f compose.prod.yml exec -T postgres cleanup <days>
```

### Docs & email

- MkDocs is served at <http://localhost:8050>; sources in `docs/`, config in `docker/mkdocs/mkdocs.yml`, navigation via `.pages`.
- Captured mail: <http://localhost:8025>.

### Pre-commit

```bash
pre-commit run --all-files
pre-commit autoupdate
```

Hooks: trailing whitespace, EOF fixer, YAML check, large-file check, `ruff` + `ruff format --check` on `^src/.*\.py$`, and local `npx eslint` / `npx prettier --check` on `^src/frontend/src/.*`.

---

## Project layout

```
.
├── .claude/                  # shared PLANEKS CLAUDE templates + this project layer
├── .github/workflows/        # ci.yml, deploy-reusable.yml, {dev,staging,production}_deploy.yml
├── ansible/                  # provisioning: roles common/docker/github_actions/monitoring/backup
├── data/                     # local volumes — gitignored
├── docker/                   # django/, frontend/, postgres/, caddy/, mkdocs/
├── docs/                     # MkDocs sources
├── scripts/                  # deploy.sh, backup.sh, health-check.sh, provision-server.sh, init_production_volumes.sh
├── src/
│   ├── manage.py · pyproject.toml · poetry.lock · .python-version
│   ├── config/               # settings/{base,dev,prod,test}.py, urls.py, celery.py, wsgi.py, asgi.py, templates/, static/
│   ├── accounts/             # custom User (AUTH_USER_MODEL), SSR views/forms + api/ (DRF) + tests/
│   ├── core/                 # IndexView, middleware, management/commands/
│   └── frontend/             # Django app (views, templatetags, templates) + React/Vite project
│       ├── package.json · vite.config.js · vitest.config.js · eslint.config.js · .prettierrc
│       └── src/              # App.jsx, index.jsx, setup/{sentry,i18n,icons}.js, locales/, __tests__/
├── compose.dev.yml · compose.prod.yml
├── dev.env · prod.env        # templates; copy to .env (gitignored)
└── .pre-commit-config.yaml
```

### URL map

`/` (SPA shell) · `/superadmin/` (admin) · `/api/token/` + `/api/token/refresh/` (JWT) · `/api/schema/` · `/api/docs/` (Swagger) · `/api/redoc/` · `/__debug__/` (dev only).

### Adding a new Django app

```bash
docker compose -f compose.dev.yml run --rm django manage startapp <name>
```

Mirror the `accounts/` layout: create `src/<name>/api/` for DRF code from day one, `src/<name>/tests/` for tests, and register the app in `src/config/settings/base.py`.

---

## Environment variables

Authoritative list: `dev.env` / `prod.env` (both carry the same keys). Copy to `.env`, which is gitignored.

`PYTHONENCODING` · `DEBUG` · `CONFIGURATION` · `DJANGO_SETTINGS_MODULE` · `DJANGO_LOG_LEVEL` · `SECRET_KEY` · `ALLOWED_HOSTS` · `SITE_URL` · `SITE_DOMAIN` · `COMPOSE_PROJECT_NAME` · `POSTGRES_HOST` · `POSTGRES_PORT` · `POSTGRES_DB` · `POSTGRES_USER` · `POSTGRES_PASSWORD` · `REDIS_URL` · `EMAIL_HOST` · `EMAIL_PORT` · `EMAIL_HOST_USER` · `EMAIL_HOST_PASSWORD` · `CELERY_FLOWER_USER` · `CELERY_FLOWER_PASSWORD` · `CADDY_PASSWORD` · `SENTRY_DSN` · `VITE_DEV_SERVER_HOST`

Also read by settings but absent from the env templates: `PROJECT_NAME`, `INTERNAL_IPS`, `CSRF_TRUSTED_ORIGINS`. Caddy uses `CADDY_USER` (default `admin`).

When introducing a new env var: add it to **both** `dev.env` and `prod.env` with a placeholder, read it via `python-decouple` in `src/config/settings/base.py` with a safe default, and document it in `docs/`. Never commit real values.

---

## CI / CD

`.github/workflows/ci.yml` runs on PRs to `develop` / `staging` / `main`:

1. `check_migration_conflicts` (PRs only) — duplicate migration numbers vs the base branch.
2. `lint-backend` — `ruff check`, `ruff format --check`, `pip-audit` (non-blocking).
3. `lint-frontend` — `npm run lint`, `npm run format:check`, `npm audit` (non-blocking).
4. `test-backend` — builds the dev image, `run --rm django test`. Skipped when the PR targets `develop`.
5. `test-frontend` — `npm test` then `npm run build`. Skipped when the PR targets `develop`.

Deploys: push to `develop` → dev (no CI gate) · `staging` → CI then `compose.prod.yml` · `main` → manual approval + CI then prod. All go through `scripts/deploy.sh` over SSH.

Don't bypass CI by force-pushing. Fix the root cause.

---

## Deployment

See `docs/deployment_automated.md`, `docs/deployment_manual.md`, `docs/github-actions-setup.md`.

- Provisioning: `ansible/playbooks/provision.yml` or `./scripts/provision-server.sh <aws|digitalocean> <env> <ip>`.
- Deploy: `scripts/deploy.sh` — invoked by CI, **not manually from a laptop**.
- Backups: `scripts/backup.sh` (cron on the host); media backup via `--media`.
- Health: `scripts/health-check.sh`. TLS: Caddy + Let's Encrypt.

---

## Working with this codebase — quick rules

1. **All Python and Node commands run inside Docker.** No `pip install` / `npm install` / `python manage.py` on the host.
2. **Always `-f compose.dev.yml`.** There is no default compose file; omitting `-f` can silently target the wrong stack.
3. **Prefer the entrypoint verbs** (`manage`, `test`, `add`) over raw commands — they set the venv, user, and settings module for you.
4. **API code in `src/<app>/api/`, SSR code at `src/<app>/` top level.** DRF imports never appear outside `api/`.
5. **Settings are split** (`base` + `dev`/`prod`/`test`). New settings go in `base.py` with an env default.
6. **Ruff is the only Python linter/formatter**; ESLint + Prettier are the only JS ones.
7. **Frontend assets go through `{% vite_asset %}`**, never hardcoded `/static/` paths.
8. **Migrations:** one per logical change, reviewed before commit, renumbered on conflict.
9. **Celery:** dispatch with `transaction.on_commit(lambda: task.delay(...))`; keep tasks idempotent.
10. **Don't disable pre-commit or CI checks.**

---

## Anti-patterns specific to this boilerplate

- `pip install` instead of `poetry add` → package lands in the image but not in `poetry.lock`.
- Running `python manage.py` from `src/` on the host → appears to work until it can't reach Postgres/Redis.
- Omitting `-f compose.dev.yml` and hitting the prod stack.
- Editing files inside the container — `./src` is bind-mounted; edit on the host.
- Putting secrets in `dev.env` / `prod.env` (they're committed templates) instead of `.env`.
- DRF views in `<app>/views.py` instead of `<app>/api/views.py`.
- Adding a second static-asset pipeline alongside Vite, or referencing `dist/` paths directly in templates.
- Leaving `NEWPROJECTNAME` in a forked project.
- Running `pytest` without `DJANGO_SETTINGS_MODULE=config.settings.test` and wondering why it hits the dev DB.
