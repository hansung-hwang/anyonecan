# /commit — Commit Automation

Analyzes changes, proposes a commit message, and commits if validation passes.

## Steps

### Step 1: Pre-scan

Before committing, grep for the following:

```bash
# Check for pinned tests (test.only / describe.only, etc.)
grep -rn "\.only(" src/ tests/ 2>/dev/null || true

# Check for leftover debug output (language-specific)
grep -rn "console\.log\|print(\|System\.out\.print" src/ 2>/dev/null || true
```

If any are found, **abort** the commit and report the locations.

### Step 2: Validate

```bash
./scripts/validate.sh
```

If validation fails, abort the commit and report the errors.

### Step 3: Analyze Changes

Analyze `git diff --staged` to understand what changed.

### Step 4: Propose Commit Message

```
<type>(<scope>): <English description>

[reason and context — optional]
[Closes #issue-number — optional]
```

### Step 5: Confirm with User, Then Commit

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

- Both pre-scan and validation must pass before committing
- Do not use `--no-verify`
- If there are no staged files, do not commit
