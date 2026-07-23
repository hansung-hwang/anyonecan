# plans/

Design and progress documents for in-flight work. Run `/plan` before starting
non-trivial work (multi-file changes, architecture decisions, anything worth
tracking) to create one here. Skip it for trivial one-line fixes.

The user can open any file in this directory to see what the agent is
designing, deciding, and how far along it is.

## Naming

`YYYY-MM-DD-<kebab-case-topic>.md`

## Template

```markdown
# <Title>

- **Date**: YYYY-MM-DD
- **Status**: In Progress | Done | Abandoned
- **Owner**: (optional — only when multiple people share this project; who owns this task)

## Goal

What this work achieves and why.

## Approach

Design/implementation strategy, key decisions and trade-offs.

## Checklist

- [ ] Step 1
- [ ] Step 2

## Notes

Open questions, alternatives considered, links to ADRs if relevant.

## Parallelization (optional — only for multi-agent work)

Fill this in only when at least two tasks are genuinely independent and the parallelism benefit exceeds
delegation/review/integration cost. Otherwise delete this section — single-agent is the default. `/coordinate`
(Claude Code) generates this section directly from the active task; see
`docs/how-to/multi-agent-collaboration.md` for the full model.

- **Coordinator**: the one session that integrates, runs full validation, updates shared docs, and runs `/done`.
- **Base SHA**: the fixed commit every agent branch forks from (set after Wave 0 prerequisites are committed).
- **Shared / generated files** (Coordinator-owned; no agent writes these): e.g. `.workspace/**`, lockfiles,
  generated bundles/manifests, result tables.
- **Full validation command + environment**: the exact command, working directory, and any writable-temp/env flags.

### Wave 0 — prerequisites (Coordinator, committed before assignments)
- shared fixtures / scaffolding / interfaces that agents build on

### Wave 1 — assignments (one writer per file per wave)
| Agent | Goal (one sentence) | Allowed files | Prohibited files | Depends on |
|---|---|---|---|---|
|  |  |  | `.workspace/**`, shared/generated, other agents' files |  |

### Integration order
1. ...

### Completion authority
Only the Coordinator updates shared journals, regenerates derived artifacts, and runs `/done`.
Sub-agents report `requirement → file/symbol/test location`, their commit SHA, and validation command+result.
```

## Multiple Team Members

`.workspace/` is designed to survive one branch, not merge cleanly across
many at once:

- **`STATUS.md`** is a per-branch snapshot by nature — expect it to differ
  across feature branches; that's normal, not drift. On merge, keep
  whichever branch's snapshot represents the more current state (usually
  the branch being merged in), don't try to union it.
- **`worklog.md`** is append-only. On a merge conflict, keep **both** sides'
  rows rather than picking one — it's a log, not a single source of truth
  for current state. Rows may optionally include an author column
  (`| date | author | summary | files | plan |`) when it's useful to know
  who did what; single-contributor projects can leave it out.
- Plan files (this directory) are one-per-task and named by date+topic, so
  they rarely conflict; if two members start a plan with the same name on
  the same day, disambiguate with a suffix (`-2`). The template's optional
  `Owner` field records who owns a given task's plan.
