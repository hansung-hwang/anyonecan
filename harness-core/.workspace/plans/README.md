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

## Goal

What this work achieves and why.

## Approach

Design/implementation strategy, key decisions and trade-offs.

## Checklist

- [ ] Step 1
- [ ] Step 2

## Notes

Open questions, alternatives considered, links to ADRs if relevant.
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
  for current state.
- Plan files (this directory) are one-per-task and named by date+topic, so
  they rarely conflict; if two members start a plan with the same name on
  the same day, disambiguate with a suffix (`-2`).
