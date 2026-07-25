# Upgrade Tooling — Safety Fix + Dry Run

- **Date**: 2026-07-25
- **Status**: In Progress (design; no implementation started)
- **Target release**: Harness 1.6.0 candidate — **but see Gate U0: a version bump may not be appropriate**
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

### Phase U0 — Design gate (decide before writing code)

- [ ] Confirm D3: bump `HARNESS-VERSION` or changelog-only? (recommendation: changelog-only)
- [ ] Confirm the D1 two-case split is right, especially that pre-1.3.0 projects keep the overwrite path.
- [ ] Confirm flag naming: `--dry-run` (py/sh) and `-DryRun` (PowerShell switch), matching each shell's idiom.
- [ ] Decide whether `--dry-run` should exit non-zero when merges are pending (useful for CI) or always 0
      (recommendation: always 0 — this is a preview, not a gate).

### Phase U1 — `--dry-run` (do this first: it makes U2 testable)

- [ ] `upgrade.py`: add a `dry_run` flag parsed from `sys.argv`; introduce `write_text()`/`remove_if_exists()`
      helpers; route **all** write sites through them — the per-file loop (lines ~139-201), the `HARNESS-VERSION`
      write (~204), the bootstrap-file writes (~237-238), and the `.harness-meta.json` write (~255).
- [ ] `upgrade.ps1`: same, as a `[switch]$DryRun` param — it is a 303-line parallel implementation of the same
      logic, so every change here must mirror U1's Python change exactly.
- [ ] `upgrade.sh`: accept and forward the flag (currently hardcodes exactly two positional args); update its
      usage string.
- [ ] Print a clear `DRY RUN` banner and suppress the "Changes are NOT committed" footer (nothing changed).

### Phase U2 — Baseline safety fix

- [ ] `upgrade.py`: split the `else` at line ~190 per D1 — when `has_baselines` is true but the path has no
      baseline entry **and the file exists**, write `<file>.new` and add to `merge_needed` instead of overwriting.
- [ ] `upgrade.ps1`: mirror exactly (line ~190).
- [ ] Report these distinctly from ordinary customized-file merges — the user needs to know *why* a `.new` appeared
      for a file they never knowingly customized (e.g. "framework newly manages this path; your version was kept").
- [ ] Update `harness-core/harness-manifest.json`'s `_baselinesComment` — it currently documents the old
      "overwrite-everything for one run" semantics and would otherwise become a stale cross-reference
      (AGENTS.md: "when editing a durable doc, update every other section referencing the changed fact").

### Phase U3 — Post-upgrade guidance for user-owned files

- [ ] When `added` contains any `.claude/commands/*.md`, print a reminder that `AGENTS.md`'s Workflow Prompts table
      and `CLAUDE.md`'s command list are **user-owned** — upgrade cannot edit them — and name the commands added.
      (Directly from the Homographormer plan's Phase H5, which exists only because nothing tells the user this.)

### Phase U4 — Verification matrix (real projects, not simulation)

Follow the 1.4.0/M5 and 1.5.0/T4 technique: disposable projects from `git worktree` checkouts, deleted afterward.

- [ ] **Reproduce the Homographormer hazard synthetically**: generate a project at a commit predating a manifest
      path, hand-author a file at that path, upgrade with the fix → assert `.new` written, original **byte-identical**.
- [ ] **Regression: genuine pre-1.3.0 project** (no `baselines` map) still takes the overwrite path with its
      startup warning — the fix must not turn a legitimate migration into a `.new` storm.
- [ ] **Regression: normal customized file** still produces `.new` exactly as before.
- [ ] **`--dry-run` writes nothing**: hash the whole project tree before/after; `git status` unchanged.
- [ ] **`--dry-run` output == real-run output** for the same starting state (same classifications, same counts).
- [ ] Run the matrix on **both** implementations — `upgrade.ps1` and `upgrade.sh`→`upgrade.py`. Both were
      exercised this session, so both paths are known-runnable here.
- [ ] Re-run the **real Homographormer dry run** with `--dry-run` against the actual project (safe by definition
      now) and confirm the guide is reported as `.new`, not overwritten.

### Phase U5 — Docs

- [ ] `FRAMEWORK-CHANGELOG.md` entry (heading per U0's decision).
- [ ] `README.md` → Framework Versioning & Upgrades: document `--dry-run` as the recommended first step before any
      upgrade.
- [ ] Update `.workspace/plans/2026-07-25-apply-harness-1.5.0-to-homographormer.md`: **delete Phase H2** (the
      manual rescue) and replace it with "run `--dry-run` first; the guide now arrives as `.new`". Also drop the
      "Framework-side follow-up" note at its end — this plan supersedes it.

## Acceptance Criteria

1. `upgrade --dry-run` (all three entry points) writes **zero** bytes and reports the same classification the real
   run would produce.
2. A file the project authored at a path the framework later claimed is **never overwritten** — it gets `.new`.
3. A genuine pre-1.3.0 project still upgrades via the overwrite path, unchanged.
4. The user is told, at the end of an upgrade, which new commands need hand-registering and where.
5. `harness-manifest.json`'s `_baselinesComment` matches actual behavior.
6. The Homographormer plan no longer needs a manual rescue step.

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
