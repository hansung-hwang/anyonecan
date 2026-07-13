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
