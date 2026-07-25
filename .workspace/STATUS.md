# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-25
**Active plan**: — (none; 1.4.0 finished, closed out, and pushed; this session closed its one open caveat)

## Current Goal

No active implementation task. The multi-agent coordination feature (Harness 1.4.0) is complete, closed out, and
now fully validated (see below — its one open caveat is resolved). Natural next task is the team-roles/project-mode
feature (Harness 1.5.0), whose design is fully done (Gate T0 closed) but implementation hasn't started; see
`.workspace/plans/2026-07-23-team-roles-and-project-mode.md`.

**Uncommitted right now**: `setup.ps1` and `setup.sh` (bug fix, see below) plus `HARNESS-CHANGELOG.md` — left for
the user to review/commit, not committed automatically.

## Progress

- **Multi-agent coordination (Harness 1.4.0) — Done and pushed**, all six gates (M0–M6) passed
  (`.workspace/plans/2026-07-22-multi-agent-coordination.md`). Summary: designed against real evidence from a
  generated-project incident, audited against this repo's actual enforcement (check-sync.mjs, harness-manifest.json,
  the three upgrade scripts), then deliberately scoped down after a complexity-budget review — shipped the guide,
  an always-on AGENTS "Handoff and Reporting" section, `/coordinate`, and `/plan`'s optional Parallelization block;
  deferred `/start`/`/commit`/`/review`/`/done` prompt edits and a mechanical scope checker to 1.5.0 so solo users
  see zero overhead. Added a light multi-human collaboration layer (PR review as the Coordinator's integration
  gate). Verified end-to-end against real artifacts, not simulation: M1 prototyped in root `AGENTS.md`/`docs/how-to/`
  (found and fixed two bugs during self-review), M2 generalized it into `harness-core/`, M3 bumped
  `HARNESS-VERSION` to 1.4.0, M4 generated real TypeScript/Python/Java projects via `setup.ps1` and confirmed
  identical delivery, M5 upgraded a real disposable 1.3.0 project (via a temporary `git worktree`) to 1.4.0 and
  confirmed the customization-safety contract holds — finding and fixing an unrelated pre-existing bug in the
  process (`upgrade.ps1`/`upgrade.py` never updated `.harness-meta.json`'s own `harnessVersion` field). A
  post-close-out audit then checked every in-scope item against the actual files (not just re-reading the plan)
  and found one real discrepancy — root's guide copy still had its M1-prototype §13 title while harness-core's
  copy already matched the spec — fixed to match. All 9 commits (`787e7b3`..`671c13b`) are pushed to
  `origin/main`. Full detail in the plan file and `worklog.md`'s two 2026-07-24 rows.
- **Former open caveat — now closed (2026-07-25)**: got working toolchains in this same Node-18.17/no-admin
  environment (pnpm 10 via a user-writable npm `--prefix` install — pnpm 11+ needs Node ≥22.13, and pnpm 8/9
  choke on this repo's `pnpm-workspace.yaml` `allowBuilds` key; `uv` via `pip install --user`). Ran root
  `pnpm validate` (typecheck/lint/test all pass) and, for TypeScript and Python, generated a fresh project via
  `setup.ps1` and ran its `validate.sh` end-to-end (both pass). While doing this, found and fixed two real bugs in
  `setup.ps1`/`setup.sh`'s dependency-install step — see `HARNESS-CHANGELOG.md`'s 2026-07-25 entry: (1) the
  success message printed unconditionally regardless of the install command's exit code, and (2) `setup.ps1`
  additionally promoted routine installer stderr into a terminating exception (via `2>&1` under a global
  `$ErrorActionPreference = "Stop"`), aborting the install step mid-run even though the child process kept
  installing in the background. Both fixed and re-verified against fresh TS/Python generations post-fix.
  **Java/Maven remain unavailable**: no `java`/`javac`/`mvn` on PATH, and `winget` requires interactively accepting
  Microsoft Store terms before resolving *any* package (blocks non-interactively); did not touch system-level
  winget source config to force past it. This is the one language pack still never validated end-to-end in this
  environment — pick up if/when a toolchain-complete (or admin) environment is available.
- **Uncommitted changes from this session**: `setup.ps1`, `setup.sh` (the bug fix above), `HARNESS-CHANGELOG.md`.
  Not committed — user's call.
- **Team roles & project mode (Harness 1.5.0, provisional) — design done, Gate T0 closed, implementation not
  started** (`.workspace/plans/2026-07-23-team-roles-and-project-mode.md`). Setup-time Solo/Team mode (changeable
  anytime via a new `/team` command), a 7-role catalog (Planner, Architect, Backend, Frontend, Data/DBA, Infra, QA)
  with Reviewer as a rotating hat rather than a fixed role, role ownership mapped onto the existing
  clean-architecture layers instead of a new ACL system, `.harness-meta.json`-stored mode/roles/roster treated as
  user data upgrade never overwrites, prose-only enforcement in 1.5.0 (mechanical `check-agent-scope` deferred to
  1.6.0). Explicitly sequenced after 1.4.0 since it reuses that feature's primitives (handoff rules, ownership
  matrix, PR gate, check-sync parity/manifest guard).
- `agentic-eacc-mcp-server` (external project) was upgraded 1.2.0 → 1.3.0 in an earlier session, on its still-unmerged
  `chore/harness-upgrade-1.2.0` branch (commit `e0d9c70`, on top of `d40aa6c`). Merging/pushing that branch is the
  user's call, not made in any session so far — unrelated to this repo's own work, carried forward as a reminder.

## Next Steps

1. **User's call, first**: review and commit `setup.ps1`/`setup.sh`/`HARNESS-CHANGELOG.md` (the install-step bug
   fix from this session) — currently uncommitted.
2. **Optional next implementation task**: start Phase T1 of the team-roles/project-mode plan (1.5.0) — Gate T0 is
   already closed, so this can begin whenever picked up; not started because it's explicitly sequenced after 1.4.0
   landing, and no further design decisions are needed first.
3. **User's call, whenever**: merge/push `chore/harness-upgrade-1.2.0` in the `agentic-eacc-mcp-server` repo.
4. **User's call, whenever a toolchain/admin environment is available**: validate the Java language pack's
   `validate.sh` (still the one language never run end-to-end — see caveat above).

## Blockers / Open Questions

- None. Both plans have their design gates fully closed. Java/Maven validation is deferred to a future
  toolchain-complete environment, not a design or implementation blocker.
