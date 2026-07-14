# /start — Session Start Routine

Understand the current state and clarify work goals at the start of a session.

## Steps

### 1. Check Current Changes

```bash
git status
```

Identify staging status, untracked files, and conflicts.

### 2. Check Recent Commits

```bash
git log --oneline -5
```

Understand the context of previous work.

### 3. Read Project Docs

Read `CLAUDE.md` and `AGENTS.md` to review current rules and conventions.

### 4. Read Work State

Read `.workspace/STATUS.md`. If it has an active plan, also read that file
in `.workspace/plans/` to see the design and checklist progress.

### 4.5. Check for Other In-Progress Plans

```bash
grep -l "Status.*In Progress" .workspace/plans/*.md 2>/dev/null
```

`STATUS.md`'s "Active plan" only points at one plan. Grep the rest of
`.workspace/plans/` for any other file with `- **Status**: In Progress` —
these are unfinished work `STATUS.md` doesn't mention. Note them in the
summary below; don't start overlapping work without reading them first.

### 5. Summarize Current State

Summarize the following concisely:

- **Current branch**: `git branch --show-current`
- **Uncommitted changes**: list of files and summary, if any
- **Recent work context**: inferred from commit messages and `.workspace/STATUS.md`
- **Current work goal**: from the active plan if one exists; otherwise confirm with user or infer and present
- **Other in-progress plans**: any found in step 4.5 beyond the active one

### 6. Ready Message

After the summary, finish with:

```
Ready. What would you like to work on?
```
