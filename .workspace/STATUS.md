# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-28
**Active plan**: none — `2026-07-28-agents-section-drift-detection.md` is Done. **Harness 1.7.0 released.**

## Current Goal

No active plan. Most recent work: shipped **`AGENTS.md` template section
drift detection** and released it as **harness 1.7.0** — `upgrade` now tells
a project when the framework changed the *body* of an `AGENTS.md` section
it already has (1.6.1 could only detect a section missing entirely).

## Progress

- **Harness 1.7.0 — done, released, applied to `Homographormer`.** Full
  record in `.workspace/plans/2026-07-28-agents-section-drift-detection.md`;
  highlights only, not repeated here:
  - Justified by measurement before building anything: 11 "heading stayed,
    body changed" events across `harness-core/AGENTS.md`'s full history; 8
    undetected by any existing mechanism — 2× the 4 missing-section events
    1.6.1 already got tooling for. One confirmed live victim
    (`Homographormer`'s stale `Work Journal`, fixed by hand in `e658404`
    the same session, before this plan started).
  - Design property carried over from 1.6.1's own lesson: hashes the
    **template's** section body, never the project's own prose, so a
    translated/rewritten section never false-positives.
  - New `.harness-meta.json` key `agentsTemplateSections`; first run on an
    existing project (no recorded hash yet) records silently, reports
    nothing — `setup.ps1`/`setup.sh` now record it at generation time so a
    freshly generated project never hits that gap at all.
  - **Version bump to 1.7.0 was required for a mechanical reason, not
    visibility**: `upgrade.py`'s early-return on a version match would
    otherwise leave the feature permanently dormant on every
    already-current project, `Homographormer` included. Full reasoning in
    the plan.
  - **Real bug found and fixed during verification** (not by inspection —
    a freshly generated test project reported 5 false "changed" sections
    seconds after being generated): PowerShell's `Get-Content` defaults to
    the system codepage, not UTF-8, silently mangling non-ASCII template
    prose before hashing. Fixed every `Get-Content` call in
    `upgrade.ps1`/`setup.ps1` that reads UTF-8 content. This incidentally
    fixed a **pre-existing, independent 1.6.1 bug**: `Get-Headings` had the
    same gap, and `upgrade.ps1`'s read of `.harness-meta.json` was silently
    corrupting non-English `commentLanguage` values (e.g. `"한국어 (Korean)"`)
    on every real run against a non-English project. Neither had been
    exercised before since prior verification only used ASCII content.
  - Verified end-to-end, real projects/generation, not simulation: a fresh
    `setup.ps1` generation reports clean; a direct mutation of
    `harness-core/AGENTS.md`'s `Steering Loop` body was correctly named by
    both `upgrade.py --verify` and `upgrade.ps1 -Verify` (reverted via
    `git checkout` after each test, confirmed clean); `--dry-run`/matching-
    version real runs confirmed to write nothing.
  - Applied for real to `Homographormer`: `chore/harness-upgrade-1.7.0`
    (forked from the unmerged `chore/harness-upgrade-1.6.1` tip, same
    reasoning as the 1.6.0→1.6.1 fork), commit `3783e12`. First-run-silent
    confirmed live (6 sections recorded, nothing reported); full
    `validate.sh` (mypy/ruff/pytest 14/14) passing; `main` untouched.
- **Homographormer 1.6.0 → 1.6.1 (`b045373`) and its AGENTS.md advisory-gap
  fixes (`e658404`) — done**, immediately preceding the 1.7.0 work above.
  Full record in `.workspace/plans/2026-07-28-upgrade-homographormer-1.6.1.md`.
  `test_dependencies.py`'s `STDLIB_ROOTS` moved to `sys.stdlib_module_names`
  (project's `EXCLUDED_SOURCE_DIRS`/`collect_py_files` customization
  preserved by hand); `AGENTS.md` gained an English `Handoff and Reporting`
  heading, a `File Ownership` section, and a `Work Journal` sentence it was
  missing since the 1.4.0 era.
  - **Noted, not fixed**: `worklog.md` has no 2026-07-27 row even though
    `FRAMEWORK-CHANGELOG.md`/this file reference that date's 1.6.1 release
    work — same append-only-history gap the 2026-07-26 audit already found
    and fixed once. Still out of scope, still left for a future pass.
- Everything from 2026-07-25/26/27 (harness 1.6.0 release itself, the
  Homographormer 1.6.0 upgrade, the plan-status audit, `agentic-eacc-mcp-
  server`'s 1.3.0→1.6.0→1.6.1 upgrades) is **Done** — see `worklog.md` for
  full detail, not repeated here since none of it is still open.

## Next Steps

1. Small, out-of-scope follow-up noted during the file-ownership-rules plan:
   fix `.workspace/plans/README.md`'s root/harness-core drift (root is
   missing 1.4.0's Owner field + Parallelization block).
2. **Possible future cleanup, not urgent, user's call**:
   `C:\anyonecan_harness\anyonecan\Homographormer\` sits nested inside this
   framework repo's own working tree (untracked, own separate `.git`) rather
   than as a sibling directory. Purely filesystem-organization, not a
   git-history issue. Not done — the user's call, and not urgent.
3. **User's call, whenever a toolchain/admin environment is available**:
   validate the Java language pack's `validate.sh` (`mvn verify`) — still
   unconfirmed end-to-end in this environment (`winget` blocks on an
   interactive Microsoft Store ToS prompt; no JDK/Maven present).
4. `worklog.md`'s missing 2026-07-27 row (see Progress above) — cosmetic,
   not urgent, but the same class of gap that's been fixed twice before.
5. **Deliberately deferred, not a bug**: the `.harness-meta.json` alias map
   for translated `AGENTS.md` headings (`agentsSectionAliases`) — one
   confirmed occurrence (`Homographormer`), stays behind this repo's own
   n=2 bar. Un-defer trigger: a second non-English project hitting the same
   false positive.
6. `Homographormer` now has three sequential unmerged upgrade branches
   (`chore/harness-upgrade-1.6.0` → `1.6.1` → `1.7.0`, each forked from the
   last since none have been merged to `main`) — purely that project
   owner's call on when/whether to merge, not a problem to fix from here,
   but worth knowing the chain exists before starting a 1.7.1+ upgrade later.

## Blockers / Open Questions

- **None blocking.** Environment notes carried forward for future sessions
  on this box:
  - `pnpm` missing from Bash-tool PATH by default — fix with
    `npm install -g pnpm@10 --prefix "$APPDATA/npm"` (corepack's
    `pnpm@11.x` shim hits a Node 18.17 `ERR_VM_DYNAMIC_IMPORT_CALLBACK_MISSING`
    incompatibility; use `npm install -g pnpm@10` directly, not corepack).
  - **Python interpreter situation, still broken in effect**: `python3` on
    PATH no longer resolves to the old Windows-Store alias — it's now a
    real Python 3.13.0 install (`AppData\Local\Programs\Python\Python313`)
    — but it still has none of mypy/ruff/pytest/torch/numpy; only
    miniconda's `python` does. Workaround, reusable as-is: a temporary
    `python3` shim on `PATH` pointing at miniconda's `python.exe`, scoped to
    just the one command that needs it.
  - **New this session**: this box's default console/file codepage is
    Korean, not UTF-8 — confirmed the hard way (see 1.7.0 above). Any
    **new** PowerShell code added to this repo that reads a UTF-8 file via
    `Get-Content` must pass `-Encoding UTF8` explicitly, or non-ASCII bytes
    silently corrupt on this box (and any other non-UTF8-codepage Windows
    machine). `[System.IO.File]::ReadAllText(path, [System.Text.Encoding]::UTF8)`
    calls are unaffected (already explicit). Checked and fixed everywhere
    this applied as of 1.7.0; re-check if adding a new `Get-Content` call.
  - No `mvn`/`javac` here, so any Java verification in these plans is
    structural (generation) rather than build-level — same constraint as
    1.4.0/M4, 1.5.0/T4, 1.6.0, 1.6.1, and now 1.7.0.
