# /fix — Mistake Steering Loop

When an agent mistake occurs, harden the harness so the same mistake does not recur.

## Steps

### 1. Analyze the Mistake

- Which file and line did it occur in?
- What is the root cause?
- What rule, if it existed, would have caught it automatically?

### 2. Decide Where to Add the Rule

| Mistake Type | Where to Add |
|---|---|
| Code pattern detectable by linter | Add rule to linter config file |
| Code habit, naming, or comment issue | Sync addition to `CLAUDE.md` + `AGENTS.md` |
| Architecture or design decision | Write new ADR at `docs/adr/NNN-<title>.md` |

### 3. Apply the Rule

Add the rule to the decided location.

### 4. Validate

```bash
./scripts/validate.sh
```

### 5. Record in HARNESS-CHANGELOG.md

Add a row to `HARNESS-CHANGELOG.md` in this format:

| Today's date | Summary of mistake | Rule added | Location |
|---|---|---|---|

### 6. Output Rule Summary

```
## Rules Added
- [location]: [rule content]
- Recurrence prevention rationale: [why this rule prevents the mistake]
```
