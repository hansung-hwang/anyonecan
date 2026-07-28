# Upgrade Homographormer 1.6.0 → 1.6.1

- **Date**: 2026-07-28
- **Status**: Done

## Goal

Bring `Homographormer` (nested project repo at
`C:\anyonecan_harness\anyonecan\Homographormer\`) from harness 1.6.0 to the
current framework version, 1.6.1.

## Approach

**Scope of the actual change.** Diffing commits `4048be2..8f7f4aa` in this
repo shows 1.6.1 touches exactly one project-delivered file:
`language-packs/python/tests/arch/test_dependencies.py` — `STDLIB_ROOTS`
replaced with `sys.stdlib_module_names` instead of a hand-written 30-name
subset (fixes false positives like `calendar`/`zoneinfo`). Everything else
in the 1.6.1 changelog (`upgrade.py`/`.ps1`/`.sh` `--verify` mode, `AGENTS.md`
missing-section reporting) is framework-repo-only tooling, never copied into
a generated project — confirmed by `git diff --stat`, only `HARNESS-VERSION`
and that one test file changed under `harness-core`/`language-packs`.

**Known merge conflict, not a surprise.** Homographormer's copy of
`tests/arch/test_dependencies.py` was already classified "customized"
(superset of the template) during the 1.6.0 upgrade (H4) — it adds
`EXCLUDED_SOURCE_DIRS = {"HomoGraphormer_original"}` and a
`collect_py_files()` helper the template doesn't have, on top of its own
hand-written `STDLIB_ROOTS`. A fresh diff today confirms this is still true.
1.6.1 will therefore deliver another `.new` for this file, same as before —
the task is to fold the template's `sys.stdlib_module_names` line into the
project's existing customized copy without losing
`EXCLUDED_SOURCE_DIRS`/`collect_py_files`, not to overwrite wholesale.

**Branch strategy — the one real decision here.** Unlike
`agentic-eacc-mcp-server` (whose 1.6.0 branch was already merged to
`master` before the 1.6.1 branch was cut fresh from it), Homographormer's
`chore/harness-upgrade-1.6.0` branch (commit `d51a7a4`) was **deliberately
not merged** into its `main` (2026-07-26 decision, still standing) — and the
project owner has since added real work on top of it
(`6187450`, Phase 0 test promotion). Cutting a new 1.6.1 branch from `main`
would drop both the harness upgrade and that follow-on work; cutting from
`main` was never how this branch was meant to reach 1.6.1 anyway. Plan: fork
`chore/harness-upgrade-1.6.1` from the current tip of
`chore/harness-upgrade-1.6.0` (`6187450`), same as the file-ownership rule
this repo already follows for merge-vs-hold decisions — merging into `main`
stays the project owner's call, not this session's.

**Validation environment — recurring issue, same workaround.** No project
`.venv` here. `python3` on PATH no longer resolves to the old broken
Windows-Store alias (it's now a real 3.13.0 install at
`AppData\Local\Programs\Python\Python313`), but it still lacks
mypy/ruff/pytest/torch/numpy — only miniconda's `python` has those. So
`scripts/validate.sh`'s `python3`-preferred fallback will still silently
pick the wrong interpreter with no `.venv` present. Same fix as last
session: a temporary `python3` shim on `PATH` pointing at miniconda's
`python.exe`, scoped to the validation command only, removed right after.

## Checklist

- [x] Confirm branch/file state: `chore/harness-upgrade-1.6.0` clean, tip
      `6187450`, not merged to `main`.
- [x] Confirm 1.6.1's actual delivered diff (one file) vs. tooling-only
      changes.
- [x] Confirm Homographormer's `test_dependencies.py` is still customized
      (superset) relative to the template.
- [x] Create `chore/harness-upgrade-1.6.1` from `chore/harness-upgrade-1.6.0`
      tip (`6187450`).
- [x] Run `python upgrade.py Homographormer . --dry-run` from `anyonecan`
      (note: takes two positional args, `<project_dir> <script_dir>`, not
      `-ProjectDir`/PowerShell-style flags — `upgrade.py` is invoked
      directly here, not through `upgrade.ps1`). Reported **2** customized
      files, not 1: `tests/arch/test_dependencies.py` (expected) plus
      `scripts/lint-format-hook.sh` (re-flagged every upgrade since it's
      still the 1.6.0-era customized superset — template itself unchanged
      in 1.6.1, confirmed by diffing `.new` against the current file: no
      content difference beyond the project's pre-existing addition).
- [x] Ran the real upgrade (no flags) — `HARNESS-VERSION` and
      `.harness-meta.json.harnessVersion` now 1.6.1.
- [x] Merged `tests/arch/test_dependencies.py.new`: added `import sys`,
      replaced the hand-written `STDLIB_ROOTS` with
      `sys.stdlib_module_names`, kept `EXCLUDED_SOURCE_DIRS` +
      `collect_py_files()` untouched. `lint-format-hook.sh.new` had no
      real content to merge (see above) — discarded as-is, file kept
      customized.
- [x] Validated via miniconda's interpreter (temporary `python3` shim on
      `PATH`, scoped to each command): `mypy src/` clean (2 files),
      `ruff check src/ tests/` clean, `pytest` 14/14 (same count as the
      1.6.0 upgrade — the Phase 0 research-contract tests from `6187450`
      live outside `testpaths: tests`/are governed separately, not part of
      this suite; not a regression).
- [x] `git diff` confirmed only the 3 expected files changed
      (`HARNESS-VERSION`, `.harness-meta.json`, `test_dependencies.py`);
      `upgrade.py --verify` afterward: exit 0, no previously-delivered file
      missing.
- [x] Committed on `chore/harness-upgrade-1.6.1` as `b045373` (used the
      same temporary `python3`-shim workaround for the project's own
      `.husky/pre-commit`, which also runs `validate.sh`). `main` and
      `chore/harness-upgrade-1.6.0` untouched — merge decision left to the
      project owner, same as the 1.6.0 precedent.
- [x] Updated `anyonecan`'s own `.workspace/STATUS.md`.

## Notes

- No `harness-manifest.json`/`harness-core` framework-owned paths are being
  edited by this plan itself — this plan *applies* an already-released
  version, it doesn't change the framework. No `HARNESS-VERSION` bump or
  `FRAMEWORK-CHANGELOG.md` entry needed in `anyonecan`.
- If the dry-run surfaces anything beyond the one expected `.new`, stop and
  re-diff before applying — that would mean the 1.6.0-era baseline recorded
  for Homographormer doesn't match what's actually in its tree, which is
  worth understanding before proceeding.
