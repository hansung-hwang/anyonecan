# Apply Harness 1.6.0 to Homographormer

- **Date**: 2026-07-25 (retargeted to 1.6.0 on 2026-07-26 — see sequencing note)
- **Status**: Done, 2026-07-26. Committed on `chore/harness-upgrade-1.6.0` (`d51a7a4`) in the Homographormer repo;
  `main` untouched. Merging to `main` is the project owner's call, not done here.
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

### Phase H0 — Pre-flight (do not skip) — ✅ Done 2026-07-26

- [x] Confirmed `git status` clean and HEAD = `e719135`, exactly matching this plan's recorded rollback point —
      no drift since the plan was written.
- [x] Confirmed framework repo at 1.6.0 with both fixes (committed and pushed as `a5b022f`/`bf3e429`/`ccaf5fa`/
      `a802359`, confirmed on `origin/main`).
- [x] Created `chore/harness-upgrade-1.6.0` branch in Homographormer; `main` never touched.

### Phase H1 — Preview, then run the upgrade — ✅ Done 2026-07-26

- [x] **Previewed first**: `--dry-run` output **differed from this plan's recorded expectation in a fully
      anticipated way** — 3 added (not 2: `docs/how-to/file-ownership.md` is new in 1.6.0), 2 updated, 2
      customized-locally `.new`, **2 newly-managed `.new`** (not 1: `harness-manifest.json` itself joined the guide
      in that bucket, because D5 made it framework-owned in this very release, so no baseline existed for it yet —
      exactly the one-time-caveat behavior documented in the 1.6.0 changelog). This is drift from *the plan's
      1.5.0-era recording*, not drift in the *project* — confirmed by re-checking against the current framework's
      own FRAMEWORK-CHANGELOG.md 1.6.0 entry before proceeding, not treated as a "stop and re-diff the project"
      trigger.
- [x] Ran for real; confirmed via `git status` that `docs/how-to/multi-agent-collaboration.md` was untouched
      (byte-identical) and only the expected `.new`/added/updated files appeared. `git status -- src/
      HomoGraphormer/ results/` empty both before and after.

### Phase H2 — Port the genuinely new 1.4.0/1.5.0 content into the project's guide (by hand, Korean) — ✅ Done 2026-07-26

- [x] Compared the project's guide (610 lines) against the incoming template (387 lines) section-by-section — the
      structure maps 1:1 (roles/worktree/task-template/file-ownership-table/conflict-rules/completion-report/
      merge-procedure/failure-rework/next-session-prompt), just Korean-translated with project-specific role names
      and Wave assignments. **The only genuinely new content was template §13 "Working as a team"** — confirmed
      by grepping the whole template for role/team mentions outside §13 (none found) and comparing §1's principle
      count (7 = 7, no new principles). Ported as a new **§15** (project's own numbering continues past its
      existing §14, per the no-renumbering rule below), in Korean, in the project's voice — a short pointer rather
      than the full section, per the Solo decision below.
- [x] **Decided Team mode: Solo, confirmed not assumed** — checked `.harness-meta.json` (no `projectMode` key,
      pre-1.5.0 generation) and `worklog.md` (no team/collaborator mentions). §15 records this explicitly and
      summarizes what would change if `/team` is ever run, without duplicating the framework guide's content.
- [x] Did **not** renumber the project's existing §13 (사고 기록) / §14 (Claude Code 실행 수단) — confirmed both
      already substantively cover what the template's separate §14 "Why these rules exist" provides (the project's
      §13 is its own concrete-incidents version of the same idea, predating the template's abstract-categories
      version), so no separate port of template §14 was needed either.
- [x] Deleted `docs/how-to/multi-agent-collaboration.md.new` after the merge.
- [x] **Relocated to `docs/guides/multi-agent-collaboration.md`** (`git mv`, preserving history) per
      `docs/how-to/file-ownership.md`'s rule. Updated the two path references in the project's own `AGENTS.md`
      (핸드오프·보고 규약 §, 다중 액터 절) to point at the new location.
- [x] **Found and fixed a consequence of the relocation, not originally in this checklist**: `.claude/commands/
      coordinate.md` and `team.md` (both framework-owned, delivered by this same upgrade) internally reference
      `docs/how-to/multi-agent-collaboration.md` — a path that no longer existed on disk after the `git mv`. Fixed
      correctly (not by hand-editing the framework-owned command files): forced the upgrade's per-file loop to run
      again, which delivered the plain framework template fresh at that path (correctly bucketed as `added`, with
      a proper baseline recorded) — restoring it as an ordinary, unmodified framework file rather than leaving a
      broken internal reference. Also resolved `harness-manifest.json.new` in the same pass (diffed first, confirmed
      it was purely the newer manifest with no project edits, then applied it) — this file wasn't in the plan's
      original H4 scope either, since the D5 "manifest becomes framework-owned" case didn't exist when this plan
      was first written.

### Phase H4 — Merge the two `.new` files — ✅ Done 2026-07-26

- [x] `scripts/lint-format-hook.sh` — diffed against `.new`: the project's version is a **strict superset** of the
      template (the Windows path-normalization guard is the only delta; nothing new to adopt from upstream). Kept
      the project's version, deleted the `.new`.
- [x] `tests/arch/test_dependencies.py` — diffed against `.new`: project's version is likewise a superset
      (`EXCLUDED_SOURCE_DIRS` + the `collect_py_files()` refactor threaded through every test function; no
      upstream-only content). Kept the project's version, deleted the `.new`. **Verified, not just diffed**: ran
      the file directly with `pytest` (stdlib-only, no project `.venv` needed) — 6/6 passed, confirming the
      exclusion logic actually works, not just that the diff looks safe.
- [x] Confirmed both `.new` files gone.

### Phase H5 — Register the two new commands in user-owned files — ✅ Done 2026-07-26

- [x] `AGENTS.md` → Workflow Prompts table: added `coordinate.md`/`team.md` rows. **In English, not Korean** —
      checked the table first and found every existing row already in English (framework boilerplate, never
      translated at generation time despite the project's Korean `commentLanguage`); matched the table's *actual*
      observed style over this plan's literal wording, per "matching the table's existing style" being the actual
      intent.
- [x] `CLAUDE.md` → Claude Code Extras: appended `/coordinate`, `/team`.
- [x] Confirmed `.harness-meta.json` has no `projectMode` key — no action taken, correct per Solo default.

### Phase H6 — Validate and land — ✅ Done 2026-07-26

- [x] **Environment limitation, same class as Java's `mvn`**: this session's environment has no project `.venv`
      (no `uv sync` run), so `scripts/validate.sh` itself can't execute — its fallback logic picks a broken
      `python3` (a Windows Store alias with no `mypy`) over a working system Python that happens to have `mypy`/
      `ruff`/`pytest`/`torch`/`numpy` installed. **Did not skip validation** — ran validate.sh's exact three
      commands manually against the working interpreter instead: `mypy src/` (2 files, clean), `ruff check src/
      tests/` (clean), `pytest` (14/14 passed, `testpaths: tests` per `pyproject.toml` — the accurate full scope).
      This is real validation with real dependencies present, not a partial/simulated substitute.
- [x] `git diff`/`git status` confirmed **zero** changes under `src/`, `HomoGraphormer/`, `results/` — re-verified
      on the real repo, twice (once mid-upgrade, once immediately before commit).
- [x] Confirmed `HARNESS-VERSION` = 1.6.0 **and** `.harness-meta.json`'s `harnessVersion` = 1.6.0 — match, no
      stale-field regression.
- [x] Committed on `chore/harness-upgrade-1.6.0` (`d51a7a4`, Korean commit message matching the project's own
      convention). `main` never touched — merging is the project owner's call. **Real hook-environment issue found
      and fixed correctly, not bypassed**: the same broken-`python3` issue above also blocks the project's own
      `.husky/pre-commit` hook (`bash scripts/validate.sh`). Did not use `--no-verify` — instead created a
      temporary `python3` wrapper (pointing at the working interpreter) scoped to only this commit's `PATH`, so the
      hook's own existing tool-discovery logic succeeded legitimately; removed the wrapper immediately after.

## Acceptance Criteria

1. ✅ Homographormer reports Harness 1.6.0 in both `HARNESS-VERSION` and `.harness-meta.json`.
2. ✅ **Zero** changes to project source code, verified by `git status`/`git diff` scoped to `src/`,
   `HomoGraphormer/`, `results/` on the real repo, checked twice.
3. ✅ The project's Korean, project-specific multi-agent guide is intact at its new location
   (`docs/guides/multi-agent-collaboration.md`) — its custom roles (7 mentions) and Wave assignments (9 mentions)
   confirmed present by direct grep, not assumed from the diff alone.
4. ✅ Both local customizations (`lint-format-hook.sh` path guard, arch-test exclusion) still in effect — the
   latter verified by actually running the merged test file (6/6 passed), not just diffing; no `.new` files left
   behind (confirmed via `find`).
5. ✅ `/coordinate` and `/team` exist and are listed in `AGENTS.md`/`CLAUDE.md`.
6. ✅ `validate.sh`'s exact three commands pass against the real dependency stack (mypy/ruff/pytest with
   torch/numpy present) — the literal script couldn't run due to a `.venv`-less environment (a `python3` PATH
   resolution issue, not a code defect), documented rather than silently worked around.
7. ✅ Upgrade never touches the guide directly, and the permanent fix landed: guide relocated to `docs/guides/`,
   confirmed by re-running the upgrade a second time and observing `docs/how-to/multi-agent-collaboration.md` come
   back as a clean `added` (plain framework template, fresh baseline) rather than a repeat `.new` offer — the
   mechanism verified end-to-end on the real project, not just asserted from the design.

**All seven acceptance criteria met, 2026-07-26.** Committed on `chore/harness-upgrade-1.6.0` (`d51a7a4`) in the
Homographormer repo. `main` untouched; merging is the project owner's decision.

## Risks

| Risk | Mitigation |
|---|---|
| Someone runs `upgrade` without previewing first and doesn't notice the `.new` files | H1 requires `--dry-run` first; upgrade itself never overwrites the guide now — structurally, not by process. |
| `.new` merge forgotten → new upstream content silently missed on the guide, or a real local fix reverts | H2/H4 both explicitly require deleting each `.new` only after merging; a leftover `.new` is itself the reminder, and is harmless if left (just re-offered next run). |
| Project moved on since this plan (HEAD ≠ `e719135`) | H1 requires the upgrade output to match the dry run exactly, else stop and re-analyze. |
| Merging Korean guide content introduces English drift | H2 explicitly requires porting in Korean, in the project's voice. |
