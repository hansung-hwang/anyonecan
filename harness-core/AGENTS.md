# AGENTS.md — {{PROJECT_NAME}}

> **Project**: {{PROJECT_DESCRIPTION}}
> **Language**: {{LANGUAGE_DISPLAY}}
> **Author**: {{AUTHOR}} | **Created**: {{DATE}}
>
> This file is read by **all AI coding tools** (Claude Code, Cursor, Windsurf, Codex, etc.).
> Detailed guides: `docs/how-to/` | Architecture decisions: `docs/adr/`

## Architecture

Layer dependency (unidirectional): `domain` ← `application` ← `infrastructure` ← `presentation`
`domain` layer must not depend on external libraries. (→ `docs/adr/001`)

## Coding Rules

{{LANGUAGE_RULES}}

- Comments: English, WHY only (WHAT is explained by the code)

## Prohibited

{{BANNED_ITEMS}} · direct `.env` edits · PRs without tests

## Validation

Always run after modifying code:

```bash
./scripts/validate.sh
```

## Steering Loop

On a mistake:
1. Run `./scripts/validate.sh` to identify errors
2. If a linter rule can catch it, add a rule to the linter config file
3. If it's a habit/pattern issue, add it to this file (AGENTS.md) and `CLAUDE.md` (keep both in sync)
4. If it's an architecture decision, write a new ADR in `docs/adr/`
5. Record the change in `HARNESS-CHANGELOG.md`

## Workflow Prompts

Markdown files in `.claude/commands/` are **shared AI tool prompts**.

| File | Purpose | Claude Code |
|---|---|---|
| `start.md` | Session start — git status, recent commits, goal summary | `/start` |
| `fix.md` | Error fix loop — root cause analysis, rule addition | `/fix` |
| `commit.md` | Pre-commit checks | `/commit` |
| `review.md` | Code review | `/review` |
| `test.md` | Test writing guide | `/test` |
| `adr.md` | Architecture decision record | `/adr` |
| `coverage.md` | Test coverage check | `/coverage` |

**Non-Claude Code tools**: Copy the contents of the relevant file and use it as a prompt.
