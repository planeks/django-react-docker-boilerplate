# Repository map

A compact orientation for finding code fast. For the running-container view, see the C4 diagram in `docs/index.md`; for commands, `docs/code-quality.md`.

## Components

| Component | Responsibility | Runs as (dev) |
|-----------|----------------|---------------|
| Django (`src/`) | HTTP API + server-rendered shell, admin, auth (JWT) | `django` service, port 8000 |
| Celery worker/beat | Async tasks + scheduling (redbeat) | `celeryworker`, `celerybeat` |
| PostgreSQL | Application database | `postgres` |
| Redis | Celery broker + result backend | `redis` |
| React (`src/frontend/`) | Frontend, built by Vite, mounted into Django templates | `frontend` (Vite dev server, 5173) |
| Caddy | Reverse proxy / TLS (prod; opt-in in dev) | `caddy` |
| MkDocs | These docs | `mkdocs`, port 8050 |
| MailHog / Flower | Dev email capture (8025) / task monitor (5555) | `mailhog`, `flower` |

## Entry points

- WSGI/ASGI: `src/config/wsgi.py`, `src/config/asgi.py`. Settings: `src/config/settings/{base,dev,prod,test}.py`.
- URL root: `src/config/urls.py` → per-app `src/<app>/urls.py` → API routes in `src/<app>/api/router.py`.
- Celery app: `src/config/celery.py`. Management CLI: `src/manage.py` (usually via the entrypoint `manage` subcommand).
- Frontend: `src/frontend/src/index.jsx`; Django integration via `src/frontend/templatetags/vite_tags.py` reading the Vite manifest.

## Apps

- `accounts` — the only domain app. Registration, JWT login/logout, profile, password change, email activation. Full worked example of the API pattern in `src/accounts/api/`.
- `core` — middleware, management commands (`clear_cache`), shared views. No models.
- `config` — project package: settings, celery, root urls.
- `frontend` — Django app that serves the Vite-built React bundle.

## Where to find a typical implementation

- **An API endpoint** (view + serializer + permissions + task dispatch + JWT + OpenAPI annotations): `src/accounts/api/views.py`, `serializers.py`, `router.py`.
- **A model with a custom manager**: `src/accounts/models.py` (`UserManager`).
- **A Celery task**: `src/accounts/tasks.py` (`@shared_task`, called with `.delay()`).
- **A backend test**: `src/accounts/tests/test_models.py` (`TestCase`), `src/accounts/api/tests.py` (`APITestCase`).
- **Settings split / third-party config** (DRF, SimpleJWT, drf-spectacular, Celery): `src/config/settings/base.py`.
- **A frontend test**: `src/frontend/src/__tests__/App.test.jsx` (Vitest + React Testing Library).

## Key dependencies

Backend: Django 5.1, DRF 3.15, drf-spectacular, djangorestframework-simplejwt, Celery 5.3 + celery-redbeat, psycopg2, sentry-sdk. Declared in `src/pyproject.toml` (Poetry).
Frontend: React 18, Vite 5, Vitest 2, react-i18next, @sentry/react, FontAwesome. Declared in `src/frontend/package.json` (npm). Plain JavaScript/JSX — no TypeScript.

## Conventions cheat sheet

- No service/selector layer — logic lives in DRF views + model managers.
- DRF generic class-based views + explicit `path()`; no ViewSets/routers.
- Ruff is the only Python linter/formatter; frontend uses ESLint + Prettier. No typecheck step.
- Tests run under pytest-django but are written as Django `TestCase`/`APITestCase`.
- Everything runs through `docker compose -f compose.dev.yml ...`.
