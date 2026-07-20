# AGENTS.md

Instructions for AI coding agents (Codex, Cursor, Copilot, Gemini CLI, Claude Code, …)
working in this repository.

> **Generated file — do not edit by hand.**
> Sources live in `.claude/`; regenerate with `./scripts/build-agents-md.sh` after changing them.
> Claude Code reads the same content via `CLAUDE.md`, which imports those sources directly.

Sections are ordered general → specific. Where two sections conflict, **the later one wins** —
the project layer at the end is authoritative for this repository.

## Contents

1. [PLANEKS Base Standards](#planeks-base-standards)
2. [Python](#python-planeks)
3. [Django](#django-planeks)
4. [React](#react-planeks)
5. [Architecture](#architecture-planeks)
6. [django-react-docker-boilerplate](#django-react-docker-boilerplate-planeks) — this project


---

# PLANEKS Base Standards

> **Scope:** Code-level standards Claude must apply when writing or editing code in any PLANEKS project. Layer framework-specific files (Python/Django/Flask/FastAPI/React) on top.
>
> Human-level policy (client reporting, hosting choices, backups, on-call, etc.) lives in the team wiki, not here — it doesn't change what Claude writes.

---

## Language & naming

- **English only.** All names of files, variables, functions, parameters, classes, methods, comments, data structures, DB fields/tables, branches, commit messages, and code documentation must be English. No exceptions.
- Descriptive and meaningful names. Prefer short over long, but never sacrifice readability.
  - Good: `calculate_total_price`. Bad: `calc_price`.
- Language-specific casing rules live in framework files.

## Code formatting

- **Max line length: 120 chars.**
- Consistent indentation, spacing, and bracket placement.
- Always run the project's configured linter/formatter before completing a task. Match the existing config (`pyproject.toml`, `.eslintrc`, etc.) — never override it ad-hoc.
- Don't bypass pre-commit hooks (no `--no-verify`). If a hook fails, fix the underlying issue.

## Comments

- Document **why**, not how. The code shows how; the comment explains intent or a non-obvious constraint.
- No emotional commentary, jokes, or remarks about previous code quality.
- Split long functions (50+ lines) into smaller blocks with intent comments per block where helpful.
- When deviating from a standard (PEP 8, naming, etc.) — leave a one-line comment with the reason.
- When using code/algorithm from an external source (GitHub gist, article), add a reference comment.
- `# TODO:` for temporary or simplified solutions that need revisiting. Don't leave silent shortcuts.

## Docstrings

- Every public function, class, and module gets a docstring.
- Cover purpose, args, returns, raises (or framework equivalent). Style is set per project — match what's already in the file.

## Project docs alongside code

When a change affects setup, public API, or architecture:

- Update the README (setup instructions, env vars, new commands, new dependencies).
- Update API docs (OpenAPI annotations, GraphQL schema descriptions, generated reference).
- For significant architectural changes, add or update an ADR if the project keeps them.
- Doc updates go in the **same commit/PR** as the code change — never "I'll do it later."

## Error handling

- Catch **specific** exception types. No bare `except` / `catch (Throwable)`.
- Log with context (`logger.exception(...)` inside `except` to capture the traceback).
- Don't suppress exceptions to make tests pass or "stabilize" a path. Fix the root cause.

```python
try:
    value = dictionary['key']
except KeyError as e:
    logger.error(f"KeyError: {e}")
```

## Git

When Claude creates branches or commits via `git` / `gh`:

- **Branches:** `feature/<short-desc>`, `fix/<short-desc>`, `hotfix/<short-desc>`. Include the Jira/Trello ticket tag if there is one. Keep names short.
- **Commits:** atomic — one logical change per commit. Conventional format, ≤ 72 chars for the subject:
  - `feat: Add new authentication method`
  - `fix: Handle null user in profile view`
- **Pull requests** (when created via `gh pr create`):
  - **Title:** the conventional commit subject.
  - **Body:** 1–3 bullet summary of what changed, link to the Trello/Jira ticket if there is one, brief test plan.
  - If the reviewer can't access the ticket tracker, put a short summary in the body instead of just the link.
- **Never commit:** compiled artifacts, third-party libs (use the project's package manager), commented-out "dead" code, `.env`, secrets.

## Testing

- Write/update tests for every code change. Cover the happy path, the obvious edge cases, and any branch you just added.
- Test framework, layout, and runner are defined per project — match what exists. Don't introduce a new test framework unilaterally.
- Mock external services (HTTP, queues, third-party APIs) in unit tests. Use the project's existing mocking conventions.

## Secrets & configuration

- **No hardcoded secrets, API keys, URLs, or passwords.** Read them from environment variables (`os.environ`, `import.meta.env`, etc.).
- If `.env.example` exists, add a placeholder line there for every new env var you introduce.
- Passwords are hashed with bcrypt / argon2 via the framework's recommended lib — never stored in plaintext.

## Security defaults (code-level)

Apply these whenever Claude touches the relevant code paths:

- **SQL:** parameterized queries / ORM only. Never f-string SQL.
- **Output:** rely on the template engine's auto-escape. Use `|safe` / `dangerouslySetInnerHTML` only on content you've verified.
- **HTTP input:** validate at the boundary (serializers / schemas). Don't trust client data.
- **CSRF:** keep it on for cookie-based sessions; not needed for stateless tokens in `Authorization` headers.
- **File uploads:** validate type and size; store outside the app process (cloud storage), not on local disk.
- **CORS:** never combine `allow_origins=["*"]` with `allow_credentials=True`.
- **Dependencies:** if a new package is requested, prefer the project's existing patterns (e.g. `django-anymail` for email, `django-axes` for brute-force protection) over inventing wiring from scratch.

## When in doubt

1. **Read the existing code first.** Match the conventions you find — even if your preference differs.
2. **Don't bypass safety checks** (pre-commit, linter, tests, CI) to move faster. Diagnose and fix.
3. **Don't add abstractions for hypothetical future needs.** Solve the task in front of you.
4. **State assumptions in PR descriptions** when Claude generates them, so reviewers can challenge them.

---

# Python (PLANEKS)

> Layer this on top of the `CLAUDE_base` section of this file. Framework files (Django/Flask/FastAPI) layer on top of this.

---

## Style & formatting

- **PEP 8** is the baseline. Use the official Python style guide for anything not specified here.
- **Casing:**
  - `snake_case` — variables, functions, methods, modules, packages
  - `CapitalizedWords` (PascalCase) — classes, exceptions
  - `UPPER_SNAKE_CASE` — constants
  - `_leading_underscore` — internal/private; `__double_leading` — name-mangled (avoid unless you know why)
- **Tools (run before commit):**
  - `flake8` — linting
  - `isort` — import ordering
  - Configure both in `pyproject.toml` or `setup.cfg`. Match the team's existing config.
- Line length 120 chars (override PEP 8's 79).

## Imports

- Order via `isort`: stdlib → third-party → first-party → local relative.
- Prefer absolute imports inside packages. Avoid `from module import *`.
- No unused imports — `flake8` will catch them.

## Type hints

- Use type hints on public functions/methods and on anything non-trivial.
- For complex types: `from typing import ...` or PEP 604 (`X | None`) on Python 3.10+.
- Run `mypy` if the project has it configured. Don't add it unilaterally — coordinate with the team.

## Docstrings

- Every public function, class, and module gets a docstring.
- Use **Google** or **NumPy** style — pick one and stick to it project-wide.
- Cover: purpose, args, returns, raises, side effects.

```python
def calculate_total_price(items: list[Item], discount: float = 0.0) -> Decimal:
    """Calculate cart total after applying a discount.

    Args:
        items: Cart items to total.
        discount: Fractional discount (0.0–1.0).

    Returns:
        Final price as Decimal.

    Raises:
        ValueError: If discount is outside [0, 1].
    """
```

## Error handling

- **No bare `except`.** Always catch specific exception types.
- Log the exception with context. Use `logger.exception(...)` inside `except` to capture the traceback.
- Don't use exceptions for control flow if a conditional works.
- Define custom exception classes for domain-specific errors. Inherit from a base project exception.

## Logging

- Use the stdlib `logging` module. Get a logger via `logger = logging.getLogger(__name__)`.
- Never `print()` for production code. `print` is for one-off scripts only.
- Don't log secrets, tokens, PII, or raw request bodies that may contain them.

## Dependencies & environments

- Pin dependencies. Use `requirements.txt` + `requirements-dev.txt`, or `pyproject.toml` with **Poetry** / **uv** / **pip-tools** — match the project's choice.
- **Never** commit `venv/`, `.env`, `*.pyc`, or build artifacts.
- One virtual env per project. Document the Python version in README.

## Configuration

- All config via environment variables. Use `python-dotenv` or `pydantic-settings` to load.
- Never hardcode URLs, secrets, API keys.
- Provide `.env.example` with placeholder values committed to the repo.

## Testing

- Default framework: **pytest** (preferred) or **unittest**.
- Test layout: `tests/` mirrors the package structure, or `test_*.py` next to source — match project convention.
- Aim for high coverage on business logic and edge cases. Use `pytest-cov` to track.
- Fixtures via `conftest.py`. Parametrize with `@pytest.mark.parametrize`.
- Mock external services (HTTP, DB, queues) with `unittest.mock` or `pytest-mock`. Use `responses` / `httpretty` / `respx` for HTTP.
- Keep tests fast and deterministic. Mark slow/integration tests with custom markers.

## Concurrency

- Choose deliberately: threads for I/O-bound + blocking libs, `asyncio` for I/O-bound + async libs, `multiprocessing` for CPU-bound.
- Don't mix `asyncio` and blocking I/O inside the same coroutine without `run_in_executor`.

## Performance

- Profile before optimizing (`cProfile`, `py-spy`, `line_profiler`).
- Database queries are usually the bottleneck — see framework-specific files for ORM N+1 guidance.
- Prefer generators / iterators over building large lists in memory.

## Security

- Validate and sanitize all external input.
- SQL: parameterized queries only — never f-string SQL. ORMs handle this.
- Passwords: hash with `bcrypt` / `argon2` (via `passlib` or framework auth). Never store plaintext.
- Secrets: env vars only. Use a secrets manager (AWS Secrets Manager / Vault) in production.
- Dependencies: run `pip-audit` before adding or upgrading deps; CI runs it on PRs.

## Project structure (typical)

```
project/
├── src/<package>/        # or just <package>/
│   ├── __init__.py
│   ├── domain/           # business logic, framework-agnostic
│   ├── infrastructure/   # DB, external services
│   ├── api/              # HTTP layer (framework-specific)
│   └── settings.py
├── tests/
├── scripts/              # one-offs, migrations helpers
├── .env.example
├── pyproject.toml
└── README.md
```

- Framework-specific layouts override this in their CLAUDE.md.

---

## Common pitfalls

- Mutable default args: `def f(x=[])` — use `None` and create inside.
- Catching `Exception` to hide real bugs.
- `os.path` instead of `pathlib.Path` for new code.
- Manual JSON parsing without validating shape — use Pydantic / dataclasses.
- Forgetting context managers (`with`) — file handles, DB sessions, locks leak otherwise.

---

# Django (PLANEKS)

> Layered on top of the `CLAUDE_base` section of this file and the `CLAUDE_python` section of this file.

---

## Project layout

```
project/
├── config/                       # settings, urls, wsgi/asgi
│   ├── settings/
│   │   ├── base.py
│   │   ├── dev.py
│   │   ├── prod.py
│   │   └── test.py
│   ├── urls.py                   # root URL conf — mounts SSR + api/v1/*
│   ├── wsgi.py
│   └── asgi.py
├── apps/
│   └── <app_name>/
│       ├── __init__.py
│       ├── apps.py
│       ├── models.py             # domain entities + invariants
│       ├── admin.py
│       ├── tasks.py              # Celery
│       ├── selectors.py          # read logic (framework-agnostic)
│       ├── services.py           # write / business logic (framework-agnostic)
│       ├── signals.py            # only if truly needed
│       │
│       ├── views.py              # server-rendered views (SSR) — optional
│       ├── urls.py               # SSR URL routes
│       ├── forms.py              # Django forms (SSR)
│       ├── templates/<app_name>/ # SSR templates
│       │
│       ├── api/                  # ── API LAYER — fully isolated from SSR ──
│       │   ├── __init__.py
│       │   ├── views.py          # or viewsets.py — DRF
│       │   ├── serializers.py
│       │   ├── urls.py           # mounted under /api/v1/<app_name>/
│       │   ├── permissions.py    # per-app permission classes
│       │   ├── filters.py        # DRF FilterSet classes
│       │   ├── pagination.py     # only if non-default
│       │   └── schemas.py        # OpenAPI overrides, if any
│       │
│       └── tests/
│           ├── __init__.py
│           ├── factories.py
│           ├── test_models.py
│           ├── test_services.py
│           ├── test_selectors.py
│           ├── test_views.py     # SSR tests
│           └── api/
│               ├── __init__.py
│               ├── test_views.py
│               └── test_serializers.py
├── manage.py
└── requirements/
```

- One Django app per bounded context. Keep apps small and focused.
- Business logic lives in `services.py` / `selectors.py`, **not** in views or models. Models hold data + invariants only.
- **Never mix API code with SSR code in the same module.** The `api/` subpackage is the only place DRF (`serializers`, `viewsets`, DRF `permissions`) lives.

## API vs SSR isolation (mandatory)

Each app has **two distinct presentation surfaces**, kept in separate modules so a change to one never silently affects the other:

| Concern              | API layer                              | SSR layer                       |
|----------------------|----------------------------------------|---------------------------------|
| Location             | `apps/<app>/api/`                      | `apps/<app>/` (top-level)       |
| Routing              | `apps/<app>/api/urls.py` → `/api/v1/<app>/...` | `apps/<app>/urls.py` → `/<app>/...` |
| Views                | DRF `APIView` / `ViewSet`              | Django `View` / `TemplateView`  |
| Input shape          | JSON via DRF serializers               | HTML forms via Django forms     |
| Auth                 | `permission_classes`, token/JWT        | `LoginRequiredMixin`, sessions  |
| Tests                | `tests/api/`                           | `tests/test_views.py`           |

### Rules

1. **Both layers call the same `services.py` / `selectors.py`.** Business logic is shared, presentation is not.
2. `api/` modules **never** import from `views.py`, `forms.py`, or `templates/`. SSR modules **never** import from `api/`.
3. DRF imports (`from rest_framework import ...`) appear **only** inside `api/`. If you see DRF in `views.py` — move it.
4. `serializers.py` lives in `api/` only. Don't reuse serializers as a generic "object → dict" tool elsewhere — use plain functions or dataclasses.
5. If an app is API-only (no SSR), keep the top-level `views.py` / `urls.py` / `templates/` absent. Don't create empty placeholders.
6. If an app is SSR-only, the `api/` directory simply doesn't exist for that app.
7. Root `config/urls.py` mounts each app's URLs twice (if both surfaces exist):
   ```python
   # config/urls.py
   urlpatterns = [
       path("admin/", admin.site.urls),
       # SSR
       path("users/", include("apps.users.urls", namespace="users")),
       # API
       path("api/v1/users/", include("apps.users.api.urls", namespace="users-api")),
   ]
   ```
8. Namespacing: SSR namespace = app name (`users`), API namespace = `<app>-api` (`users-api`). Reverse names stay distinct.

### When adding a new endpoint

- API endpoint → create/extend `apps/<app>/api/views.py` + `apps/<app>/api/serializers.py` + register in `apps/<app>/api/urls.py`.
- SSR page → create/extend `apps/<app>/views.py` + template + register in `apps/<app>/urls.py`.
- New business rule → goes into `services.py` / `selectors.py`, then **both** layers can use it.

## Settings

- Split settings: `base.py` + per-env overrides. Choose env via `DJANGO_SETTINGS_MODULE`.
- All secrets and env-specific values via env vars. Use `django-environ` or `pydantic-settings`.
- `DEBUG = False` in production. `ALLOWED_HOSTS` set explicitly.
- `SECRET_KEY` — env var, never committed.

## Models

- One model = one entity. Use abstract base models for shared fields (`created_at`, `updated_at`).
- Add `__str__` and `Meta.ordering` to every model.
- Choices: use `TextChoices` / `IntegerChoices`.
- Indexes: declare in `Meta.indexes` for any field used in lookups/joins.
- Constraints (uniqueness, checks): use `Meta.constraints` over signals.

## Migrations

- One migration per logical change. Review autogenerated migrations before committing.
- Never edit a migration after it's been applied to a shared environment — write a new one.
- Test migrations on a copy of prod data before deploying.
- For large tables: avoid blocking schema changes during business hours; use `RunPython` with `atomic = False` if needed.

## Querysets & ORM

- **Avoid N+1.** Use `select_related` (FK) and `prefetch_related` (reverse FK / M2M).
- Use `.only()` / `.defer()` for wide tables when you need only a few fields.
- Heavy aggregations → `.annotate()` + `.aggregate()`; don't compute in Python.
- For bulk ops: `bulk_create`, `bulk_update`, `update()`, `delete()` — but mind that they bypass signals and `save()`.
- Wrap multi-step writes in `transaction.atomic()`.

## Views

- Class-based views (CBV) for CRUD; function-based for one-off endpoints.
- For APIs use **Django REST Framework** (DRF). For GraphQL use **Strawberry** or **Graphene** (project's choice).
- Keep views thin — delegate to services/selectors.

### DRF specifics (lives only under `api/`)

- All DRF code (`ViewSet`, `Serializer`, `permission_classes`, `FilterSet`) goes in `apps/<app>/api/`.
- `ViewSet` + `Router` for resourceful APIs. Register the router in `apps/<app>/api/urls.py`.
- Serializers validate input and shape output. Don't put business logic in serializers — call `services.py` from `create`/`update`.
- Permissions: per-view `permission_classes` or DRF global default. Never rely on UI to enforce access.
- Pagination: default class in settings. Don't return unpaginated lists.
- Throttling for public/auth-sensitive endpoints.

## URLs

- **SSR routes:** `apps/<app>/urls.py` with `app_name = "<app>"`, mounted at `/<app>/`.
- **API routes:** `apps/<app>/api/urls.py` with `app_name = "<app>-api"`, mounted at `/api/v1/<app>/`.
- Use `path()` with named patterns. Avoid regex unless necessary.
- API is **always** versioned: `/api/v1/...`. Bump the version, never break v1 silently.

## Forms & templates

- Server-rendered? Use Django forms with explicit field declarations. Avoid `Meta: fields = "__all__"` for security.
- Always escape user input — `{{ var }}` auto-escapes; use `|safe` only when you've verified the source.
- CSRF protection on by default — keep it on. Use `{% csrf_token %}` in forms.

## Admin

- Register models with custom `ModelAdmin`. Limit `list_display`, add `search_fields`, `list_filter`.
- For sensitive models: restrict `has_*_permission` instead of leaving defaults.
- Randomize the admin URL via an env var (e.g. `ADMIN_URL`); don't hardcode `admin/` in `urls.py` for production builds.

## Auth

- Custom `User` model from day one — even if you don't need it yet. Extend `AbstractBaseUser` / `AbstractUser`.
- Permissions: prefer object-level via `django-guardian` if RBAC isn't enough.
- Sessions for SSR; tokens (DRF token, JWT via `djangorestframework-simplejwt`) for APIs.

## Celery (async tasks)

- Place tasks in `<app>/tasks.py`. Decorate with `@shared_task` for app-independence.
- Tasks must be idempotent — they will retry.
- Pass IDs, not ORM objects (objects can be stale or unpickleable). Refetch inside the task.
- Set explicit `time_limit` and `soft_time_limit`. Configure retries with backoff.
- Use **Redis** as broker by default; **RabbitMQ** when ordering/durability requires it.

## Caching

- Use `django.core.cache` with **Redis** backend.
- Cache invalidation: prefer short TTLs + explicit invalidation on writes. Avoid manual key juggling.
- Don't cache user-specific data without including the user in the key.

## Static & media files

- `collectstatic` in deploy. Serve with **WhiteNoise** for small apps, **Nginx/Caddy** + cloud storage (S3) for larger ones.
- User uploads (media) → cloud storage in production (`django-storages` + S3). Never local disk in containers.

## Testing

- **pytest-django** preferred. Use `@pytest.fixture` + factories (`factory_boy`) over Django's `TestCase` when possible.
- Factories per model in `tests/factories.py`.
- `pytest.mark.django_db` for DB access. Use `transactional_db` only when needed.
- Don't hit external services — mock with `responses` / `respx`.
- Test what users do: views/APIs end-to-end; unit-test services/selectors directly.

## Security

- `django-axes` or similar for brute-force protection.
- `SECURE_*` settings in production: `SECURE_SSL_REDIRECT`, `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`, `SECURE_HSTS_SECONDS`.
- Run `python manage.py check --deploy` before going to prod.

## Performance

- `django-debug-toolbar` in dev to catch slow queries and N+1.
- `django-silk` for ad-hoc production profiling (gate behind auth).
- Database connection pooling: `CONN_MAX_AGE` or `pgbouncer`.

---

## Anti-patterns

- **Mixing API and SSR code in the same module** — DRF serializers in `views.py`, or template rendering in `api/views.py`. Move them to their correct layer.
- Importing `apps.<app>.api.*` from outside the `api/` package (other than root `urls.py`). The API layer is a presentation detail, not a service.
- Sharing DRF serializers as a generic "model → dict" helper across the codebase — use plain functions or dataclasses for that.
- Fat models with business logic that touches multiple apps.
- Signal handlers that hide write paths — explicit service calls are easier to reason about.
- `objects.all()` in templates / serializers — always paginate or filter.
- Putting Celery tasks inline (`task.delay()`) inside a transaction — they may fire before the commit; use `transaction.on_commit(lambda: task.delay(...))`.
- Catching `Exception` in views to "make it work" — fix the root cause.

---

# React (PLANEKS)

> Layered on top of the `CLAUDE_base` section of this file.

---

## Stack defaults

- **Language:** TypeScript (preferred over plain JS). Strict mode on.
- **Build tool:** Vite (preferred for new projects). Next.js if SSR/SSG is needed. CRA only for legacy.
- **Styling:** project's choice — Tailwind, CSS Modules, styled-components, or SCSS. Pick one and stick to it.
- **HTTP client:** `fetch` + a thin wrapper, or **TanStack Query** / **RTK Query** for server state.
- **Forms:** **react-hook-form** + **zod** for validation.
- **Routing:** **React Router** (SPA) or Next.js routing.
- **Testing:** **Vitest** (or Jest) + **React Testing Library**, **Cypress** / **Playwright** for E2E.

## Style guide

- **Airbnb JavaScript Style Guide** + standard React rules (per PLANEKS base standards).
- **Lint:** ESLint with `eslint-config-airbnb` (or `@typescript-eslint` + `eslint-plugin-react` + `eslint-plugin-react-hooks`).
- **Format:** Prettier. Pre-commit hook (`lint-staged` + `husky`).
- Don't disable rules ad-hoc — discuss in the team if a rule fights the codebase.

## Naming

- Components: **PascalCase** files and exports: `UserCard.tsx` exports `UserCard`.
- Hooks: `use*` camelCase: `useUserProfile`.
- Variables/functions: camelCase.
- Constants: `UPPER_SNAKE_CASE`.
- Types/interfaces: PascalCase. Don't prefix interfaces with `I` (TypeScript convention).
- Booleans: `isLoading`, `hasError`, `canSubmit`.

## Project structure

```
src/
├── app/                       # app shell, providers, routing
├── pages/ or routes/          # route-level components
├── features/<feature>/        # feature-scoped: components, hooks, api, store
│   ├── components/
│   ├── hooks/
│   ├── api.ts
│   └── types.ts
├── components/                # shared UI primitives
├── hooks/                     # shared hooks
├── lib/                       # third-party wrappers, helpers
├── store/                     # global state (Redux/Zustand)
├── styles/
├── types/                     # global types
└── main.tsx
```

- **Feature-first** layout for medium+ apps. `src/components` is for genuinely shared primitives, not a dumping ground.
- Co-locate tests next to source: `UserCard.test.tsx` next to `UserCard.tsx`.

## Components

- **Functional components + hooks only.** No class components in new code.
- One component per file (unless tightly coupled and private).
- Keep components small. If a component does too much → extract custom hooks for logic, child components for UI.
- Props typed with TypeScript interfaces. Destructure props in the signature.
- Don't mutate props or state directly — always produce new references.

```tsx
interface UserCardProps {
  user: User;
  onEdit?: (id: string) => void;
}

export function UserCard({ user, onEdit }: UserCardProps) {
  return (
    <article>
      <h3>{user.name}</h3>
      {onEdit && <button onClick={() => onEdit(user.id)}>Edit</button>}
    </article>
  );
}
```

## Hooks

- Follow the rules of hooks: call at the top level only, never in conditionals/loops.
- Custom hooks for reusable logic, not just for "moving code out of a component."
- `useEffect` is for **synchronizing with external systems**. For derived state, compute during render or use `useMemo`.
- Always provide the dependency array. Let `eslint-plugin-react-hooks` guard it — don't disable the rule.
- Cleanup side effects (subscriptions, timers, listeners) in the returned function.

## State management

- **Local state** (`useState`, `useReducer`) by default.
- **Context** for cross-cutting *low-frequency* state (theme, auth, locale). Don't use Context as a global store — it re-renders all consumers.
- **Server state**: **TanStack Query** or **RTK Query** — handles caching, dedup, retries, invalidation.
- **Client global state**: **Redux Toolkit** (large/team projects), **Zustand** (smaller/simpler).
- Don't put server data in Redux unless you have a clear reason — let TanStack Query own it.

## Data fetching

- Centralize API calls in a `features/<x>/api.ts` module. Components call hooks, hooks call API functions.
- Handle loading, error, and empty states explicitly — every async UI has at least three states.
- Cancel in-flight requests on unmount (TanStack Query handles this; if using raw fetch, use `AbortController`).
- Don't fetch inside `useEffect` if a data-fetching lib is available — use that lib.

## Forms

- **react-hook-form** + **zod** for schemas. One schema = validation + TypeScript types.
- Controlled vs uncontrolled: prefer uncontrolled with `react-hook-form` for performance.
- Disable submit while pending. Show field-level errors inline.
- Re-validate on blur and submit, not on every keystroke (unless UX demands).

## Performance

- Profile before optimizing — React DevTools Profiler.
- `useMemo` / `useCallback` for expensive computations or referential equality across renders. Don't sprinkle them defensively.
- `React.memo` for components that re-render often with the same props.
- Lazy-load route components with `React.lazy` + `Suspense`.
- Virtualize long lists (`react-window`, `@tanstack/react-virtual`).
- Image optimization: lazy-loading, responsive `srcset`, WebP/AVIF.

## Accessibility

- Semantic HTML first (`button`, `nav`, `main`, `article`). ARIA only when semantic HTML can't express the intent.
- Every interactive element is keyboard-navigable and focus-visible.
- Form fields have labels (`<label htmlFor>` or `aria-label`).
- Images have meaningful `alt` (or `alt=""` for decorative).
- Color contrast meets WCAG AA.

## Cross-browser & responsive

- Test on the project's supported browsers (define in `package.json` `browserslist`).
- Mobile-first CSS.
- Avoid hover-only interactions for primary actions — touch devices don't have hover.

## Testing

- **Unit / component tests:** Vitest + React Testing Library. Test behavior, not implementation.
  - Query by accessible role/text (`getByRole`, `getByLabelText`), not by class/id.
  - No snapshot-only tests — they catch nothing useful.
- **Integration:** mount the feature, mock the API (MSW), assert user flows.
- **E2E:** Cypress or Playwright for golden-path flows.
- Mock HTTP with **MSW** — works in tests and in dev.

## Error handling

- **Error boundaries** around route trees and async UI sections.
- Show a fallback UI; log to Sentry.
- Never `try/catch` to suppress errors silently.
- Server errors → map to user-friendly messages; show details only in dev.

## TypeScript

- Strict mode on (`strict: true` in tsconfig).
- Prefer `type` for unions/intersections, `interface` for object contracts that may be extended.
- Avoid `any`. Use `unknown` + narrowing when shape is uncertain.
- No `// @ts-ignore` without a comment explaining why and a TODO.

## Routing

- Route-level code splitting: lazy-load page components.
- Protect routes with a wrapper component (`<RequireAuth>`).
- Don't read auth state inside every page — read once at the route boundary.

## Configuration

- All env vars go through Vite's `import.meta.env.VITE_*` (or `process.env.NEXT_PUBLIC_*` for Next.js).
- Never put secrets in client code — anything shipped to the browser is public.
- Separate configs per environment (`.env.development`, `.env.production`).

## Security

- Sanitize HTML if you must render it — **DOMPurify**. Avoid `dangerouslySetInnerHTML`.
- Validate URLs before opening (no `javascript:` URLs).
- Store auth tokens carefully: HttpOnly cookies (preferred) > sessionStorage > localStorage (avoid for tokens if XSS is a concern).
- CSP headers (server-side) to limit attack surface.

## Build output

- Cache-bust via hashed filenames (Vite does this automatically). `index.html` short cache, assets long.
- Source maps in production: upload to Sentry but don't serve publicly.

---

## Anti-patterns

- Class components in new code.
- `useEffect` to derive state — compute it during render.
- Putting all state in Redux because "global is easier."
- `any` in TypeScript to silence the compiler.
- Fetching in `useEffect` without cleanup → stale state and warnings on unmount.
- Inline functions/objects in JSX as `React.memo` props (breaks memoization).
- `key={index}` on dynamic lists (breaks reconciliation when items reorder).
- Putting business logic in components — extract to hooks or plain functions.
- Disabling `eslint-plugin-react-hooks/exhaustive-deps` ad-hoc.

---

# Architecture (PLANEKS)

> Cross-cutting code-organization rules. Read alongside the framework-specific file.
> Operational concerns (hosting, CI policy, on-call, backups, SLOs) live in the team wiki — they don't change what Claude writes.

---

## Code principles

- **Boring is good.** Prefer well-understood, well-supported patterns over novel ones unless there's a concrete reason.
- **Don't over-engineer.** Solve the task in front of you; don't add abstractions for hypothetical future needs.
- **Make the implicit explicit.** Surface hidden coupling, magic config, and undocumented invariants in code and names — not in tribal knowledge.
- **Dependencies point inward.** Domain doesn't import from infrastructure. Presentation doesn't bypass services to hit the DB.

## Layers (typical web app)

```
┌──────────────────────────────────────────┐
│ Presentation (HTTP/UI)                   │  routes, controllers, components
├──────────────────────────────────────────┤
│ Application services                     │  use-cases, orchestration
├──────────────────────────────────────────┤
│ Domain                                   │  entities, business rules
├──────────────────────────────────────────┤
│ Infrastructure                           │  DB, queues, external APIs, FS
└──────────────────────────────────────────┘
```

- For small projects, collapse layers — don't invent ceremony you won't use.
- For medium+, keep them separate.

## Module boundaries

- Organize by **feature/domain**, not by layer alone. `users/`, `billing/`, `notifications/` — each owns its models, services, routes, tests.
- Cross-feature calls go through public service interfaces, not direct DB access into another feature's tables.
- Shared code → `core/` / `common/`. Pull something in only when it's used by 2+ features.

## Business logic placement

- **Services** own write paths (`create_order`, `charge_customer`, `send_invite`).
- **Selectors / queries** own read paths (list users with filters, dashboard aggregates).
- **Models / entities** hold data + invariants (validation that's always true regardless of caller).
- **Controllers / routes / views** translate HTTP ↔ services. They don't decide business rules.

## API design

- REST by default for CRUD. GraphQL when clients need flexible read shapes. gRPC for service-to-service in polyglot environments.
- **Version from day one:** `/api/v1/...`. Break only by bumping the version.
- **Pagination on every list endpoint.** Default page size, max page size, cursor or offset (cursor for large datasets).
- Filtering / sorting via query params with **allow-lists** — never accept arbitrary field names from the client.
- **Idempotency keys** on POSTs where retries could duplicate (payments, mutations).
- Status codes: 200 read, 201 create, 204 delete, 400 bad input, 401 auth missing vs 403 forbidden, 409 conflict, 422 validation.

## Data & persistence

- **SQL first.** Reach for NoSQL only when the access pattern doesn't fit SQL (graph, geo, full-text-only, time-series at scale).
- **PostgreSQL** is the default relational DB.
- Use **Redis** for caching, session storage, queues, rate limiting, ephemeral data.
- Use **MongoDB** when the data is genuinely document-shaped with evolving schema.
- **Migrations** for schema changes — never edit a production DB by hand.
- Design indexes with queries in mind, not afterwards. Check query plans on slow queries.
- Soft delete vs hard delete: pick one per entity and apply it consistently.

## Caching

Cache invalidation is the hard part. Prefer in this order:

1. **Short TTLs** (seconds–minutes) when mild staleness is acceptable.
2. **Explicit invalidation on writes** when staleness isn't acceptable.
3. **Versioned cache keys** to avoid stale reads after deploys.

- Never cache user-specific data without including the user in the key.
- For HTTP, use `ETag` / `Cache-Control` for cacheable GETs.

## Async / background work

- HTTP handlers should return fast. Anything > ~1s of work → background job.
- Tasks must be:
  - **Idempotent** — they will retry.
  - **Small** — one logical action.
  - **Logged** with a correlation ID.
- Dispatch **after** the DB commit (`transaction.on_commit` in Django, equivalent in other frameworks) — otherwise the worker may read stale state from a replica.
- Pass IDs to tasks, not ORM objects (objects detach from sessions and may be stale).

## Multi-tenancy

When the app serves multiple tenants:

- Pick isolation level **once**, at the start: column-based (cheapest), schema-per-tenant (middle), DB-per-tenant (strongest isolation, highest overhead).
- All queries filter by tenant. Enforce in a base manager/repository — not per-call.
- Tests cover cross-tenant access attempts and ensure they fail closed.

## Configuration

- **12-factor:** config via env vars, not files committed to the repo.
- One config object loaded at startup. **Validate at startup** — fail loud on missing/invalid values.
- Different envs (dev, staging, prod) differ only in config, not code.

## Secrets

- Never in code, never in committed files. Env vars (with `.env` gitignored) in dev.
- In production, a secrets manager (AWS Secrets Manager, Vault, Doppler) — but that wiring is set up before Claude is involved; just read from the env.

## Observability (code-level)

When adding logging or error tracking in code:

- **Structured logs** (JSON) with a correlation/request ID. No secrets, no raw request bodies that may contain them, no PII.
- Use the framework's recommended logger. Never `print()` for production paths.
- For uncaught exceptions, **Sentry SDK** (`sentry-sdk`) is the project default — initialize it once at startup, then it captures automatically.
- Tag releases and environments in the Sentry init.

Health endpoints:

- `GET /healthz` — liveness (process is up).
- `GET /readyz` — readiness (DB, Redis, critical deps reachable).
- Both return cheap JSON, no auth.

## Resilience (code patterns)

When calling external services:

- **Timeouts** on every outbound call. Connect timeout + read timeout, separately.
- **Retries** with exponential backoff + jitter on retryable errors. Cap attempts.
- **Circuit breakers** for dependencies that can take down the system.
- **Graceful degradation** — if a recommendations service is down, the product page still renders.
- **Idempotency** on retried operations to avoid duplicates.

## Performance

- Measure before optimizing. Slow queries are usually the culprit.
- Optimization order: pagination → indexes → denormalize. Caching is a tool, not a fix for a bad query plan.
- Connection pooling for DB and HTTP clients.
- Detect N+1 in dev (debug toolbar, query loggers, tests that assert query counts).

## Security architecture (code-level)

- **Defense in depth:** input validation + parameterized queries + output escaping + CSP — not just one.
- **Least privilege** in code paths: a service that only reads should hold a read-only DB role; per-service IAM roles in cloud calls.
- **Authn vs Authz separated.** Centralize authorization checks in services/middleware, not scattered across controllers.
- **Audit logging** for sensitive actions: who did what, when, to what entity.
- Always validate / sanitize HTML you render from user input. Avoid `dangerouslySetInnerHTML` / `mark_safe` without a clear reason.

## When to introduce complexity

Default to a **modular monolith** with clear feature boundaries. Split out a service only when:

- An independent scaling axis demands it.
- A different team owns it end-to-end.
- It needs a different language/runtime for a good reason.

Avoid by default:

- **Microservices** without org/scale pressure — two services with a shared DB are worse than a modular monolith.
- **Event sourcing / CQRS** — niche; almost never the right starting point.
- **Custom infrastructure** when managed services fit.

---

## Decision quick-reference

| Question                                | Default answer                          |
|-----------------------------------------|-----------------------------------------|
| SQL or NoSQL?                           | SQL (Postgres) unless shape demands NoSQL |
| Monolith or microservices?              | Modular monolith                        |
| REST or GraphQL?                        | REST unless clients need flexible reads |
| Sync or async API handler?              | Whichever the framework prefers; don't mix |
| Cache or fix the query?                 | Fix the query first                     |
| Where do business rules live?           | Services / domain, not controllers      |
| External API call fails — what now?     | Timeout + retry + circuit breaker + fallback |
| Where do secrets live in code?          | Read from env vars; never hardcoded     |
| Add a new abstraction?                  | Only when 2+ concrete use cases exist   |

---

## Anti-patterns

- "Generic" / "flexible" abstractions built for hypothetical future needs.
- Distributed monolith — many services that must deploy together.
- Business logic split across triggers, signals, ORM hooks, and services — no single place to read it.
- Long-running transactions holding DB locks.
- Catch-all `except` / `catch` that suppresses errors to "stabilize" production.
- Shared mutable state across requests (module-level dicts, singletons holding per-request data).
- "We'll add tests later." Later doesn't come.
- Cargo-culting patterns from large companies (Netflix, Google) without their scale, team, or constraints.

---

# django-react-docker-boilerplate (PLANEKS)

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
