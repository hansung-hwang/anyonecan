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
| 2026-07-14 | `language-packs/python`'s own shipped sample/template code had 2 real lint violations (E501 line-too-long in `test_dependencies.py`, F401 unused `User` import in `test_user.py`) that this repo's own root `pnpm validate` can never catch — it's a TypeScript project and has no Python toolchain, so a Python pack's sample code can silently ship broken. Found by manually running the new `validate.ps1` against a freshly generated sample project. | Fixed both violations directly (extracted `rel` var to shorten the f-string line; dropped the unused `User` import). Added a step to `docs/how-to/adding-a-language-pack.md`'s "Verify end-to-end" checklist: re-run `scripts/validate.sh`/`.ps1` in a generated sample project after **any** edit to a pack's shipped code, not only when adding a new pack. | `language-packs/python/tests/arch/test_dependencies.py`, `language-packs/python/tests/domain/test_user.py`, `docs/how-to/adding-a-language-pack.md` |
| 2026-07-25 | `setup.ps1`'s "Installing dependencies" step always printed the candidate's `successMessage` regardless of whether the install actually succeeded (no exit-code check outside the esbuild `retryFix` branch). Worse, the script's global `$ErrorActionPreference = "Stop"` combined with `Invoke-Expression $candidate.run 2>&1 \| Out-Null` turned any routine stderr line from the installer (e.g. uv's "Using CPython ... interpreter at:") into a terminating exception that aborted the block mid-install while the native process kept running in the background — producing a broken partial `.venv` while the console showed no error, or (if it hit the generic catch) reported failure even when the install would have finished successfully a moment later. Found while running item 2 of `.workspace/STATUS.md`'s Next Steps (closing the 1.4.0 validation caveat): a freshly generated Python project's `validate.sh` failed with "No module named mypy" despite `setup.ps1` having reported "uv sync complete". `setup.sh` (Mac/Linux) had the same always-succeed reporting bug but not the EAP issue (bash `set -e` doesn't fire inside `if` conditions). | Made success reporting honest in both scripts (only print the success message if the install command's actual exit code was 0; otherwise print a "failed, run it manually" warning). In `setup.ps1`, additionally scope `$ErrorActionPreference = "Continue"` around the install block (saved/restored via a `finally`) so native stderr no longer gets promoted to a terminating exception. Verified by regenerating real TypeScript and Python projects via `setup.ps1` after the fix and running each one's `validate.sh` end-to-end (all passed); confirmed no regression on the TS/pnpm path, which never hit the bug because pnpm happened to emit no stderr in that run. | `setup.ps1`, `setup.sh` |
