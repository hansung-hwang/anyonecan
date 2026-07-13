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

Read `CLAUDE.md` (Claude Code) or `AGENTS.md` (other AI tools) to review current rules and conventions.

### 4. Read Work State

Read `.workspace/STATUS.md`. If it has an active plan, also read that file
in `.workspace/plans/` to see the design and checklist progress.

### 5. Summarize Current State

Summarize the following concisely:

- **Current branch**: `git branch --show-current`
- **Uncommitted changes**: list of files and summary, if any
- **Recent work context**: inferred from commit messages and `.workspace/STATUS.md`
- **Current work goal**: from the active plan if one exists; otherwise confirm with user or infer and present

### 6. Ready Message

After the summary, finish with:

```
Ready. What would you like to work on?
```
