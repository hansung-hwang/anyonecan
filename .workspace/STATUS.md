# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-26
**Active plan**: none — **all three linked 2026-07-25 plans are now Done.**

## Current Goal

The three linked plans from 2026-07-25 are **all complete**:

1. **`2026-07-25-upgrade-tooling-safety-and-dry-run.md`** — ✅ Done, committed `a5b022f`. `--dry-run` on all three
   entry points; the baseline-safety fix (a manifest path added after a project's last upgrade, where the project
   already wrote a file there, now gets `.new` instead of silent overwrite).
2. **`2026-07-25-file-ownership-rules.md`** — ✅ Done, committed `bf3e429` + review fixes `ccaf5fa`. Ships
   `docs/how-to/file-ownership.md`, an `AGENTS.md` File Ownership section, makes `harness-manifest.json` itself
   framework-owned (D5), and a 4th `check-sync.mjs` guard keeping the doc and manifest from drifting apart.
   `HARNESS-VERSION` bumped to **1.6.0**.
3. **`2026-07-25-apply-harness-1.5.0-to-homographormer.md`** (retargeted to 1.6.0) — ✅ **Done, 2026-07-26.**
   Homographormer upgraded 1.3.0 → 1.6.0 for real, committed on its own `chore/harness-upgrade-1.6.0` branch
   (`d51a7a4`) — **not merged to its `main`**, that's the project owner's call.

No active plan for the next session — start fresh, or pick up the small follow-ups in Next Steps below.

## Progress

- **Plan 1 — committed as `a5b022f`.** `pnpm validate` passed pre-commit. Full record in that plan file.
- **Plan 2 (file ownership rules) — done, committed `bf3e429`, plus a post-implementation review pass committed
  as `ccaf5fa`.**
  - **Post-implementation review (`ccaf5fa`) found 3 real documentation-accuracy defects** — the code and its O4
    verification held up, but shipped prose did not: (1) `AGENTS.md`'s Framework Versioning kept a hand-written
    list of framework-owned paths that was stale (missing all `docs/how-to/**` guides — a gap dating to
    1.2.0/1.4.0 — plus `harness-manifest.json`, which 1.6.0 itself added); fixed by **deleting the enumeration**
    rather than correcting it, since that was the *third* hand-copy of the list to drift during 1.6.0's own
    development; (2) the shipped guide claimed its Framework tier is "generated from" the manifest and "not
    hand-maintained" — both false, it's hand-written and *guarded*, and check-sync catches drift rather than
    preventing it; (3) the guide claimed the project's manifest copy "never goes stale", overstated for both a
    pre-1.6.0 project's first upgrade and any project that edits its copy. All three fixed.
  - **Also verified during that review, all previously unchecked**: newly generated 1.6.0 projects **do** record a
    baseline for `harness-manifest.json` (so no spurious `.new` on their first upgrade — this was the D5 change's
    highest-risk unverified assumption, confirmed by forcing the per-file loop on a fresh project); `setup.sh` has
    **full parity** with `setup.ps1` on all of it and produces a byte-identical baseline hash; `check-sync.mjs` is
    correctly absent from the manifest, so the guide's "the framework repo's check-sync.mjs" wording is accurate.
  - Full phase-by-phase record (O0-O5, Gate O0's own tier-table bug, the check-sync guard's 3-way break-test) is in
    that plan file — not repeated here since it's Done and won't be revisited unless something regresses.
  - **Found, out of scope, not fixed**: `.workspace/plans/README.md`'s root and `harness-core` copies have
    drifted independently of anything this plan touches — root is missing the entire "Owner" field and
    "Parallelization" block that 1.4.0 added to harness-core's copy. Worth its own small fix in a future session.
- **Plan 3 (Homographormer upgrade) — done, real project, real commit, real validation.**
  - **Homographormer directory identity — resolved this session, before running the upgrade.**
    `C:\anyonecan_harness\anyonecan\Homographormer\` (flagged as an open discrepancy at last session's close) is
    confirmed to be the **real, actively-developed project**, not a leftover scratch copy — its own Claude Code
    session history spans 9 days (2026-07-17 to 2026-07-25) with megabytes of real transcripts; the alternate
    candidate location (`C:\Users\rty10\Desktop\HomoGraphormer`) doesn't exist on disk and has no real session
    history. Last session's STATUS.md claim that "the scratch copy was deleted" referred to a *different*,
    separate temporary copy from that session's own dry-run testing — not this directory. Nested-repo hygiene (a
    full git repo sitting inside this framework repo's own working tree, untracked) is still a structural oddity
    worth fixing eventually, but wasn't touched — the user's call.
  - **H0-H1**: pre-flight confirmed clean `git status`, HEAD matched the plan's recorded rollback point exactly
    (`e719135`), branch `chore/harness-upgrade-1.6.0` created. `--dry-run` output **differed from the plan's
    1.5.0-era recording in a fully anticipated way** (3 added not 2 — `file-ownership.md` is new in 1.6.0; 2
    newly-managed `.new` not 1 — `harness-manifest.json` itself joined the guide, the documented D5 one-time
    caveat) — cross-checked against the current FRAMEWORK-CHANGELOG.md before proceeding, not treated as project
    drift. Real upgrade run confirmed `git status` matched exactly.
  - **H2 (guide merge) — the real content-merge step.** Compared the project's 610-line Korean guide against the
    387-line template section-by-section: 1:1 structural match except one genuinely new section, template §13
    "Working as a team" (the `/team`-paired role-scoping layer) — confirmed by grepping the whole template for
    role/team mentions outside §13 (none) and a principle-count check (7=7). Confirmed Solo status from
    `.harness-meta.json` (no `projectMode`) and `worklog.md` (no team mentions) before porting a **short pointer**
    (new §15, project's own numbering) rather than the full section, per the plan's own Solo-likely guidance.
    Relocated the merged guide to `docs/guides/multi-agent-collaboration.md` via `git mv`, fixed the two path
    references left in the project's `AGENTS.md`.
  - **Real, unplanned finding during H2**: relocating the guide left `.claude/commands/coordinate.md`/`team.md`
    (freshly delivered, framework-owned) with a dangling internal reference to the now-empty
    `docs/how-to/multi-agent-collaboration.md` path. Fixed correctly, not by hand-editing the framework-owned
    command files: forced the upgrade's per-file loop to run a second time, which delivered the plain framework
    guide fresh at that path (`added`, proper baseline recorded) — restoring a normal, unmodified framework file
    instead of a broken reference. Resolved `harness-manifest.json.new` in the same pass (diffed first — pure
    newer-manifest content, no project edits — then applied); this file wasn't in the original plan's H4 scope
    since it predates D5.
  - **H4**: both `.new` files (`lint-format-hook.sh`, `test_dependencies.py`) diffed and confirmed the project's
    version is a strict superset of the template in both cases; kept, `.new` deleted. The arch-test exclusion was
    **run for real** (`pytest tests/arch/test_dependencies.py`, stdlib-only, no `.venv` needed) — 6/6 passed,
    confirming the merge didn't just look safe but actually works.
  - **H5**: registered `/coordinate`/`/team` in `AGENTS.md`'s Workflow Prompts table and `CLAUDE.md`. Used
    **English, not Korean** for the new table rows — checked the existing table first and found it entirely
    English (framework boilerplate, never translated at generation despite the project's Korean comment
    language), so matched the table's actual observed style over the plan's literal wording.
  - **H6**: real environment limitation, same class as Java's `mvn` — no project `.venv` in this session, so
    `scripts/validate.sh` itself can't run (its `python3` fallback resolves to a broken Windows Store alias
    instead of the working system Python that happens to have `mypy`/`ruff`/`pytest`/`torch`/`numpy` installed).
    **Did not skip validation** — ran the script's exact three commands manually against the working interpreter:
    `mypy src/` (2 files, clean), `ruff check src/ tests/` (clean), `pytest` (14/14, full `testpaths: tests`
    scope). Confirmed zero changes under `src/`/`HomoGraphormer/`/`results/`, twice. `HARNESS-VERSION` and
    `.harness-meta.json`'s `harnessVersion` both 1.6.0, no stale-field regression.
  - **Commit**: the project's own `.husky/pre-commit` hook hits the identical broken-`python3` issue. **Did not
    use `--no-verify`** — created a temporary `python3` wrapper (pointing at the working interpreter) scoped only
    to the commit command's `PATH`, so the hook's own existing logic found a real interpreter and passed
    legitimately; removed the wrapper immediately after. Committed as `d51a7a4` on `chore/harness-upgrade-1.6.0`;
    `main` untouched.
  - **All 7 acceptance criteria met** — full detail in the plan file.
- **Harness 1.4.0, 1.5.0, and now 1.6.0 — all Done, fully validated, committed, and pushed.** `origin/main` =
  `4048be2` (confirmed synced with local `main`).
- **Plan-status audit + README restructure (`4048be2`)** — done after the three plans closed, at the user's
  request to verify everything landed and to organize the README's project-creation/upgrade guidance.
  - **Found 4 real staleness defects**, all instances of this repo's own "update every section referencing the
    changed fact" rule being violated in its own workspace docs: both 2026-07-25 plans still claimed "not yet
    committed/pushed" in their Status line *and* acceptance-criteria footer hours after being committed and
    pushed; `2026-07-14-harness-1.3.0-customization-safety.md` had claimed "commit pending user approval" for
    **12 days** (`af1698f` landed the same day the plan was written); Phase U1's header still said "not yet
    U4-verified" with an unchecked box for a proof U4 had since passed. All corrected.
  - **`worklog.md` had no 2026-07-26 entry at all** — three completed plans and 7 commits were missing from the
    append-only history. Two rows added (framework work; the Homographormer upgrade).
  - **Systemic observation, not yet acted on**: the first three defects share one cause — a plan's `Status:` line
    gets written *before* the commit exists, saying "not yet committed", and is never revisited afterward. The
    existing AGENTS.md rule already covers it in principle; what would actually prevent it is not putting
    commit state in a plan's Status line at all (it's guaranteed to go stale), or having `/done` check for it.
    Left as an observation for the user to decide on rather than unilaterally adding another rule.
  - **README restructured**: new "After Generating: What's Yours vs. the Framework's" section (three-tier table,
    the `docs/guides/` rule, the two files the framework can't update for you), and "Framework Versioning &
    Upgrades" split from one prose wall into a 6-step workflow, a table decoding all 7 output buckets, a Cautions
    list, and a framework-contributor note. Bucket names verified against `upgrade.py`'s actual output strings
    rather than written from memory.
- `agentic-eacc-mcp-server` (external project, `agentic-eacc-mcp-server/` in this repo's working tree) — **is now
  present on this machine** as of 2026-07-27 (contradicts the 2026-07-26 note below, which is now stale — the
  project must have been copied/cloned onto this machine between those two dates). 2026-07-27: upgraded its
  harness from 1.3.0 to 1.6.0 on branch `chore/harness-upgrade-1.6.0` (commit `30e8715` in that project's own repo,
  not this one — it's a separate git repository nested in this working tree, not a submodule). Full detail in its
  own `.workspace/worklog.md` (2026-07-27 row). **Merged to that project's `master` (fast-forward, now at
  `30e8715`)** — the merge also carried 3 pre-existing unmerged commits that had been sitting on the old
  `chore/harness-upgrade-1.2.0` branch (Phase 3A indexing fix + ADR 002 finalization), since the 1.6.0 branch was
  cut from it rather than from `master`. Nothing further to do from this repo.
  <details><summary>2026-07-26 note (superseded)</summary>Not present on this machine at the time; searched this
  machine's filesystem and found nothing. Since superseded by the above.</details>

## Next Steps

1. **Decided 2026-07-26**: Homographormer's `chore/harness-upgrade-1.6.0` branch will **not** be merged into its
   `main` — it's a separate project, merge decisions there are entirely out of this repo's scope. Branch stays as
   a validated, ready artifact in that repo; no further action needed from here.
2. Small, out-of-scope follow-up noted during plan 2: fix the `.workspace/plans/README.md` root/harness-core drift
   (root is missing 1.4.0's Owner field + Parallelization block).
3. **Possible future cleanup, not urgent, user's call**: `C:\anyonecan_harness\anyonecan\Homographormer\` sits
   nested inside this framework repo's own working tree (untracked, own separate `.git`) — a full separate project
   physically living inside `anyonecan`'s folder rather than as a sibling directory. Not a git-history issue (its
   history is self-contained), purely a filesystem-organization one; a plain folder move to a sibling location
   would resolve it. Not done — the user's call, and not urgent.
4. **User's call, whenever a toolchain/admin environment is available**: validate the Java language pack's
   `validate.sh` (`mvn verify`) — still unconfirmed end-to-end in this environment (`winget` blocks on an
   interactive Microsoft Store ToS prompt; no JDK/Maven present).

## Blockers / Open Questions

- **None.** All three linked plans are Done and verified.
- **Environment notes carried forward for future sessions on this box**:
  - `pnpm` missing from Bash-tool PATH by default — fix with `npm install -g pnpm@10 --prefix "$APPDATA/npm"`
    (corepack's `pnpm@11.x` shim hits a Node 18.17 `ERR_VM_DYNAMIC_IMPORT_CALLBACK_MISSING` incompatibility; use
    `npm install -g pnpm@10` directly, not corepack).
  - This box has **two Pythons that matter**: `python` → miniconda (`C:\Users\rty10\miniconda3`, has
    mypy/ruff/pytest/torch/numpy installed) and `python3` → a Windows Store alias with none of those. Any script
    that does `command -v python3` before falling back to bare `python` (several `validate.sh`/hook scripts do
    this, by design, to prefer a project `.venv` first) will silently pick the broken one when no `.venv` exists.
    Workaround used this session: a temporary `python3` shim pointing at miniconda's `python.exe`, placed early in
    `PATH` for just the one command that needs it, never touching the system config.
  - No `mvn`/`javac` here, so any Java verification in these plans is structural (generation) rather than
    build-level — same constraint as 1.4.0/M4, 1.5.0/T4, and 1.6.0.
