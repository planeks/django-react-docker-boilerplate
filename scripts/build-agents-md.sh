#!/usr/bin/env bash
#
# Generate AGENTS.md from the CLAUDE templates in .claude/.
#
# CLAUDE.md uses Claude Code's `@path` imports, which other agents (Codex, Cursor,
# Copilot, Gemini CLI) don't resolve. AGENTS.md is the same content flattened into a
# single file so those tools get the full standards.
#
# Run after editing anything in .claude/, then commit both files.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

OUTPUT="AGENTS.md"

# Order matters: later files override earlier ones where they conflict.
SOURCES=(
    ".claude/CLAUDE_base.md"
    ".claude/CLAUDE_python.md"
    ".claude/CLAUDE_django.md"
    ".claude/CLAUDE_react.md"
    ".claude/CLAUDE_architecture.md"
    ".claude/CLAUDE_project.md"
)

for source in "${SOURCES[@]}"; do
    if [[ ! -f "$source" ]]; then
        echo "error: missing source file: $source" >&2
        exit 1
    fi
done

{
    cat <<'HEADER'
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

HEADER

    for source in "${SOURCES[@]}"; do
        printf '\n---\n\n'
        # Two rewrites so the flat file reads as one document:
        #   1. `# CLAUDE.md — Django (PLANEKS)` → `# Django (PLANEKS)`, so the heading
        #      anchors match the table of contents above.
        #   2. Cross-references between templates become in-document pointers.
        sed -E \
            -e '1,5s/^# CLAUDE\.md — /# /' \
            -e 's/\[[^]]*\]\(\.\/(CLAUDE_[a-z_]+)\.md\)/the `\1` section of this file/g' \
            -e 's/`(CLAUDE_[a-z_]+)\.md`/the `\1` section of this file/g' \
            "$source"
    done
} >"$OUTPUT"

echo "Wrote $OUTPUT from ${#SOURCES[@]} source files ($(wc -l <"$OUTPUT" | tr -d ' ') lines)."
