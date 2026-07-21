# AGENTS.md — backend (`src/`)

Django/Python rules. Adds to the root `AGENTS.md`; `src/frontend/` has its own file that
overrides this one for React code. Full standards: `.claude/CLAUDE_python.md`,
`.claude/CLAUDE_django.md`, `.claude/CLAUDE_architecture.md`.

## Deviations from the shared templates — this repo wins

| Template says | Here | Why |
|---|---|---|
| apps under `apps/<app>/` | apps at `src/<app>/` | boilerplate layout, keep it |
| API routes `/api/v1/<app>/` | `/api/…`, no version segment | add versioning when a real external consumer appears |
| Black + isort + flake8 | **Ruff only** (lint *and* format) | one tool, config in `pyproject.toml` |

## API vs SSR isolation (mandatory)

DRF code lives **only** in `src/<app>/api/` — views, serializers, permissions, routers, filters.
Top-level `views.py` / `forms.py` / `templates/` are the SSR surface. Neither imports the other;
both call the same `services.py` / `selectors.py`. A `from rest_framework import …` outside
`api/` is a bug — move it.

Business logic goes in `services.py` (writes) and `selectors.py` (reads), not in views,
serializers, or models. Models hold data and invariants.

New app: `… run --rm django manage startapp <name>`, mirror `accounts/` (create `api/` and
`tests/` from day one), register it in `config/settings/base.py`.

## Settings

Split: `config/settings/base.py` + `dev.py` / `prod.py` / `test.py`, selected by
`DJANGO_SETTINGS_MODULE`. New settings go in `base.py` with an env default via
`python-decouple`, overridden per environment only when they must differ.

## Migrations

```bash
docker compose -f compose.dev.yml run --rm django manage makemigrations
docker compose -f compose.dev.yml run --rm django manage migrate   # also run by the dev entrypoint
```

One migration per logical change. **Read the generated file before committing.** CI fails a PR
that introduces a duplicate migration number for an app — rebase and renumber, never rewrite an
applied migration.

## Tests

```bash
docker compose -f compose.dev.yml run --rm django test                                    # full suite
docker compose -f compose.dev.yml run --rm django bash -c \
  "DJANGO_SETTINGS_MODULE=config.settings.test pytest -x accounts/"                       # subset
```

pytest, never `manage.py test`. There is no `pytest.ini` or `conftest.py` — the `test` verb is
what exports the settings module, so **a bare `pytest` runs against the dev database**. Always
export it yourself when you bypass the verb.

App tests in `src/<app>/tests/`, API tests in `src/<app>/api/tests.py` (match `accounts/`).

## Dependencies

```bash
docker compose -f compose.dev.yml run --rm django add <package>
docker compose -f compose.dev.yml exec django poetry add --group dev <package>
docker compose -f compose.dev.yml build django    # rebuild after any change
```

Poetry only — `pip install` lands in the image but not in the lock file. Commit **both**
`pyproject.toml` and `poetry.lock`.

## Lint & format

```bash
docker compose -f compose.dev.yml exec django ruff check --fix .
docker compose -f compose.dev.yml exec django ruff format .
```

Config in `pyproject.toml`: `select = ["ALL"]` with a documented ignore list, per-file ignores
for settings/tests/middleware/urls, `migrations` excluded. Don't add `# noqa` or widen the
ignore list ad-hoc — propose the change in a PR.

## Celery

Tasks in `<app>/tasks.py`, `@shared_task`, idempotent, with explicit `time_limit` /
`soft_time_limit`. Pass **IDs, not ORM objects**, and refetch inside the task. Dispatch after
commit:

```python
transaction.on_commit(lambda: send_invite.delay(user.id))
```

## ORM

`select_related` / `prefetch_related` against N+1. Aggregate in the database, not in Python.
Wrap multi-step writes in `transaction.atomic()`. Bulk operations bypass signals and `save()` —
know that before using them. Never build SQL with f-strings.
