# /fix — Mistake Steering Loop

When an agent mistake occurs, harden the harness so the same mistake does not recur.

## Steps

### 1. Analyze the Mistake

Understand what went wrong:

- Which file and line did it occur in?
- What is the root cause?
- What rule, if it existed, would have caught it automatically?

### 2. Decide Where to Add the Rule

| Mistake Type | Where to Add |
|---|---|
| Code pattern detectable by linter | Add rule to `eslint.config.js` |
| Code habit, naming, or comment issue | Add to `AGENTS.md` (single rule source — `CLAUDE.md` imports it, other tool files point to it) |
| Architecture or design decision | Write new ADR at `docs/adr/NNN-<title>.md` |

### 3. Apply the Rule

Add the rule to the decided location.

**ESLint rule example** (`eslint.config.js` → `rules` object):
```javascript
'no-restricted-syntax': ['error', { selector: '...', message: '...' }]
```

**AGENTS.md example** (append to prohibited list — the only file to edit):
```
`pattern-name` · reason
```

**ADR example**:
```
docs/adr/004-<decision-title>.md
```
Date: today, Status: Accepted, include decision, reason, and consequences (including prohibited items).

### 4. Validate

After adding the rule, confirm no impact on existing code:

```bash
pnpm validate
```

### 5. Record in HARNESS-CHANGELOG.md

Add a row to `HARNESS-CHANGELOG.md` in this format:

| Today's date | Summary of mistake | Rule added | Location |
|---|---|---|---|

### 6. Output Rule Summary

Summarize the added rule in this format:

```
## Rules Added

- [location]: [rule content]
- Recurrence prevention rationale: [why this rule prevents the mistake]
```
