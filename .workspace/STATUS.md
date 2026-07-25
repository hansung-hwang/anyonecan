# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-25
**Active plan**: — (none; 1.5.0 finished, all phases T0-T4 done, not yet committed/pushed)

## Current Goal

No active implementation task. The team-roles/project-mode feature (Harness 1.5.0) is complete —
`.workspace/plans/2026-07-23-team-roles-and-project-mode.md` marked Done, all four phases verified with real
generations/upgrades/dry runs, not just review. **T4 (the last phase) is not yet committed.**

**Uncommitted right now**: `harness-core/HARNESS-VERSION` (1.4.0 → 1.5.0), `FRAMEWORK-CHANGELOG.md` (1.5.0 entry),
`README.md` (Solo/Team documentation), plus this session's final `.workspace/*` doc updates. Left for the user to
review/commit.

## Progress

- **Multi-agent coordination (Harness 1.4.0) — Done, pushed, and fully validated.** All six gates passed; its one
  open caveat was closed 2026-07-25. Full detail in `.workspace/plans/2026-07-22-multi-agent-coordination.md`.
- **1.4.0 validation caveat — closed (2026-07-25), commits `f3b9e34` + `52820ab`**: got working toolchains in this
  Node-18.17/no-admin environment (pnpm 10; `uv` via `pip install --user`). Root `pnpm validate` and
  generated-project `validate.sh` (TS + Python) all pass. Found and fixed two real bugs in `setup.ps1`/`setup.sh`'s
  install step — see `HARNESS-CHANGELOG.md`'s 2026-07-25 entry. **Java/Maven remain unavailable** in this
  environment (no toolchain; `winget` blocks on an interactive ToS prompt).
- **Team roles & project mode (Harness 1.5.0) — Done (2026-07-25).** All four phases complete and verified;
  `.workspace/plans/2026-07-23-team-roles-and-project-mode.md` has the full record. Summary:
  - **T1** (`2044a28`): `setup.ps1`/`setup.sh` Solo/Team prompt; `.harness-meta.json` `projectMode`/`roles`/`roster`;
    conditional `Team & Roles` AGENTS scaffold.
  - **T2** (`9c1126c`): the `/team` command (root + harness-core), registered everywhere check-sync requires.
  - **T3** (`8b98bbb`): documented the in-role convention in the multi-agent guide's §13; **two real dry runs with a
    fresh agent found and closed a real gap** — the escalation note's location was unspecified in run 1 (agent had
    to infer it), fixed to a concrete path, confirmed by run 2 ("given verbatim, not inferred").
  - **T4** (uncommitted): `HARNESS-VERSION` → 1.5.0, `FRAMEWORK-CHANGELOG.md` entry, README documentation. Completed
    the fresh-generation matrix with Java (structural only — no JDK/Maven here, same limitation as 1.4.0's M4).
    Ran a **real upgrade matrix** via disposable `git worktree` checkouts (not simulation): a Team-mode project
    generated pre-T4 with real `roles`/`roster` data survived upgrade byte-for-byte (only `.harness-meta.json`'s
    `baselines`/`harnessVersion` and the version file itself changed); a genuinely pre-1.5.0 Solo project upgraded
    cleanly with `team.md` delivered as a new file and **zero** `projectMode`/`roles`/`roster` keys spontaneously
    added — confirming "Solo unaffected" structurally, not just by assertion. Both upgraded projects' `validate.sh`
    still pass.
  - **Java/Maven caveat carries forward**: Java's own `validate.sh` (via `mvn`) has still never run end-to-end in
    this environment — the one language pack whose *build* is unverified, though its *generation* (Solo/Team,
    `.harness-meta.json`, package structure) is fully verified.
- `agentic-eacc-mcp-server` (external project) was upgraded 1.2.0 → 1.3.0 in an earlier session, on its still-unmerged
  `chore/harness-upgrade-1.2.0` branch (commit `e0d9c70`, on top of `d40aa6c`). Merging/pushing that branch is the
  user's call, not made in any session so far — unrelated to this repo's own work, carried forward as a reminder.

## Next Steps

1. **User's call, first**: review and commit the Phase T4 diff (`harness-core/HARNESS-VERSION`,
   `FRAMEWORK-CHANGELOG.md`, `README.md`) — currently uncommitted. This closes out the entire 1.5.0 plan.
2. **User's call, whenever**: push this session's commits to `origin/main` (currently 5 ahead: the setup.ps1/sh
   install-step fix, the 1.4.0-caveat-closure docs, and 1.5.0's T1/T2/T3 — plus T4 once committed).
3. **User's call, whenever**: merge/push `chore/harness-upgrade-1.2.0` in the `agentic-eacc-mcp-server` repo.
4. **User's call, whenever a toolchain/admin environment is available**: validate the Java language pack's
   `validate.sh` (`mvn verify`) — still the one thing about Java never confirmed end-to-end in this environment.
5. **No plan currently active.** Next implementation work (if any) starts fresh — nothing sequenced or blocked.

## Blockers / Open Questions

- None. Both existing plans (1.4.0, 1.5.0) are Done. Java/Maven build validation is deferred to a future
  toolchain-complete environment — a known, documented limitation, not a design or implementation blocker.
