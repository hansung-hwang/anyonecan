# HARNESS-CHANGELOG

History of harness rule changes added due to agent mistakes.
Run `/fix` when a mistake occurs, then record it in this file.

## Format

| Date | Mistake | Rule Added | Location |
|------|---------|------------|----------|
| yyyy-mm-dd | What the mistake was | What rule was added | `eslint.config.js` / `CLAUDE.md` / `docs/adr/NNN` |

---

| Date | Mistake | Rule Added | Location |
|------|---------|------------|----------|
| 2026-06-17 | (initial audit) `npm test` hook, bare-module allowlist bug | Full initial harness hardening applied in bulk | entire repo |
