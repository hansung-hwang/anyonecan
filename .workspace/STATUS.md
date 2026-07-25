# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-25
**Active plan**: — (none; both existing plans, 1.4.0 and 1.5.0, are Done and fully committed)

## Current Goal

No active implementation task. Harness 1.5.0 (team roles & project mode) is complete: all four phases plus a
post-close-out audit fix are committed. Working tree is clean (only the pre-existing untracked `Homographormer/`
remains, unrelated to this session). Nothing queued — next work starts fresh whenever picked up.

## Progress

- **Multi-agent coordination (Harness 1.4.0) — Done, pushed, and fully validated.** Full detail in
  `.workspace/plans/2026-07-22-multi-agent-coordination.md`.
- **1.4.0 validation caveat — closed (2026-07-25), commits `f3b9e34` + `52820ab`.** Found and fixed two real bugs
  in `setup.ps1`/`setup.sh`'s install step. **Java/Maven remain unavailable** in this environment (no toolchain;
  `winget` blocks on an interactive ToS prompt).
- **Team roles & project mode (Harness 1.5.0) — Done and fully committed (2026-07-25).**
  `.workspace/plans/2026-07-23-team-roles-and-project-mode.md` has the full phase-by-phase record plus a
  "Post-close-out audit" section. Commits: `2044a28` (T1), `9c1126c` (T2), `8b98bbb` (T3), `c63bfae` (T4),
  `3a3ae41` (post-close-out audit fix). Summary:
  - **T1/T2**: Solo/Team config model + setup, the `/team` command.
  - **T3**: documented the in-role convention; two dry runs found and fixed a real gap (escalation note location
    was unspecified — made concrete, confirmed).
  - **T4**: version bump to 1.5.0, changelog, README, Java added to the fresh-gen matrix (structural), and a real
    upgrade matrix via disposable `git worktree`s (Team data survives, Solo genuinely unaffected).
  - **Post-close-out audit** (user explicitly asked to check the plan was actually followed): found and fixed two
    more real gaps — (1) the 1.4.0-deferred `/start`/`/commit`/`/review`/`/done` edits weren't formally recorded
    as "still deferred" (n=2 not met), now documented as a decision; (2) a **live** `/team` run (the first time
    the command was actually executed by an agent, not just reviewed or manually simulated) found `/team`'s
    `.harness-meta.json` step had no worked JSON example — fixed with an explicit shape + example, verified
    across three live runs.
  - **Java/Maven caveat carries forward**: Java's `validate.sh` (`mvn verify`) has never run end-to-end in this
    environment; generation (Solo/Team, `.harness-meta.json`, package structure) is fully verified, the build isn't.
- `agentic-eacc-mcp-server` (external project) was upgraded 1.2.0 → 1.3.0 in an earlier session, on its still-unmerged
  `chore/harness-upgrade-1.2.0` branch (commit `e0d9c70`, on top of `d40aa6c`). Merging/pushing that branch is the
  user's call, not made in any session so far — unrelated to this repo's own work, carried forward as a reminder.

## Next Steps

1. **User's call, whenever**: push this session's 8 commits to `origin/main` — explicitly held back per the
   user's request this session, not yet done.
2. **User's call, whenever**: merge/push `chore/harness-upgrade-1.2.0` in the `agentic-eacc-mcp-server` repo.
3. **User's call, whenever a toolchain/admin environment is available**: validate the Java language pack's
   `validate.sh` (`mvn verify`) — still the one thing about Java never confirmed end-to-end in this environment.
4. **No plan currently active.** Next implementation work (if any) starts fresh — nothing sequenced or blocked.

## Blockers / Open Questions

- None. Both existing plans (1.4.0, 1.5.0) are Done. Java/Maven build validation is deferred to a future
  toolchain-complete environment — a known, documented limitation, not a design or implementation blocker.
