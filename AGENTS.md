# AGENTS.md — anyonecan (Harness Engineering Framework)

> **⚠ This file is for framework development only.**
> To create a new project, run `setup.ps1` (Windows) or `./setup.sh` (Mac/Linux),
> then run the AI tool from the generated project directory.
>
> **Language**: TypeScript
> This file is read by **all AI coding tools** (Claude Code, Cursor, Windsurf, Codex, etc.).
> When using Claude Code, you can also use the slash commands defined in `CLAUDE.md`.

## Architecture

Layer dependency (unidirectional): `domain` ← `application` ← `infrastructure` ← `presentation`
`src/domain` must not import external libraries. (→ `docs/adr/001`)

## Coding Rules

- No `any` → use `unknown` + type guards
- Explicit return type on every function (`explicit-function-return-type`)
- `as` assertions only when unavoidable; explain the reason in a comment
- File names: `kebab-case.ts` / `.test.ts` / `.types.ts` / `.interface.ts`
- Comments: English, WHY only (WHAT is explained by the code)

## Prohibited

`any` · `@ts-ignore` · `@ts-nocheck` · `@ts-expect-error` · `console.log` · excessive `eslint-disable` · direct `.env` edits · PRs without tests

## Validation

```bash
pnpm validate   # typecheck + lint + test
```

## Steering Loop

On a mistake:
1. Run `pnpm validate` to identify errors
2. If a linter rule can catch it, add a rule to `eslint.config.js`
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
