# Upgrade Tooling — Safety Fix + Dry Run

- **Date**: 2026-07-25
- **Status**: Done (all phases U0-U5 complete and verified 2026-07-26; not yet committed/pushed)
- **Target release**: Tooling fix — no `HARNESS-VERSION` bump (confirmed at Gate U0; changelog-only)
- **Motivation**: found while planning the Homographormer 1.3.0 → 1.5.0 upgrade
  (`.workspace/plans/2026-07-25-apply-harness-1.5.0-to-homographormer.md`). That plan needs a manual
  "rescue the file upgrade is about to destroy" step. This plan removes the need for that step.
- **Sequencing**: **do this one first of the three.** Land it before
  `.workspace/plans/2026-07-25-file-ownership-rules.md` (whose decision D5 — making `harness-manifest.json`
  framework-owned — is only safe once this plan's U2 fix exists, otherwise it can overwrite a project that edited
  its manifest copy), and before the Homographormer upgrade (this deletes that plan's riskiest phase, H2).
  Full order: **this → file-ownership-rules → apply-harness-1.5.0-to-homographormer**.
- **Companion**: `.workspace/plans/2026-07-25-file-ownership-rules.md` — same incident, other half of the fix.
  This plan makes the *mechanism* safe (upgrade won't destroy project-authored files); that one makes the *rule*
  known (projects are told where the boundary is, so they don't create the collision in the first place).

## Goal

Make `upgrade` safe to run and cheap to preview:

1. **`--dry-run`** — preview exactly what an upgrade would do, writing nothing.
2. **Close the baseline gap** — stop silently overwriting a file the project authored itself.
3. **Tell the user what they must do by hand** — new commands need registering in user-owned files.

## Evidence this is worth doing (real, not hypothetical)

Planning the Homographormer upgrade required cloning 1.4 GB of that project into scratch space and running a real
upgrade against the copy, purely to answer "what will this do?" — because **there is no dry-run** (confirmed:
`upgrade.py` takes two positional args, no flags). That preview found a real hazard: a hand-written 22 KB Korean
multi-agent guide would be **silently overwritten**, losing project-specific agent roles and Phase-0 wave
assignments. Recoverable only because the project has a clean git repo and someone knew to look.

Both problems are general, not Homographormer-specific.

## Design decisions

### D1 — The baseline fix must be surgical, not a blanket "never overwrite"

There are two different "no baseline" situations, and the current code conflates them
(`upgrade.py:190-201`, `upgrade.ps1:190-198`):

| Situation | Meaning | Correct behavior |
|---|---|---|
| `has_baselines == False` — no `baselines` map at all | Project predates 1.3.0 entirely; its files are almost certainly untouched framework copies | **Keep overwriting** (current behavior). Already warned loudly at startup. Forcing `.new` here would spew dozens of `.new` files on a legitimate one-time migration. |
| `has_baselines == True`, but this path has no entry | The path entered the manifest *after* this project's last upgrade — and the file **exists on disk anyway**, so the project created it | **Write `.new`, never overwrite.** This is the Homographormer case. |

The second case can only mean project authorship: any manifest path known at the last 1.3.0+ run already has a
baseline, and a path with no baseline that *doesn't* exist on disk takes the "added" branch instead. So "exists +
no baseline + baselines map present" ⇒ the project wrote it.

### D2 — `--dry-run` should share one code path with the real run

Not a separate "simulate" function — the classification logic must be identical or the preview is worthless.
Implementation: gate the ~13 write sites behind two tiny helpers (`write_text(...)` / `remove_if_exists(...)`) that
no-op when dry-run is set, and print the same report with a `DRY RUN — nothing was written` banner.

### D3 — Probably **no** `HARNESS-VERSION` bump (decide at Gate U0)

`upgrade.ps1`/`upgrade.sh`/`upgrade.py` are **not** in `harness-manifest.json` — they are framework-repo tooling,
never copied into a generated project (verified). Per `AGENTS.md` → Framework Versioning, only framework-*owned*
file changes require a bump. Precedent: 1.4.0's changelog recorded an `upgrade.ps1`/`upgrade.py` fix explicitly as
*"not itself frameworkOwned, no version bump required, noted here since it affects every upgrade run."*

Counter-argument considered and rejected: bumping would make every project's next `upgrade` report "already
current" and advance a version marker with **zero** shipped file changes — pure noise for users.

**Recommendation**: no bump; add a `FRAMEWORK-CHANGELOG.md` entry under a "Tooling" heading. Retitle this plan from
"1.6.0" to "tooling" if U0 confirms.

## Phases and Gates

### Phase U0 — Design gate (decide before writing code) — ✅ Closed 2026-07-26

- [x] Confirm D3: bump `HARNESS-VERSION` or changelog-only? **Decided: changelog-only.** Plan retitled from
      "1.6.0 candidate" to "tooling fix" above.
- [x] Confirm the D1 two-case split is right, especially that pre-1.3.0 projects keep the overwrite path.
      **Decided: confirmed as written** — pre-1.3.0 (no `baselines` map) keeps overwriting; only "has baselines
      map, path missing, file exists on disk" gets `.new` treatment.
- [x] Confirm flag naming: `--dry-run` (py/sh) and `-DryRun` (PowerShell switch), matching each shell's idiom.
      **Decided: confirmed as written.**
- [x] Decide whether `--dry-run` should exit non-zero when merges are pending (useful for CI) or always 0.
      **Decided: always 0** — preview, not a gate.

### Phase U1 — `--dry-run` (do this first: it makes U2 testable) — ✅ Implemented 2026-07-26 (not yet U4-verified)

- [x] `upgrade.py`: added a `dry_run` flag parsed from `sys.argv` (accepts `--dry-run` anywhere in argv);
      introduced `write_text()`/`remove_if_exists()` helpers; routed **all** write sites through them — the
      per-file loop, the `HARNESS-VERSION` write, the bootstrap-file writes, and the `.harness-meta.json` write
      (now built as a string via `json.dumps` so it can go through `write_text()` too). `os.makedirs` is now
      inside `write_text()` so dry-run also creates zero directories.
- [x] `upgrade.ps1`: mirrored exactly via `[switch]$DryRun` param and `Write-ManagedText`/`Remove-IfExists`
      helper functions (PowerShell-idiomatic names, same no-op-when-dry-run semantics).
- [x] `upgrade.sh`: accepts `--dry-run` anywhere in its args (loop over `"$@"`, first non-flag arg is
      `PROJECT_DIR`), forwards it to `upgrade.py`; usage string updated to `[--dry-run]`.
- [x] `DRY RUN` banner: prints `Mode : DRY RUN -- nothing will be written` up top when active, and a
      `DRY RUN -- nothing was written` closing line replacing the "Changes are NOT committed" footer.
- [ ] **Not yet done**: full-tree hash / `git status` verification that dry-run truly writes zero bytes — that's
      U4's job, not this phase's syntax-level implementation.

### Phase U2 — Baseline safety fix — ✅ Implemented + smoke-tested 2026-07-26

- [x] `upgrade.py`: split the `else` into `elif has_baselines:` (new `.new`-writing branch) vs `else:` (old
      overwrite path) — when `has_baselines` is true but the path has no baseline entry **and the file exists**
      (guaranteed at that point, since the `existing is None` case already `continue`d earlier), writes
      `<file>.new` into a new `newly_managed` list instead of overwriting.
- [x] `upgrade.ps1`: mirrored exactly (`elseif ($HasBaselines)` vs `else`), new `$NewlyManaged` list.
- [x] Reported distinctly from ordinary customized-file merges, in both scripts — separate "N file(s) newly
      managed by the framework" block explaining *why* (path added to manifest after last upgrade, framework
      can't tell if it's the project's own file, so it's treated like a customization).
- [x] Updated `harness-core/harness-manifest.json`'s `_baselinesComment` to document all three cases (unmodified /
      customized / newly-managed-with-no-entry) instead of the old two-case description.
- [x] **Smoke-tested** (not yet the full U4 matrix): reproduced the exact Homographormer shape — a hand-authored
      file at a manifest-known path with no baseline entry — confirmed original byte-identical, `.new` written,
      both dry-run and real-run agree. Also regression-checked a genuine pre-1.3.0 project (no `baselines` key at
      all) with a pre-existing file still takes the overwrite path unchanged.

### Phase U3 — Post-upgrade guidance for user-owned files — ✅ Implemented + smoke-tested 2026-07-26

- [x] When `added` contains any `.claude/commands/*.md`, both `upgrade.py` and `upgrade.ps1` now print a reminder
      that `AGENTS.md`'s Workflow Prompts table and `CLAUDE.md`'s Claude Code Extras command list are
      **user-owned** — upgrade cannot edit them — and name the commands added. Smoke-tested on both entry points
      against a fresh pre-1.0 project (11 new commands correctly listed).

### Phase U4 — Verification matrix (real projects, not simulation) — ✅ Passed 2026-07-26

Followed the 1.4.0/M5 and 1.5.0/T4 technique: disposable projects from `git worktree` checkouts (`af1698f`, the
1.3.0 commit; `f34eb77`, the pre-versioning commit — both predate `.harness-meta.json`'s `baselines`/existence
respectively), generated via each worktree's own `setup.ps1` **non-interactively** (piped stdin works when
`setup.ps1` is invoked directly via `powershell.exe -File ... < answers.txt`, bypassing this session's
`-NonInteractive` wrapper on the PowerShell tool itself — `Read-Host` errors under that wrapper even with piped
stdin, so the workaround was calling `powershell.exe` from the Bash tool instead). Both worktrees removed, both
scratch project dirs deleted, after verification.

- [x] **Reproduced the Homographormer hazard synthetically**: generated a real 1.3.0 TypeScript project from the
      `af1698f` worktree (confirmed: its manifest has zero `multi-agent-collaboration.md` references), hand-authored
      a file at `docs/how-to/multi-agent-collaboration.md`, upgraded with the current (fixed) `upgrade.ps1` →
      reported as "1 file(s) newly managed", `.new` written, and the hand-authored original confirmed
      **byte-identical** by direct `cat` after upgrade. No baseline was recorded for it (confirmed via grep on
      `.harness-meta.json`), so a later upgrade will re-offer the merge until resolved — correct per D1.
- [x] **Regression: genuine pre-versioning project** (generated from `f34eb77`, confirmed **no** `.harness-meta.json`
      on disk at all — predates even P2) with a hand-customized `.editorconfig`: upgraded via current `upgrade.ps1`
      → `.editorconfig` landed in the **overwritten** bucket (not newly-managed), matching old behavior exactly,
      with the expected "predates harness versioning" warning.
- [x] **Regression: normal customized file** (real baseline entry from a prior real upgrade, not synthetic):
      hand-customized `.editorconfig` on the already-upgraded 1.3.0→1.5.0 test project (forced the per-file loop to
      re-run by temporarily rolling its own `HARNESS-VERSION` back to 1.4.0, same technique as the 1.4.0/M5
      precedent) → landed in the **merge_needed** bucket ("customized locally"), reported separately and correctly
      from the still-pending `newly_managed` guide file in the same run.
- [x] **`--dry-run` writes nothing**: full-tree SHA-256 hash (44 files) + `git status --porcelain` captured before
      and after a `--dry-run` run that classified 2 added / 2 updated / 1 customized / 1 newly-managed — both
      diffs **empty** (byte-for-byte identical, zero new untracked files).
- [x] **`--dry-run` output == real-run output**: same project, same starting state — identical classification and
      file lists between the `-DryRun` run and the immediately following real run; the real run then verified to
      actually apply (hand-authored file still byte-identical after; `.new` present; no baseline recorded for it).
- [x] Ran the matrix on **both** implementations: `upgrade.ps1` (primary, all scenarios above) cross-checked with
      `upgrade.py` directly (identical classification on the same post-upgrade project state) and `upgrade.sh`
      (via Git Bash + real `python3`, confirmed `--dry-run` forwards correctly both as a trailing and a leading
      argument).
- [x] Re-ran the **real Homographormer dry run** against the actual on-disk copy at
      `C:\anyonecan_harness\anyonecan\Homographormer` (safe by construction now — dry-run is proven zero-write
      above) — confirmed `docs/how-to/multi-agent-collaboration.md` reported as "1 file(s) newly managed" /
      `.new`, **not** silently overwritten; the two previously-known `.new` merges
      (`scripts/lint-format-hook.sh`, `tests/arch/test_dependencies.py`) landed correctly in the ordinary
      `merge_needed` bucket; `git status --porcelain` inside that copy stayed empty after the dry-run. **Caveat
      carried forward, not resolved here**: whether this on-disk copy is *the* real Homographormer project or a
      stray leftover from a prior session's scratch analysis is still an open question flagged to the user at
      session start — dry-run's provable zero-write safety made running it low-risk either way, but the copy's
      identity itself is unresolved.

### Phase U5 — Docs — ✅ Done 2026-07-26

- [x] `FRAMEWORK-CHANGELOG.md`: added a `## Tooling - 2026-07-26 (no HARNESS-VERSION bump)` entry (before the
      `[1.5.0]` entry), summarizing `--dry-run`, the D1 baseline-safety fix, U3's command-registration reminder,
      and the `_baselinesComment` update, plus the real-project verification technique used.
- [x] `README.md` → Framework Versioning & Upgrades: added a `--dry-run`/`-DryRun` example block right after the
      upgrade command, and extended the "Customized a framework-owned file?" paragraph to cover the new
      "newly managed" case and the U3 command-registration reminder.
- [x] Updated `.workspace/plans/2026-07-25-apply-harness-1.5.0-to-homographormer.md`: deleted the old Phase H2
      manual rescue entirely; merged its content-porting purpose into the renumbered Phase H2 (was H3), now sourced
      from the `.new` file instead of a manually-saved copy; Phase H1 gained an explicit `--dry-run`-first step;
      re-ran both dry-run states (pre-fix, from the original session record, and post-fix, live against the real
      on-disk project) and recorded both in the "Evidence" section; dropped the "Framework-side follow-up" section
      since this plan now supersedes it; fixed every other cross-reference (`H3`→`H2` in two places, Acceptance
      Criterion 7, the Risks table) so the doc is internally consistent under the new phase numbering.

## Acceptance Criteria

1. ✅ `upgrade --dry-run` (all three entry points) writes **zero** bytes and reports the same classification the
   real run would produce. *(U1 + U4: full-tree hash + `git status` proven empty diff; `.py`/`.ps1`/`.sh` cross-checked.)*
2. ✅ A file the project authored at a path the framework later claimed is **never overwritten** — it gets `.new`.
   *(U2 + U4: reproduced synthetically and confirmed byte-identical; confirmed live against the real Homographormer copy.)*
3. ✅ A genuine pre-1.3.0 project still upgrades via the overwrite path, unchanged. *(U4: verified on a real
   pre-versioning project generated from the `f34eb77` worktree.)*
4. ✅ The user is told, at the end of an upgrade, which new commands need hand-registering and where. *(U3, smoke-tested on both `.py` and `.ps1`.)*
5. ✅ `harness-manifest.json`'s `_baselinesComment` matches actual behavior. *(U2.)*
6. ✅ The Homographormer plan no longer needs a manual rescue step. *(U5: old Phase H2 deleted from that plan.)*

**All six acceptance criteria met, 2026-07-26. Plan ready to close out** (pending user review / commit — nothing
pushed yet).

## Risks

| Risk | Mitigation |
|---|---|
| Two parallel implementations (`.py` / `.ps1`) drift | Every U1/U2 change is specified as "mirror exactly"; U4 runs the matrix on both. Nothing mechanically enforces this parity today — a known, accepted limitation. |
| `--dry-run` misses a write site → the "preview" mutates a project | D2's helper-function approach makes omissions visible; U4 verifies with a full-tree hash, not by inspection. |
| The D1 split is wrong and a legitimate case starts emitting `.new` | U4 explicitly regression-tests the pre-1.3.0 path, which is the case most likely to be broken by this change. |
| Scope creep into a general "upgrade UX" rewrite | Three narrow changes, all traceable to a real incident. Anything else is out of scope for this plan. |

## Out of scope

- Mechanical parity enforcement between `upgrade.py` and `upgrade.ps1` (worth its own plan if drift recurs).
- Auto-editing `AGENTS.md`/`CLAUDE.md` — they are user-owned by design; U3 only *reports*.
- Interactive/three-way merge for `.new` files.
