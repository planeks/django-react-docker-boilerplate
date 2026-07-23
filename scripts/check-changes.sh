#!/usr/bin/env bash
#
# check-changes.sh — run the tests for what changed, in Docker.
#
# Dev tooling (NOT an ops/deploy script). Lint and format are pre-commit's job
# (ruff, eslint, prettier — see .pre-commit-config.yaml); this only runs the
# test suites, scoped to whichever side of the codebase you touched, so you
# don't run the full backend+frontend for a one-line change. See the
# `verify-change` skill.
#
# Usage:
#   scripts/check-changes.sh                # test the working-tree diff
#   scripts/check-changes.sh --base main    # test everything since <ref>
#   scripts/check-changes.sh --all          # backend + frontend suites
#   scripts/check-changes.sh --help
#
# Exit code: non-zero if any suite that actually ran failed.

set -euo pipefail

COMPOSE="docker compose -f compose.dev.yml"
BASE=""
RUN_ALL=0

usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="${2:-}"; shift 2 ;;
    --all)  RUN_ALL=1; shift ;;
    --help|-h) usage ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Move to repo root so paths and compose file resolve regardless of CWD.
cd "$(git rev-parse --show-toplevel)"

ran=()
skipped=()
failures=0

note_skip() { skipped+=("$1"); }

run() { # run "<label>" <cmd...>
  local label="$1"; shift
  echo ">>> $label"
  echo "    \$ $*"
  if "$@"; then
    ran+=("PASS  $label")
  else
    ran+=("FAIL  $label")
    failures=$((failures + 1))
  fi
}

# --- preflight: docker + containers -----------------------------------------
if ! docker info >/dev/null 2>&1; then
  echo "Docker is not available — cannot run containerized tests." >&2
  echo "Start Docker and the stack: $COMPOSE up -d" >&2
  exit 2
fi

django_up=0
frontend_up=0
$COMPOSE ps --status running --services 2>/dev/null | grep -qx django   && django_up=1   || true
$COMPOSE ps --status running --services 2>/dev/null | grep -qx frontend && frontend_up=1 || true

# --- collect changed files ---------------------------------------------------
if [ -n "$BASE" ]; then
  changed="$(git diff --name-only "$BASE"...HEAD; git diff --name-only)"
else
  # staged + unstaged + untracked
  changed="$(git diff --name-only HEAD; git ls-files --others --exclude-standard)"
fi
changed="$(printf '%s\n' "$changed" | sed '/^$/d' | sort -u)"

backend_changed=0
frontend_changed=0
api_changed=0
migration_changed=0

while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in
    # Python anywhere under src/ — including src/frontend/*.py (the Django app:
    # templatetags, views) — is backend, tested by `django test`. Match this
    # before the src/frontend/* catch-all below.
    src/*/migrations/*.py) migration_changed=1; backend_changed=1 ;;
    src/*.py|src/*/*.py|src/*/*/*.py|src/*/*/*/*.py)
      backend_changed=1
      case "$f" in
        */api/*|*serializers*|*/views.py|*/urls.py) api_changed=1 ;;
      esac
      ;;
    # Everything else under src/frontend/ is the React app, tested by vitest.
    src/frontend/*) frontend_changed=1 ;;
  esac
done <<< "$changed"

if [ "$RUN_ALL" -eq 1 ]; then
  backend_changed=1; frontend_changed=1
fi

echo "== check-changes =="
if [ "$RUN_ALL" -eq 1 ]; then
  echo "mode: --all (both suites)"
else
  echo "changed files:"; printf '%s\n' "$changed" | sed 's/^/  /'
fi
echo

# --- backend -----------------------------------------------------------------
if [ "$backend_changed" -eq 1 ]; then
  if [ "$django_up" -eq 1 ]; then
    run "backend: django test" $COMPOSE run --rm django test
  else
    note_skip "backend tests — django container not running ($COMPOSE up -d)"
  fi
else
  note_skip "backend tests — no backend files changed"
fi

if [ "$api_changed" -eq 1 ]; then
  note_skip "API contract touched — regenerate schema and follow api-contract-change (not run automatically)"
fi
if [ "$migration_changed" -eq 1 ]; then
  note_skip "migration changed — confirm it applies on a fresh DB ($COMPOSE run --rm django manage migrate)"
fi

# --- frontend ----------------------------------------------------------------
if [ "$frontend_changed" -eq 1 ]; then
  if [ "$frontend_up" -eq 1 ]; then
    run "frontend: vitest" $COMPOSE exec -T frontend npm test
  else
    note_skip "frontend tests — frontend container not running ($COMPOSE up -d)"
  fi
else
  note_skip "frontend tests — no frontend files changed"
fi

# --- summary -----------------------------------------------------------------
echo
echo "== summary =="
if [ ${#ran[@]} -eq 0 ]; then
  echo "ran: (nothing)"
else
  printf '  %s\n' "${ran[@]}"
fi
if [ ${#skipped[@]} -gt 0 ]; then
  echo "skipped:"
  printf '  - %s\n' "${skipped[@]}"
fi

if [ "$failures" -gt 0 ]; then
  echo
  echo "RESULT: $failures suite(s) failed."
  exit 1
fi
echo
echo "RESULT: all suites that ran passed. Lint/format is enforced separately by pre-commit."
