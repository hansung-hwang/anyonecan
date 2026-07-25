# Apply Harness 1.5.0 to Homographormer

- **Date**: 2026-07-25
- **Status**: In Progress (plan only; no changes made to Homographormer yet)
- **Target project**: `C:\anyonecan_harness\anyonecan\Homographormer` — its own git repo (HEAD `e719135`, clean),
  Python pack, Korean comment language, currently **Harness 1.3.0**
- **Upgrade path**: 1.3.0 → 1.5.0 (**skips 1.4.0** — this project never received the multi-agent release)
- **Precedent**: `.workspace/plans/2026-07-14-apply-harness-1.2.0-to-eacc-mcp.md` (same shape: applying a framework
  release to an external project from this repo's workspace)
- **⚠ Sequencing — read before executing this plan.** Two framework plans were written *after* this one, both
  triggered by what this upgrade exposed. **Recommended order: run them first, this plan last.**
  1. `.workspace/plans/2026-07-25-upgrade-tooling-safety-and-dry-run.md` — adds `--dry-run` and stops upgrade
     from overwriting project-authored files. **Landing it deletes this plan's riskiest step (Phase H2).**
  2. `.workspace/plans/2026-07-25-file-ownership-rules.md` — ships the ownership rule so this class of incident
     stops happening. Its Phase O5 also relocates this project's custom guide to a project-owned path.

  Executing this plan *as written* (before those land) is still safe — H2 exists precisely to cover the gap — but
  it costs a manual rescue step that the framework work makes unnecessary.

## Goal

Bring Homographormer from 1.3.0 to 1.5.0 **without touching its own source code**, and without destroying the
project-specific harness customizations it has accumulated — particularly a heavily customized, Korean-language
multi-agent guide that the framework would otherwise overwrite.

## Evidence: a real dry run was already performed

This plan is not written from assumptions. A faithful copy of the project (same git HEAD, clean tree) was made in
this session's scratchpad, the actual `upgrade.py` from the current tree was run against it, the results were
recorded below, and the copy was deleted. **The real Homographormer was never modified** — verified still at
`HARNESS-VERSION` 1.3.0 with a clean `git status` after the exercise.

### Dry-run result (exact upgrade output)

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

### The user's hard requirement is structurally satisfied

`git diff --name-only` after the dry run touched **zero** source files. Confirmed no changes under `src/`,
`HomoGraphormer/`, or any research/data directory. `upgrade` only ever writes paths listed in
`harness-manifest.json`, and none of this project's source lives there. **Requirement met — source code is not at
risk.**

## The one real hazard (must be handled before running upgrade)

`docs/how-to/multi-agent-collaboration.md` will be **silently overwritten** — 735 lines changed, net −186.

**Why it happens (not a bug in this project, a real gap in the framework):** upgrade protects a file only when it
has a *baseline hash* recorded in `.harness-meta.json`. This project was generated at 1.3.0, when that file did not
exist in the manifest — so no baseline was ever recorded for it. The project then hand-wrote its own file at that
exact path (commit `2e2b21a`, "멀티 agent 가이드 신설"). At 1.4.0 the framework added the same path to
`frameworkOwned`. `upgrade.py`'s logic (lines 190-201) treats "framework-owned file that exists but has no
baseline" as *pre-1.3.0 legacy* and falls back to unconditional overwrite. Its own code comment even names this
case: *"or the file was added to the manifest after this project's baseline snapshot."*

**What would be lost** — this is not a stale template, it is substantial irreplaceable work:

- Written **entirely in Korean** (matching the project's `commentLanguage`)
- **Project-specific agent roles** that do not exist in the framework: `Cache/Artifact Agent — 캐시와 provenance`,
  `Experiment Agent — 실행 계약과 결과 검증`, `Baseline/Research Agent — 공식 구현 감사`
- **§6 "현재 Phase 0의 권장 배정"** — concrete Wave 0-3 assignments for this project's actual research phases
  (Kaggle 외부 실행, 3단계 manifest, 연구 계약 테스트)
- **§13 "사고 기록"** — the project's own incident record explaining where its AGENTS.md handoff rules came from

Recoverable via git (own repo, clean tree), but only if someone knows to look. Hence the explicit step below.

## Approach

Run the upgrade, then immediately restore the guide from git and merge deliberately. Restoring *after* the upgrade
(rather than pre-seeding a fake baseline) is preferred because it leaves the metadata in the correct long-term
state: upgrade records the framework template's hash as the new baseline, so once the project's own version is
restored, **every future upgrade will correctly classify this file as "customized" and write `.new` instead of
overwriting** — the hazard closes itself permanently after this one run.

## Steps

### Phase H0 — Pre-flight (do not skip)

- [ ] Confirm `git status` in Homographormer is clean and note the exact HEAD SHA as the rollback point
      (currently `e719135`; re-check at execution time, it may have moved).
- [ ] Confirm the framework repo is at 1.5.0 and pushed (`harness-core/HARNESS-VERSION` = 1.5.0, currently
      `origin/main` = `7695059`).
- [ ] Create a working branch in Homographormer, e.g. `chore/harness-upgrade-1.5.0` — do **not** upgrade directly
      on its main branch. (Matches the eacc-mcp precedent, which is still on its own upgrade branch.)

### Phase H1 — Run the upgrade

- [ ] From the framework repo root: `python3 upgrade.py <homographormer-path> <framework-repo-path>`
      (or `.\upgrade.ps1 -ProjectDir <homographormer-path>` on PowerShell — both were exercised this session).
- [ ] Confirm the output matches the dry run exactly: 2 added, 2 updated, 1 overwritten, 2 `.new`. **If it differs,
      stop and re-diff** — the project may have changed since this plan was written.

### Phase H2 — Rescue the multi-agent guide (the critical step)

- [ ] `git diff docs/how-to/multi-agent-collaboration.md` and confirm it is the expected wholesale replacement.
- [ ] Save the framework's new version for reference:
      `git show :docs/how-to/multi-agent-collaboration.md > /tmp/framework-1.5.0-guide.md` *(or copy it aside)*.
- [ ] **Restore the project's own version**: `git checkout HEAD -- docs/how-to/multi-agent-collaboration.md`.
- [ ] Verify `.harness-meta.json` still carries the framework template's hash for this path — that is what makes
      future upgrades write `.new` instead of overwriting. Do **not** hand-edit it back.

### Phase H3 — Port the genuinely new 1.4.0/1.5.0 content into the project's guide (by hand, Korean)

The project's guide is a translated + customized fork that predates 1.5.0, so it is missing the new role-scoping
layer that pairs with the `/team` command arriving in this upgrade.

- [ ] Compare the project's guide against the saved framework version and port in, **in Korean, in the project's
      own voice**: the in-role convention (active role by declaration/branch-prefix; edits restricted to the active
      role's owned scope; cross-role changes escalated as a request note to
      `.workspace/plans/<date>-<short-topic>-request.md` addressed to the owning role).
- [ ] Decide explicitly whether this project wants Team mode at all — it is a solo research project, so **Solo is
      the likely correct answer** and this port may reduce to a short pointer rather than a full section.
      Record the decision either way.
- [ ] Do **not** renumber the project's existing §13/§14 (사고 기록 / Claude Code 실행 수단) to match the
      framework's numbering — the project's sections are its own and diverging numbering is expected.

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
- [ ] Confirm `HARNESS-VERSION` = 1.5.0 and `.harness-meta.json`'s `harnessVersion` = 1.5.0 (the 1.4.0-era bug
      where the JSON field went stale is fixed in this framework version).
- [ ] Commit on the branch; merging to the project's main branch is the project owner's call.

## Acceptance Criteria

1. Homographormer reports Harness 1.5.0 in both `HARNESS-VERSION` and `.harness-meta.json`.
2. **Zero** changes to project source code, verified by `git diff --name-only` on the real repo.
3. The project's Korean, project-specific multi-agent guide is intact — its custom roles and §6 Phase-0 wave
   assignments still present.
4. Both local customizations (`lint-format-hook.sh` path guard, arch-test exclusion) still in effect; no `.new`
   files left behind.
5. `/coordinate` and `/team` exist and are listed in `AGENTS.md`/`CLAUDE.md`.
6. `./scripts/validate.sh` passes.
7. Future upgrades will no longer threaten the guide (its baseline now differs from its content → `.new` path).

## Risks

| Risk | Mitigation |
|---|---|
| **Guide silently overwritten** (confirmed real, not hypothetical) | Phase H2 restores it from git immediately after upgrade; the post-upgrade baseline state then makes this self-correcting for all future runs. |
| Someone runs `upgrade` without this plan and commits blind | Upgrade prints an explicit `! overwritten (review with git diff)` warning; H0's branch requirement keeps main clean regardless. |
| `.new` merge forgotten → customization silently reverts on a later upgrade | H4 explicitly requires deleting the `.new` only after merging; a leftover `.new` is itself the reminder. |
| Project moved on since this plan (HEAD ≠ `e719135`) | H1 requires the upgrade output to match the dry run exactly, else stop and re-analyze. |
| Merging Korean guide content introduces English drift | H3 explicitly requires porting in Korean, in the project's voice. |

## Framework-side follow-up — now has its own plans (no longer open here)

This exercise surfaced two real framework gaps, independent of Homographormer. Both were written up as their own
plans on the same day; this section is kept as the origin record and is **no longer an open item in this plan**:

1. **Upgrade overwrites project-authored files.** A `frameworkOwned` path that a project created independently
   *before* that path entered the manifest is overwritten, because "no baseline" is treated as "pre-1.3.0 legacy"
   rather than "possibly project-authored." Plus there is no way to preview an upgrade at all.
   → `.workspace/plans/2026-07-25-upgrade-tooling-safety-and-dry-run.md`
2. **The framework never tells a project where the boundary is.** The shipped `AGENTS.md`/`CLAUDE.md` say nothing
   about file ownership, and the only machine-readable map (`harness-manifest.json`) is copied once at setup and
   never refreshed — so it goes stale and creates exactly this trap. This project did nothing wrong: its own
   manifest copy showed `docs/how-to/multi-agent-collaboration.md` as an unclaimed path.
   → `.workspace/plans/2026-07-25-file-ownership-rules.md`
