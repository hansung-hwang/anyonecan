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
| 2026-06-18 | `setup.ps1` non-ASCII (`·`/`→`) corrupted to mojibake in generated files on Korean Windows (PS 5.1 read the BOM-less script as cp949) | Saved `setup.ps1` as UTF-8 with BOM | `setup.ps1` |
| 2026-06-18 | Generated rule files said "Comments: Korean" while `CLAUDE.md` said "Comments: English"; English translation pass had missed 21 files | Translated all remaining Korean to English (rule templates, language packs, git-workflow guide) | rule templates, `language-packs/**`, `docs/how-to/git-workflow.md` |
| 2026-06-18 | `setup.sh` rejected language names (only numbers) and shell-interpolated free-text into a `perl` regex (could break/inject) | Accept language names; substitute via `$ENV{...}`; make git step non-fatal | `setup.sh` |
