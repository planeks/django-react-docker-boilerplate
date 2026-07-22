# Agent instructions

Permanent context for AI coding agents (Claude Code, OpenAI Codex, and others) working in this repo. Task-specific detail lives in the skills under `.agents/skills/` — read the relevant one before starting; do not duplicate its content here.

## Stack

Django 5.1 + DRF (Poetry, Python 3.12) in `src/`; Celery 5.3 + redbeat on Redis; PostgreSQL. React 18 in `src/frontend/` — **plain JavaScript/JSX, no TypeScript** — built with Vite, tested with Vitest. Everything runs in Docker via `compose.dev.yml`. Ruff is the only Python linter/formatter; the frontend uses ESLint + Prettier. There is no typecheck step.

## Main directories

- `src/config/` — settings (`settings/{base,dev,prod,test}.py`), root urls, celery.
- `src/accounts/` — the one domain app; the reference example for the API pattern (`accounts/api/`).
- `src/core/` — middleware, management commands.
- `src/frontend/` — React app; entry `src/frontend/src/index.jsx`.
- `docs/` — MkDocs. Start with `docs/architecture/repository-map.md`.

## Commands

Bring the stack up first: `cp dev.env .env` (once), then `docker compose -f compose.dev.yml up -d`.

```bash
# Backend
docker compose -f compose.dev.yml exec django ruff check .
docker compose -f compose.dev.yml exec django ruff format --check .
docker compose -f compose.dev.yml run --rm django test
docker compose -f compose.dev.yml exec django python manage.py makemigrations
docker compose -f compose.dev.yml exec django python manage.py migrate
docker compose -f compose.dev.yml exec django python manage.py spectacular --file schema.yml

# Frontend
docker compose -f compose.dev.yml exec frontend npm run lint
docker compose -f compose.dev.yml exec frontend npm run format:check
docker compose -f compose.dev.yml exec frontend npm test
docker compose -f compose.dev.yml exec frontend npm run build

# Narrowest sufficient checks for the current diff
scripts/check-changes.sh
```

## Working rules

- **Find the nearest similar implementation first.** Follow existing patterns instead of inventing new ones. `src/accounts/api/` is the model for API code. There is no service/selector layer — logic lives in DRF views + model managers. DRF uses generic class-based views + explicit `path()`, not ViewSets.
- **Narrowest sufficient verification.** Match checks to what changed; run focused tests before the full suite (`scripts/check-changes.sh`, or the `verify-change` skill). Never claim a command passed unless it ran.
- **Generated files policy.** Never hand-edit generated output: Django `migrations/` (regenerate with `makemigrations`), any committed OpenAPI `schema.yml` (regenerate with `spectacular`), the Vite `dist/` bundle. There is no generated frontend API client.
- **External docs.** Check the installed version (`src/pyproject.toml`, `src/frontend/package.json`) and look for an in-repo example before reaching out. Use Context7 or official docs only for unfamiliar, recently-changed, or version-sensitive APIs, and ask for the specific symbol/topic. Repo conventions beat generic examples. Do not auto-install Context7 or add secrets.
- Follow `CONTRIBUTING.md`: Conventional Commits, branch prefixes (`feature/`, `bugfix/`, `hotfix/`, `task/`). Do not push, merge, or deploy on the user's behalf.

## Skills

Read the matching skill in `.agents/skills/` before the work: `django-backend`, `react-frontend`, `api-contract-change`, `verify-change`, `write-project-docs`, `context-efficient-work`, `concise-engineering-output`, `systematic-debugging`. See `.agents/skills/README.md` for the index. Claude Code loads them from `.claude/skills/` (symlinks to `.agents/skills/`).
