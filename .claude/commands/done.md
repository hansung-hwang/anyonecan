# /done — Work Session Close-out

Run at the end of a work session so the next session (or another person) can
pick up immediately, even if this session ends without warning.

## Steps

### 1. Close the Checklist

If `.workspace/STATUS.md` has an active plan, open its file in
`.workspace/plans/` and mark completed items `[x]`. Set its `Status` to
`Done` if fully finished, otherwise leave `In Progress` with remaining items
visible.

### 2. Append to worklog.md

Add one row to `.workspace/worklog.md`:

| Today's date | one-line summary of what was done | key files/dirs changed | plan file path (or —) |

### 3. Reset STATUS.md

Rewrite `.workspace/STATUS.md` with a fresh snapshot: what's done, what's
next, any open blockers. Clear `Active plan` if that plan is fully done.

### 4. Sync Durable Docs (only if applicable)

- **Rule or convention changed** → update `AGENTS.md` only (the single rule
  source — `CLAUDE.md` imports it and the other tool files point to it), or
  write an ADR via `/adr`
- **User-facing behavior changed** → update `README.md`
- Otherwise, touch nothing here. These files stay lean and rule-focused;
  `.workspace/` carries the session-to-session narration, not AGENTS.md/
  README.md.

### 5. Confirm

Report a one-line summary of what was closed out.
