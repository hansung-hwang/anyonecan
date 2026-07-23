# /plan — Work Planning

Create a design/progress document before starting non-trivial work, so the
user can see what's being designed and track progress, and so a future
session can resume without re-deriving context.

## When to Use

Use before work spanning multiple files, an architecture change, or anything
worth tracking. Skip for trivial one-line fixes.

## Steps

### 1. Check Existing Plans

```bash
ls .workspace/plans/
```

Avoid duplicating an existing active plan on the same topic — update it
instead of creating a new one.

### 2. Create the Plan File

Write `.workspace/plans/YYYY-MM-DD-<kebab-case-topic>.md` using the template
in `.workspace/plans/README.md`: Goal, Approach, Checklist, Notes. For
multi-agent work, also fill in the template's optional `Parallelization`
block; skip it for ordinary single-agent plans.

### 3. Update STATUS.md

In `.workspace/STATUS.md`, set `Active plan` to the new file's path and fill
in `Current Goal`.

### 4. Confirm with User

Summarize the plan in 2-3 sentences before starting implementation.
