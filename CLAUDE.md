# CLAUDE.md

Guidance for Claude Code when working in this repository.

The standards below are the shared PLANEKS templates (kept in `.claude/`, synced from
[`ai-md-files`](https://github.com/DenysDemchenkoPlaneks/ai-md-files)) plus this project's own layer.
Read them in order — later files override earlier ones where they conflict.

@.claude/CLAUDE_base.md
@.claude/CLAUDE_python.md
@.claude/CLAUDE_django.md
@.claude/CLAUDE_react.md
@.claude/CLAUDE_architecture.md
@.claude/CLAUDE_project.md

---

## Other agents

`AGENTS.md` at the repo root holds the same content flattened into one file, for tools that don't
resolve `@imports` (Codex, Cursor, Copilot, Gemini CLI, …). It is **generated** — after editing
anything in `.claude/`, regenerate it and commit both:

```bash
./scripts/build-agents-md.sh
```
