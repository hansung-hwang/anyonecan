# /commit — Commit Automation

Analyzes changes, proposes a commit message, and commits if validation passes.

## Steps

### Step 1: Pre-scan

Before committing, grep for the following:

```bash
# Check for pinned tests (test.only / describe.only)
grep -rn "\.only(" src/

# Check for leftover console.log
grep -rn "console\.log" src/

# Check for @ts-ignore / @ts-expect-error
grep -rn "@ts-ignore\|@ts-expect-error" src/
```

If any are found, **abort** the commit and report the locations.

### Step 2: Validate

```bash
pnpm typecheck && pnpm lint && pnpm test
```

If validation fails, abort the commit and report the errors.

### Step 3: Analyze Changes

Analyze `git diff --staged` to understand what changed.

### Step 4: Propose Commit Message

Propose a commit message in this format:

```
<type>(<scope>): <English description>

[reason and context — optional]

[Closes #issue-number — optional]
```

### Step 5: Confirm with User

Show the proposed message to the user and await approval or revision.

### Step 6: Execute Commit

On approval:

```bash
git commit -m "<approved message>"
```

## Commit Type Guide

| Type | When to Use |
|------|-------------|
| `feat` | New feature, new API endpoint, new component |
| `fix` | Bug fix, incorrect behavior correction |
| `refactor` | Structural improvement without behavior change, rename |
| `test` | Add/update tests (no source change) |
| `docs` | README, comments, CLAUDE.md, or other doc changes |
| `chore` | Package updates, config file changes |
| `perf` | Performance optimization (algorithm improvement, caching, etc.) |

## Notes

- Both pre-scan and validation must pass before committing
- Do not use `--no-verify`
- If there are no staged files, do not commit and notify the user
