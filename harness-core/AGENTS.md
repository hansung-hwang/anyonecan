# AGENTS.md — {{PROJECT_NAME}}

> **Project**: {{PROJECT_DESCRIPTION}}
> **Language**: {{LANGUAGE_DISPLAY}}
> **Author**: {{AUTHOR}} | **Created**: {{DATE}}
>
> This is the **single source of truth** for project rules, read by
> **all AI coding tools** (Claude Code, Cursor, Windsurf, Codex, etc.).
> `CLAUDE.md`, `.cursorrules`, `.windsurfrules`, and `.cursor/rules/harness.mdc`
> are thin pointers to this file — edit rules here only, never in those files.
> Claude Code additionally has slash commands — see `CLAUDE.md`.
> Detailed guides: `docs/how-to/` | Architecture decisions: `docs/adr/`

## Work Journal

`.workspace/` tracks session-to-session state so work survives an unplanned session end:

- `.workspace/STATUS.md` — current snapshot (overwritten each session close-out)
- `.workspace/worklog.md` — append-only history of completed sessions
- `.workspace/plans/` — per-task design docs with progress checklists

Run `/plan` before non-trivial work, `/done` at the end of a session.
AGENTS.md/README.md stay lean — only update them when a rule, convention, or
user-facing behavior actually changes (see `/done` step 4). Update
`STATUS.md` (and any doc it affects) **the moment a meaningful change lands**
— don't wait for session end or for someone to ask; `/done` is a close-out
ritual, not the only checkpoint.

**Multiple team members**: `STATUS.md` is a per-branch snapshot — differing
across branches is normal, not drift. `worklog.md` is append-only — on a
merge conflict, keep both sides' rows rather than picking one. See
`.workspace/plans/README.md` for details.

## Key Invariants (do not break)

Project-specific rules distilled from incidents and non-obvious design
decisions — arguably the highest-value section in this file, since it's the
one a generic template can't write for you. When something breaks in a
surprising way, or a design choice isn't obvious from the code, add one
bullet here: what the rule is, why it exists, and where it's enforced.

- (none yet — add the first one when it happens)

## Architecture

Layer dependency (unidirectional): `domain` ← `application` ← `infrastructure` ← `presentation`
`domain` layer must not depend on external libraries. (→ `docs/adr/001`)

## Coding Rules

{{LANGUAGE_RULES}}

- Comments: {{COMMENT_LANGUAGE}}, WHY only (WHAT is explained by the code)

## Prohibited

{{BANNED_ITEMS}} · direct `.env` edits · PRs without tests

## Validation

Always run after modifying code:

```bash
./scripts/validate.sh
```

Windows: use `scripts/validate.ps1` instead, if the language pack provides one.

## Steering Loop

On a mistake:
1. Run `./scripts/validate.sh` to identify errors
2. If a linter rule can catch it, add a rule to the linter config file
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
