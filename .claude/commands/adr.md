# /adr — ADR Creation

Write a new Architecture Decision Record (ADR) in `docs/adr/`.

## Steps

### 1. Check Existing ADR Numbers

```bash
ls docs/adr/
```

Determine the next number (NNN).

### 2. Create the ADR File

Write `docs/adr/NNN-<kebab-case-title>.md` in this format:

```markdown
# ADR NNN — <Decision Title>

- **Date**: YYYY-MM-DD
- **Status**: Accepted | Deprecated | Superseded by ADR NNN

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

If there are related constraints, add a `(→ docs/adr/NNN)` link to the architecture section of `CLAUDE.md`.

### 4. Confirm Completion

Summarize the created ADR path and the key decision in one line.
