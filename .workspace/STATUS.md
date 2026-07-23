# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-24
**Active plan**: — (none; the last active plan finished and closed out this session)

## Current Goal

No active implementation task. The multi-agent coordination feature (Harness 1.4.0) is complete and closed out —
see below. Natural next task is the team-roles/project-mode feature (Harness 1.5.0), whose design is fully done
(Gate T0 closed) but implementation hasn't started; see `.workspace/plans/2026-07-23-team-roles-and-project-mode.md`.

## Progress

- **Multi-agent coordination (Harness 1.4.0) — Done**, all six gates (M0–M6) passed
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
  process (`upgrade.ps1`/`upgrade.py` never updated `.harness-meta.json`'s own `harnessVersion` field). Seven
  commits: `787e7b3`, `240bc9a`, `5e766f5`, `7b36860`, `527499b`, `707a81a`, `6af3106`. Full detail in the plan file
  and `worklog.md`'s 2026-07-24 row.
- **Open caveat (not a defect, an environment limitation)**: `pnpm`/`uv`/`mvn` are unavailable in this session's
  environment (Node 18.17, no admin rights — `corepack enable` failed with `EPERM`), so the full `pnpm validate`
  (root) and each generated project's `validate.sh` have never actually been run end-to-end for this feature.
  Every check that *could* run in this environment did (`node scripts/check-sync.mjs` — the exact first step
  `pnpm validate` invokes — passed after every edit; real `setup.ps1`/`upgrade.ps1` runs were exercised via M4/M5).
  **Action for the next session (or the user, whenever convenient)**: run `pnpm validate` at the repo root and
  `validate.sh` inside a freshly generated project, in an environment with the three toolchains installed, before
  treating this release as fully verified.
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

1. **User's call, whenever convenient**: run full `pnpm validate` + a generated project's `validate.sh` in an
   environment with `pnpm`/`uv`/`mvn` installed, to close the one open caveat on the 1.4.0 release above.
2. **Optional next implementation task**: start Phase T1 of the team-roles/project-mode plan (1.5.0) — Gate T0 is
   already closed, so this can begin whenever picked up; not started because it's explicitly sequenced after 1.4.0
   landing, and no further design decisions are needed first.
3. **User's call, whenever**: merge/push `chore/harness-upgrade-1.2.0` in the `agentic-eacc-mcp-server` repo.

## Blockers / Open Questions

- None. Both plans have their design gates fully closed; the only outstanding item is the environment-dependent
  validation run in Next Steps item 1, which isn't a design or implementation blocker.
