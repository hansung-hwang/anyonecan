# Apply Harness 1.6.0 to Homographormer

- **Date**: 2026-07-25 (retargeted to 1.6.0 on 2026-07-26 — see sequencing note)
- **Status**: In Progress (plan only; no changes made to Homographormer yet)
- **Target project**: `C:\anyonecan_harness\anyonecan\Homographormer` — its own git repo (HEAD `e719135`, clean),
  Python pack, Korean comment language, currently **Harness 1.3.0**
- **Upgrade path**: 1.3.0 → 1.6.0 (**skips 1.4.0/1.5.0** — this project never received the multi-agent or
  team-roles releases; retargeted from the original 1.3.0 → 1.5.0 once 1.6.0 landed, so this only needs running once)
- **Precedent**: `.workspace/plans/2026-07-14-apply-harness-1.2.0-to-eacc-mcp.md` (same shape: applying a framework
  release to an external project from this repo's workspace)
- **⚠ Sequencing — read before executing this plan.** Two framework plans were written *after* this one, both
  triggered by what this upgrade exposed. **Both are now done.**
  1. `.workspace/plans/2026-07-25-upgrade-tooling-safety-and-dry-run.md` — **done, 2026-07-26.** Added `--dry-run`
     and stopped upgrade from overwriting project-authored files. **This deleted this plan's riskiest step (the
     old Phase H2 manual rescue) — the guide is now protected structurally, not by a manual step below.** Verified
     directly against this real project (not a copy): a `--dry-run` run confirmed
     `docs/how-to/multi-agent-collaboration.md` now reports as "1 file(s) newly managed" / `.new`, not overwritten.
  2. `.workspace/plans/2026-07-25-file-ownership-rules.md` — **done, 2026-07-26.** Ships `docs/how-to/file-ownership.md`
     and the "put project-specific docs in `docs/guides/`" rule. Its Phase H2 relocation note below is now
     actionable: once this project's guide is merged and moved to `docs/guides/`, the recurring `.new` this plan's
     original Acceptance Criterion 7 warned about stops recurring entirely (the path conflict is resolved, not
     just made non-destructive).

## Goal

Bring Homographormer from 1.3.0 to 1.6.0 **without touching its own source code**, and without destroying the
project-specific harness customizations it has accumulated — particularly a heavily customized, Korean-language
multi-agent guide that the framework would otherwise overwrite.

## Evidence: two real dry runs were performed

**Original finding (2026-07-25, pre-fix)** — a faithful copy of the project (same git HEAD, clean tree) was made in
that session's scratchpad, the actual `upgrade.py` from that session's tree was run against it, the results were
recorded below, and the copy was deleted. **The real Homographormer was never modified** — verified still at
`HARNESS-VERSION` 1.3.0 with a clean `git status` after the exercise.

```
Old version : 1.3.0   New version : 1.5.0   Language : python

OK: 2 file(s) added:      .claude/commands/coordinate.md
                          .claude/commands/team.md
OK: 2 file(s) updated:    .claude/commands/plan.md
                          .workspace/plans/README.md
! 1 file(s) overwritten (no baseline recorded -- review with git diff):
                          docs/how-to/multi-agent-collaboration.md
! 2 file(s) customized locally -- left untouched, new template written as '<file>.new':
                          scripts/lint-format-hook.sh      -> .new
                          tests/arch/test_dependencies.py  -> .new
```

**Re-run after the fix (2026-07-26, against the real on-disk project, not a copy — `--dry-run` is now provably
zero-write, verified separately in the tooling plan)**:

```
Old version : 1.3.0   New version : 1.5.0   Language : python

OK: 2 file(s) added:      .claude/commands/coordinate.md
                          .claude/commands/team.md
OK: 2 file(s) updated:    .claude/commands/plan.md
                          .workspace/plans/README.md
! 2 file(s) customized locally -- left untouched, new template written as '<file>.new':
                          scripts/lint-format-hook.sh      -> .new
                          tests/arch/test_dependencies.py  -> .new
! 1 file(s) newly managed by the framework -- your existing file was kept, new template written as '<file>.new':
                          docs/how-to/multi-agent-collaboration.md -> .new
```

The guide moved from the `overwritten` bucket to its own `newly managed` bucket — **it is no longer touched by
upgrade at all**, real or dry-run. This is the structural fix; everything below is updated to match.

### The user's hard requirement is structurally satisfied

`git diff --name-only` after the dry run touched **zero** source files. Confirmed no changes under `src/`,
`HomoGraphormer/`, or any research/data directory. `upgrade` only ever writes paths listed in
`harness-manifest.json`, and none of this project's source lives there. **Requirement met — source code is not at
risk.**

## The original hazard (now closed structurally, not by a manual step)

`docs/how-to/multi-agent-collaboration.md` would previously have been **silently overwritten** — 735 lines
changed, net −186. This is why the original finding still matters even though the hazard itself is gone: it's the
only reason to look closely at Phase H2 below instead of skipping straight past this file.

**Why it used to happen (not a bug in this project, a real gap in the framework, now fixed):** upgrade protects a
file only when it has a *baseline hash* recorded in `.harness-meta.json`. This project was generated at 1.3.0,
when that file did not exist in the manifest — so no baseline was ever recorded for it. The project then
hand-wrote its own file at that exact path (commit `2e2b21a`, "멀티 agent 가이드 신설"). At 1.4.0 the framework
added the same path to `frameworkOwned`. `upgrade.py`'s old logic treated "framework-owned file that exists but
has no baseline" as *pre-1.3.0 legacy* and fell back to unconditional overwrite — regardless of whether that
absence meant "predates all baseline tracking" or "predates only this one path." **Fixed**: the two cases are now
split (`.workspace/plans/2026-07-25-upgrade-tooling-safety-and-dry-run.md`, D1) — a path with no baseline entry
but an existing file, on a project that otherwise has baseline tracking, is now treated as project-authored and
gets `.new` treatment like any other customization.

**What would have been lost** — this is not a stale template, it is substantial irreplaceable work, which is why
Phase H2 below still exists (to port genuinely new upstream content into it) even though nothing is at risk of
being destroyed anymore:

- Written **entirely in Korean** (matching the project's `commentLanguage`)
- **Project-specific agent roles** that do not exist in the framework: `Cache/Artifact Agent — 캐시와 provenance`,
  `Experiment Agent — 실행 계약과 결과 검증`, `Baseline/Research Agent — 공식 구현 감사`
- **§6 "현재 Phase 0의 권장 배정"** — concrete Wave 0-3 assignments for this project's actual research phases
  (Kaggle 외부 실행, 3단계 manifest, 연구 계약 테스트)
- **§13 "사고 기록"** — the project's own incident record explaining where its AGENTS.md handoff rules came from

## Approach

**Always run `--dry-run` first** and confirm the output matches what's recorded above before running for real —
cheap insurance, and now the recommended first step for any upgrade. The guide itself needs no rescue: upgrade
never touches it. It arrives as `docs/how-to/multi-agent-collaboration.md.new` alongside the untouched original,
handled by the same merge procedure as the project's other two customizations (Phase H4) — diff, port anything
worth adopting, delete the `.new`. Once merged, the guide's `.new` disappears from the manifest run and the
project's file remains **outside baseline tracking for that path** until the project chooses to align it — merging
`.new` in without matching its content byte-for-byte is fine; the file will keep offering `.new` on future
upgrades until it either matches the incoming template exactly or the project's `.harness-meta.json` deliberately
whitelists it, whichever comes first (companion plan `2026-07-25-file-ownership-rules.md` designs the latter).

## Steps

### Phase H0 — Pre-flight (do not skip)

- [ ] Confirm `git status` in Homographormer is clean and note the exact HEAD SHA as the rollback point
      (currently `e719135`; re-check at execution time, it may have moved).
- [ ] Confirm the framework repo is at 1.6.0 **and has both the tooling fix and the file-ownership rules**
      (`harness-core/HARNESS-VERSION` = 1.6.0; `upgrade.ps1`/`upgrade.py`/`upgrade.sh` support `-DryRun`/`--dry-run`
      and the newly-managed `.new` behavior; `docs/how-to/file-ownership.md` exists — both implemented 2026-07-26,
      commit SHA not yet fixed at time of writing; re-check `git log --oneline -5` at execution time). Do not run
      this plan against a pre-fix `upgrade` — it will overwrite the guide again.
- [ ] Create a working branch in Homographormer, e.g. `chore/harness-upgrade-1.6.0` — do **not** upgrade directly
      on its main branch. (Matches the eacc-mcp precedent, which is still on its own upgrade branch.)

### Phase H1 — Preview, then run the upgrade

- [ ] **Preview first**: `python3 upgrade.py <homographormer-path> <framework-repo-path> --dry-run` (or
      `.\upgrade.ps1 -ProjectDir <homographormer-path> -DryRun`) and confirm the output matches the "Re-run after
      the fix" block above: 2 added, 2 updated, 2 customized-locally `.new`, **1 newly-managed `.new`** (the guide
      — not `overwritten`). **If it differs, stop and re-diff** — the project may have changed since this plan was
      written.
- [ ] Run for real (same command, without `--dry-run`/`-DryRun`).
- [ ] Confirm `git status` shows `docs/how-to/multi-agent-collaboration.md` **unchanged** — only
      `docs/how-to/multi-agent-collaboration.md.new` is new/untracked, plus the other two `.new` files and the
      added/updated files from the dry run.

### Phase H2 — Port the genuinely new 1.4.0/1.5.0 content into the project's guide (by hand, Korean)

The project's guide is a translated + customized fork that predates 1.5.0, so it is missing the new role-scoping
layer that pairs with the `/team` command arriving in this upgrade. Unlike before the tooling fix, nothing here is
a rescue — the original file was never touched; this is a deliberate content merge, same shape as Phase H4 below.

- [ ] Compare the project's guide against `docs/how-to/multi-agent-collaboration.md.new` (the incoming framework
      template) and port in, **in Korean, in the project's own voice**: the in-role convention (active role by
      declaration/branch-prefix; edits restricted to the active role's owned scope; cross-role changes escalated
      as a request note to `.workspace/plans/<date>-<short-topic>-request.md` addressed to the owning role).
- [ ] Decide explicitly whether this project wants Team mode at all — it is a solo research project, so **Solo is
      the likely correct answer** and this port may reduce to a short pointer rather than a full section.
      Record the decision either way.
- [ ] Do **not** renumber the project's existing §13/§14 (사고 기록 / Claude Code 실행 수단) to match the
      framework's numbering — the project's sections are its own and diverging numbering is expected.
- [ ] Delete `docs/how-to/multi-agent-collaboration.md.new` once the merge is done (a leftover `.new` re-offers the
      same merge on the next upgrade — harmless, but noisy).
- [ ] **New in the 1.6.0 retarget — relocate the merged guide to `docs/guides/multi-agent-collaboration.md`** (or
      a name of the project's choosing under `docs/guides/`), per `docs/how-to/file-ownership.md`'s rule that
      project-specific documentation belongs there, not in the framework-owned `docs/how-to/`. This is what
      actually closes the recurring-`.new` gap noted in Acceptance Criterion 7 below — without this move, every
      future upgrade re-offers the same merge forever (harmless, but permanent noise); with it, the path conflict
      is gone and `docs/how-to/multi-agent-collaboration.md` on this project simply becomes the plain framework
      guide going forward. Update any links to the old path (this project's own `AGENTS.md`, if it references the
      guide by path).

### Phase H4 — Merge the two `.new` files

Both are real, hard-won fixes that must survive. Merge *the template into the project's file*, not the reverse.

- [ ] `scripts/lint-format-hook.sh` — project adds a Windows backslash-path normalization guard (rediscovered
      2026-07-19) that exempts `*/HomoGraphormer/*` and `*/src/HomoGraphormer_original/*` from the format hook.
      **Keep it.** Diff against `.new` for any upstream changes worth adopting, then delete the `.new`.
- [ ] `tests/arch/test_dependencies.py` — project adds `EXCLUDED_SOURCE_DIRS = {"HomoGraphormer_original"}` and a
      `collect_py_files()` helper so the vendored original implementation is excluded from arch checks.
      **Keep it.** Same procedure, then delete the `.new`.
- [ ] Confirm both `.new` files are gone (a leftover `.new` makes the next upgrade re-offer the same merge).

### Phase H5 — Register the two new commands in user-owned files

`AGENTS.md` and `CLAUDE.md` are user-owned; upgrade never touches them, so the new commands are invisible until
added by hand. Verified absent in the dry run.

- [ ] `AGENTS.md` → Workflow Prompts table: add `coordinate.md` (`/coordinate`) and `team.md` (`/team`) rows,
      **in Korean**, matching the table's existing style.
- [ ] `CLAUDE.md` → Claude Code Extras command list: append `/coordinate`, `/team`.
- [ ] Note: the project's `.harness-meta.json` has **no `projectMode` key** (generated pre-1.5.0). `/team` treats an
      absent value as Solo, which is correct here — no action needed unless the project opts into Team mode.

### Phase H6 — Validate and land

- [ ] Run the project's own `./scripts/validate.sh` (mypy + ruff + pytest via its `.venv`). It must pass —
      especially the arch test, since `tests/arch/test_dependencies.py` was just merged.
- [ ] `git diff` the full branch and confirm **zero** source-code changes (`src/`, `HomoGraphormer/`, research
      dirs) — the user's hard requirement, re-verified on the real thing rather than the dry-run copy.
- [ ] Confirm `HARNESS-VERSION` = 1.6.0 and `.harness-meta.json`'s `harnessVersion` = 1.6.0 (the 1.4.0-era bug
      where the JSON field went stale is fixed in this framework version).
- [ ] Commit on the branch; merging to the project's main branch is the project owner's call.

## Acceptance Criteria

1. Homographormer reports Harness 1.6.0 in both `HARNESS-VERSION` and `.harness-meta.json`.
2. **Zero** changes to project source code, verified by `git diff --name-only` on the real repo.
3. The project's Korean, project-specific multi-agent guide is intact — its custom roles and §6 Phase-0 wave
   assignments still present.
4. Both local customizations (`lint-format-hook.sh` path guard, arch-test exclusion) still in effect; no `.new`
   files left behind.
5. `/coordinate` and `/team` exist and are listed in `AGENTS.md`/`CLAUDE.md`.
6. `./scripts/validate.sh` passes.
7. Upgrade never touches the guide directly — it always arrives as `.new` for review, never overwritten. The
   permanent fix (not just the non-destructive one) is Phase H2's new relocation step: once the merged guide moves
   to `docs/guides/`, that path is never claimed by the manifest, so this `.new` stops recurring entirely from the
   next upgrade onward — verified as the intended mechanism by `2026-07-25-file-ownership-rules.md`'s Phase O4
   live-agent test (a fresh agent given an undirected guide-writing task chose `docs/guides/` on its own, in two
   independent runs).

## Risks

| Risk | Mitigation |
|---|---|
| Someone runs `upgrade` without previewing first and doesn't notice the `.new` files | H1 requires `--dry-run` first; upgrade itself never overwrites the guide now — structurally, not by process. |
| `.new` merge forgotten → new upstream content silently missed on the guide, or a real local fix reverts | H2/H4 both explicitly require deleting each `.new` only after merging; a leftover `.new` is itself the reminder, and is harmless if left (just re-offered next run). |
| Project moved on since this plan (HEAD ≠ `e719135`) | H1 requires the upgrade output to match the dry run exactly, else stop and re-analyze. |
| Merging Korean guide content introduces English drift | H2 explicitly requires porting in Korean, in the project's voice. |
