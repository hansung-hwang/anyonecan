# /commit — Commit Automation

Analyzes changes, proposes a commit message, and commits if validation passes.

## Steps

### Step 1: Validate

```bash
./scripts/validate.sh
```

The linter enforces the `.only()` / debug-output items from `AGENTS.md`'s
Prohibited list directly (no manual grep needed — see the arch-test and
lint config for each language). If validation fails, abort the commit and
report the errors.

### Step 2: Analyze Changes

Analyze `git diff --staged` to understand what changed.

### Step 3: Propose Commit Message

```
<type>(<scope>): <English description>

[reason and context — optional]
[Closes #issue-number — optional]
```

### Step 4: Confirm with User, Then Commit

## Commit Types

| Type | When to Use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Structural improvement without behavior change |
| `test` | Add/update tests |
| `docs` | Documentation changes |
| `chore` | Config or package changes |

## Notes

- Validation must pass before committing
- Do not use `--no-verify`
- If there are no staged files, do not commit
- After a successful commit, if this closes out the work session, run `/done`
