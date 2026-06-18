# /adr — ADR Creation

Write a new Architecture Decision Record (ADR) in `docs/adr/`.

## Steps

### 1. Check Existing ADR Numbers

```bash
ls docs/adr/
```

### 2. Create the ADR File

`docs/adr/NNN-<kebab-case-title>.md`:

```markdown
# ADR NNN — <Decision Title>

- **Date**: YYYY-MM-DD
- **Status**: Accepted

## Background
Why this decision was needed.

## Decision
What was decided.

## Rationale
Why this choice is better than the alternatives.

## Consequences
- Positive: ...
- Negative (trade-offs): ...
- Prohibited: ...
```

### 3. Add Reference to CLAUDE.md

If there are related constraints, add a `(→ docs/adr/NNN)` link to the architecture section of `CLAUDE.md` and `AGENTS.md`.
