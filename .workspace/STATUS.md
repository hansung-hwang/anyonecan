# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-14
**Active plan**: `.workspace/plans/2026-07-14-harness-1.3.0-customization-safety.md` (Done — implementation + verification complete, commit pending approval)

## Current Goal

Harness 1.3.0 implemented and E2E-verified on Windows: customization-safety
upgrade protection (baseline hash + `.new` pattern) + 5 methodology
backports from the eacc-mcp-server project. **Awaiting user approval to
commit** — nothing committed yet in this session for the 1.3.0 work.

## Progress

- Plan `2026-07-14-apply-harness-1.2.0-to-eacc-mcp.md`: Done, committed in
  eacc repo (`d40aa6c`).
- Plan `2026-07-14-harness-1.3.0-customization-safety.md`: Done.
  Implemented: baseline-hash + `.new` protection in
  setup.ps1/setup.sh/upgrade.ps1/upgrade.py; ADR-001 reclassified to
  bootstrapIfMissing; new `bootstrapLanguageSpecific` manifest section +
  3 project-rules arch-test seeds; SessionStart hook
  (`status-context.sh`) wired into all 3 language packs; AGENTS.md Key
  Invariants section + doc-sync wording; python validate.sh venv
  detection + new validate.ps1; start.md plans-status-grep step (4.5).
  HARNESS-VERSION 1.2.0 → 1.3.0, FRAMEWORK-CHANGELOG entry, README +
  adding-a-language-pack.md updated.
- Verified end-to-end on Windows via real setup.ps1/upgrade.ps1 runs in a
  scratch project (since deleted): baseline recording, no-op on
  unmodified, customized-file protection (`.new` + baseline held), manual
  merge catch-up (baseline advances, stale `.new` cleaned up), pre-1.3
  meta fallback (legacy overwrite + warning + baseline backfill),
  SessionStart hook + validate.ps1 real execution, check-sync + bash -n.
  All scenarios behaved as designed.

## Next Steps

1. User reviews `git status`/`git diff` for the 1.3.0 changes, approves a
   commit message.
2. Separate, out-of-scope finding to report: `language-packs/python`'s own
   template files have 2 pre-existing lint issues (unrelated to this
   session's changes) — E501 in `tests/arch/test_dependencies.py:102`,
   F401 unused import in `tests/domain/test_user.py:9`. Candidate for a
   quick `/fix` in a future session.
3. Follow-up (separate task): re-run `upgrade.ps1` against
   `agentic-eacc-mcp-server` once 1.3.0 is committed, so it gains a
   `baselines` map and its 3 known customizations become protected going
   forward.

## Blockers / Open Questions

- `.sh` scripts (setup.sh, upgrade.sh which calls upgrade.py) were only
  `bash -n` syntax-checked, not run end-to-end — no Mac/Linux in this
  environment (same longstanding constraint as prior sessions).
