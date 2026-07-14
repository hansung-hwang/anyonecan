# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-14
**Active plan**: none — both 1.3.0-related plans closed out

## Current Goal

No active plan. Harness 1.3.0 shipped (`af1698f`) and its two immediate
follow-ups are both done this session:
1. Fixed 2 pre-existing lint bugs in `language-packs/python`'s own sample
   code (found via `/fix`, root-caused as a process gap, doc fix added).
2. Re-upgraded `agentic-eacc-mcp-server` to 1.3.0, manually re-merging its
   3 known customizations on top of the new templates (which themselves
   carried real fixes from this session, so a blind revert wasn't safe).

## Progress

- `/fix` applied for finding #1: `language-packs/python/tests/arch/test_dependencies.py`
  (E501) and `tests/domain/test_user.py` (F401) fixed directly; root
  cause was that this repo's own `pnpm validate` can never exercise a
  Python pack's sample code (no Python toolchain at the root), so a
  process step was added to `docs/how-to/adding-a-language-pack.md` §7:
  re-run the pack's own `validate.sh`/`.ps1` after *any* edit to shipped
  pack code, not only when adding a new pack. Recorded in
  `HARNESS-CHANGELOG.md`. Root `pnpm validate` reconfirmed clean after.
- `agentic-eacc-mcp-server` upgraded 1.2.0 → 1.3.0 on its still-unmerged
  `chore/harness-upgrade-1.2.0` branch (commit `e0d9c70`, on top of
  `d40aa6c`). Pre-1.3 fallback applied (project had no baselines yet) —
  reviewed the overwrite diff file-by-file rather than blanket-reverting:
  kept the RAG arch-test customization + calendar/zoneinfo stdlib entries
  (re-merged onto the *new* template, which also had this session's E501
  fix), kept the project's own `.pytest-tmp`/no-cache pytest flags in
  `validate.ps1`, kept `.claude/settings.json` pointing at the project's
  Korean-commented `worklog-context.sh` (deleted the redundant
  framework-added `status-context.sh` duplicate), and accepted
  `validate.sh`'s venv-detection rewrite and the new
  `test_project_rules.py` seed as pure improvements. Verified: mypy 46
  files clean, ruff clean, pytest 195 passed / 1 skipped.
- Branch `chore/harness-upgrade-1.2.0` (now carrying both the 1.2.0 and
  1.3.0 upgrades) is still **not merged to `master`** in the eacc repo —
  that decision is the user's, not made this session.

## Next Steps

- None queued. If new framework work comes up, start a plan via `/plan`.
- User's call, whenever: merge/push `chore/harness-upgrade-1.2.0` in the
  `agentic-eacc-mcp-server` repo.

## Blockers / Open Questions

- (none)
