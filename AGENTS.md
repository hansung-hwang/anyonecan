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
user-facing behavior actually changes (see `/done` step 4). Update
`STATUS.md` (and any doc it affects) **the moment a meaningful change
lands** — don't wait for session end or for someone to ask.

**Multiple team members**: `STATUS.md` is a per-branch snapshot — differing
across branches is normal, not drift. `worklog.md` is append-only — on a
merge conflict, keep both sides' rows rather than picking one. See
`.workspace/plans/README.md` for details.

## Handoff and Reporting

Applies whether one actor works across turns/sessions or several share the repo — general work hygiene, not a
multi-agent-only concern. The rationale and the incidents behind each rule live in
`docs/how-to/multi-agent-collaboration.md` §14, so these bullets stay rule-only:

- Hand off a clean working tree and name the handoff SHA — a WIP commit if you have commit authority, otherwise an
  explicitly declared owned diff. Never a silent dirty handoff.
- Review a fixed Base/Head SHA; if Head moves after review starts, re-review.
- Report completion as `requirement → file/symbol/test location`, not as counts.
- Include the exact command, working directory, and environment in any validation report.
- When editing a durable doc (`AGENTS.md`, `STATUS.md`, a plan), update every other section referencing the changed fact.

Multi-actor mechanics — Coordinator role, worktree isolation, per-wave single-writer ownership, task contracts —
are conditional and activate only when multiple sessions or sub-agents touch this repository at once. See the guide.

## Framework Versioning

`harness-core/HARNESS-VERSION` (semver) is what every generated project
carries and what `upgrade.ps1`/`upgrade.sh` compares against. Any change to
a **framework-owned** file (anything listed in
`harness-core/harness-manifest.json`'s `frameworkOwned`/`languageSpecific`:
`.claude/commands/`, `scripts/status-context.sh`, `.claude/settings.json`,
arch tests, `scripts/validate.sh`/`validate.ps1`, `.github/workflows/ci.yml`,
`.husky/pre-commit`, `.editorconfig`, `.workspace/plans/README.md`) requires:

1. Bump `harness-core/HARNESS-VERSION` (patch for fixes/wording, minor for
   new commands/checks, major for breaking manifest changes)
2. Add an entry to `FRAMEWORK-CHANGELOG.md` (this repo's own changelog —
   distinct from the per-project `HARNESS-CHANGELOG.md` that tracks agent
   mistakes)

Changes to user-owned files (`AGENTS.md`/`CLAUDE.md` rule content,
`README.md`, build configs) do **not** need a version bump — `upgrade`
never touches those files anyway.

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
| `coordinate.md` | Multi-agent coordination plan (opt-in; see `docs/how-to/multi-agent-collaboration.md`) | `/coordinate` |

**Non-Claude Code tools**: Copy the contents of the relevant file and use it as a prompt.
