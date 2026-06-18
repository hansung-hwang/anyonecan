# CLAUDE.md — {{PROJECT_NAME}}

> **Project**: {{PROJECT_DESCRIPTION}}
> **Language**: {{LANGUAGE_DISPLAY}}
> **Author**: {{AUTHOR}} | **Created**: {{DATE}}
>
> This is a Claude Code-only configuration file. For other AI tools, see `AGENTS.md`.
> Detailed guides: `docs/how-to/` | Architecture decisions: `docs/adr/`

## Session Start

Run `/start` at the beginning of each session — summarizes git status, recent commits, and current goals.

## Architecture

Layer dependency (unidirectional): `domain` ← `application` ← `infrastructure` ← `presentation`
`domain` layer must not depend on external libraries. (→ `docs/adr/001`)

## Coding Rules

{{LANGUAGE_RULES}}

- Comments: English, WHY only (WHAT is explained by the code)

## Prohibited

{{BANNED_ITEMS}} · direct `.env` edits · PRs without tests

## Validation

```bash
./scripts/validate.sh
```

## Steering Loop

On a mistake, run `/fix` →
- If a linter rule can catch it, add a rule to the linter config file
- If it's a habit/pattern issue, add it to this file (CLAUDE.md) and `AGENTS.md` (keep both in sync)
- If it's an architecture decision, write a new ADR in `docs/adr/`
