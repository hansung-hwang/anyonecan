# CLAUDE.md

> **⚠ This file is for framework development only.**
> To create a new project, run `setup.ps1` (Windows) or `./setup.sh` (Mac/Linux),
> then run the AI tool from the generated project directory.
>
> This is a Claude Code-only configuration file. For other AI tools, see `AGENTS.md`.
> Detailed guides: `docs/how-to/` | Architecture decisions: `docs/adr/`

## Session Start

Run `/start` at the beginning of each session — summarizes git status, recent commits, and current goals.

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

On a mistake, run `/fix` →
- If a linter rule can catch it, add a rule to `eslint.config.js`
- If it's a habit/pattern issue, add it to this file (CLAUDE.md) and `AGENTS.md` (keep both in sync)
- If it's an architecture decision, write a new ADR in `docs/adr/`
