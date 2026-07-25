# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-25
**Active plan**: — (none; 1.5.0 finished, all phases T0-T4 done and committed, then post-close-out audit found and
fixed two real gaps — see below)

## Current Goal

No active implementation task. The team-roles/project-mode feature (Harness 1.5.0) is fully done — plan marked
Done, all four phases committed (`2044a28`, `9c1126c`, `8b98bbb`, `c63bfae`), workspace docs committed (`0bb1e5d`).
A **post-close-out audit** (checking actual files against the plan, not re-reading the plan — same practice as
1.4.0's) then found two real gaps and fixed both; that fix is **not yet committed**.

**Uncommitted right now**: `.claude/commands/team.md` + `harness-core/.claude/commands/team.md` (JSON-shape
clarification for `roles`/`roster`), `FRAMEWORK-CHANGELOG.md`, `.workspace/plans/2026-07-23-team-roles-and-project-mode.md`.
Left for the user to review/commit.

## Progress

- **Multi-agent coordination (Harness 1.4.0) — Done, pushed, and fully validated.** Full detail in
  `.workspace/plans/2026-07-22-multi-agent-coordination.md`.
- **1.4.0 validation caveat — closed (2026-07-25), commits `f3b9e34` + `52820ab`.** Found and fixed two real bugs
  in `setup.ps1`/`setup.sh`'s install step. **Java/Maven remain unavailable** in this environment (no toolchain;
  `winget` blocks on an interactive ToS prompt).
- **Team roles & project mode (Harness 1.5.0) — Done, committed, then audited (2026-07-25).**
  `.workspace/plans/2026-07-23-team-roles-and-project-mode.md` has the full record, including a "Post-close-out
  audit" section. Summary:
  - **T1** (`2044a28`), **T2** (`9c1126c`): Solo/Team config model + setup, the `/team` command.
  - **T3** (`8b98bbb`): documented the in-role convention; two dry runs found and fixed a real gap (escalation
    note location was unspecified — made concrete, confirmed).
  - **T4** (`c63bfae`): version bump to 1.5.0, changelog, README, Java added to the fresh-gen matrix (structural),
    and a **real upgrade matrix** via disposable `git worktree`s (Team data survives, Solo genuinely unaffected —
    confirmed structurally, not asserted).
  - **Post-close-out audit** (after T4, requested explicitly by the user — "계획이 잘 반영됐는지 점검해줘"): found
    two real gaps by checking files, not re-reading the plan:
    1. **Docs-only**: 1.4.0's deferred `/start`/`/commit`/`/review`/`/done` edits weren't formally recorded as
       "still deferred" in 1.5.0's own changelog/plan, even though not un-deferring them was the right call
       (1.4.0's own trigger is n=2, not met). Fixed by recording the decision explicitly in both
       `FRAMEWORK-CHANGELOG.md` and the plan.
    2. **Real gap, found via a live `/team` run** (a fresh agent actually following `.claude/commands/team.md`
       against a real generated project — not a manual dry run, which is all prior verification had used):
       `/team`'s `.harness-meta.json` instructions had no worked example, so multi-word role ids and multi-role
       people were being inferred rather than specified. Fixed with an explicit shape + JSON example (both `team.md`
       copies); verified across three live runs (one test-setup mistake along the way — reused a pre-fix generated
       project — caught and corrected, not counted as a real failure).
  - **Java/Maven caveat carries forward**: Java's `validate.sh` (`mvn verify`) has never run end-to-end in this
    environment; generation (Solo/Team, `.harness-meta.json`, package structure) is fully verified, the build isn't.
- `agentic-eacc-mcp-server` (external project) was upgraded 1.2.0 → 1.3.0 in an earlier session, on its still-unmerged
  `chore/harness-upgrade-1.2.0` branch (commit `e0d9c70`, on top of `d40aa6c`). Merging/pushing that branch is the
  user's call, not made in any session so far — unrelated to this repo's own work, carried forward as a reminder.

## Next Steps

1. **User's call, first**: review and commit the post-close-out audit fix (`.claude/commands/team.md` + harness-core
   copy, `FRAMEWORK-CHANGELOG.md`, the plan file) — currently uncommitted.
2. **User's call, whenever**: push this session's commits to `origin/main` (7 ahead as of the last commit, one more
   pending once the audit fix above is committed) — explicitly held back per the user's request this session.
3. **User's call, whenever**: merge/push `chore/harness-upgrade-1.2.0` in the `agentic-eacc-mcp-server` repo.
4. **User's call, whenever a toolchain/admin environment is available**: validate the Java language pack's
   `validate.sh` (`mvn verify`) — still the one thing about Java never confirmed end-to-end in this environment.
5. **No plan currently active.** Next implementation work (if any) starts fresh — nothing sequenced or blocked.

## Blockers / Open Questions

- None. Both existing plans (1.4.0, 1.5.0) are Done. Java/Maven build validation is deferred to a future
  toolchain-complete environment — a known, documented limitation, not a design or implementation blocker.
