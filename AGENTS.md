# AGENTS.md — anyonecan (Harness Engineering Framework)

> **⚠ This file is for framework development only.**
> To create a new project, run `setup.ps1` (Windows) or `./setup.sh` (Mac/Linux),
> then run the AI tool from the generated project directory.
>
> **Language**: TypeScript
> This is the **single source of truth** for project rules, read by
> **all AI coding tools** (Claude Code, Cursor, Windsurf, Codex, etc.).
> `CLAUDE.md`, `.cursorrules`, and `.windsurfrules` are thin pointers to
> this file — edit rules here only, never in those files.
> Claude Code additionally has slash commands — see `CLAUDE.md`.

## Work Journal

`.workspace/` tracks session-to-session state so work survives an unplanned session end:

- `.workspace/STATUS.md` — current snapshot (overwritten each session close-out)
- `.workspace/worklog.md` — append-only history of completed sessions
- `.workspace/plans/` — per-task design docs with progress checklists

Run `/plan` before non-trivial work, `/done` at the end of a session.
AGENTS.md/README.md stay lean — only update them when a rule, convention, or
user-facing behavior actually changes (see `/done` step 4).

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
3. If it's a habit/pattern issue, add it to this file (`AGENTS.md` — the single rule source; `CLAUDE.md` and the other tool files import/point to it automatically)
4. If it's an architecture decision, write a new ADR in `docs/adr/`
5. Record the change in `HARNESS-CHANGELOG.md`

## Workflow Prompts

Markdown files in `.claude/commands/` are **shared AI tool prompts**.

| File | Purpose | Claude Code |
|---|---|---|
| `start.md` | Session start — git status, recent commits, goal summary | `/start` |
| `plan.md` | Create a design/progress doc before non-trivial work | `/plan` |
| `done.md` | Session close-out — worklog entry, STATUS.md reset | `/done` |
| `fix.md` | Error fix loop — root cause analysis, rule addition | `/fix` |
| `commit.md` | Pre-commit checks | `/commit` |
| `review.md` | Code review | `/review` |
| `test.md` | Test writing guide | `/test` |
| `adr.md` | Architecture decision record | `/adr` |
| `coverage.md` | Test coverage check | `/coverage` |

**Non-Claude Code tools**: Copy the contents of the relevant file and use it as a prompt.
