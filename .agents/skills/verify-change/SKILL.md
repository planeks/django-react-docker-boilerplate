---
name: verify-change
description: Choose and run the narrowest sufficient checks for a change, then report honestly. Use before claiming a change works or is ready — after editing backend, frontend, or the API contract. Prefers focused checks over the full suite and never claims a command passed unless it actually ran.
---

# Verify change

Match the checks to what actually changed. Do not run the whole suite for a one-line edit; do not skip verification because a change "looks trivial".

## Pick the scope

Look at `git status` / `git diff --name-only`:

- **Backend** (`src/**/*.py`, excluding `migrations/`) → ruff check + ruff format check; run the affected app's tests, not the whole backend, when you can scope them.
- **Frontend** (`src/frontend/src/**`) → `npm run lint` + `npm test`.
- **API contract** (`**/api/**`, serializers, views, urls) → also follow `api-contract-change` and regenerate the schema to review the diff.
- **Migrations added** → run `migrate` in a fresh container and confirm it applies clean.
- Docs / config-only changes → no code checks; say so.

## Order

Focused tests first (fastest signal), then the format/lint gate, then the fuller suite only if the change is broad or touches shared code. Containers must be up: `docker compose -f compose.dev.yml up -d`.

## Script

`scripts/check-changes.sh` derives scope from the git diff and runs the narrowest documented commands. It wraps the existing `docker compose` commands — it does not reimplement them.

```bash
scripts/check-changes.sh              # verify the working-tree diff
scripts/check-changes.sh --base main  # verify everything since main
scripts/check-changes.sh --all        # full backend + frontend suite
```

It prints exactly what it ran and what it skipped, and exits non-zero on any real failure. Read its final summary — do not infer a pass from the absence of red.

## Report honestly

- Never state a command passed unless you ran it and saw it pass. Quote the failing output when it fails.
- Distinguish **new** failures your change caused from **pre-existing** failures on the base branch (run the check on the base if unsure).
- Name what you could **not** verify (e.g. "did not run the frontend build", "no integration test for this path") — see `concise-engineering-output` for the closing format.
