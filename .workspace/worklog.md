# WORKLOG

Append-only log of completed work sessions. Run `/done` at the end of each
session to add an entry — never edit or delete past rows.

## Format

| Date | Summary | Files Changed | Plan |
|------|---------|----------------|------|
| YYYY-MM-DD | What was done | key files/dirs touched | `.workspace/plans/xxx.md` (or —) |
| 2026-07-13 | Added `.workspace/` work journal + `/plan` `/done` commands (harness-core + root). P1 done: AGENTS.md is now the single rule source; CLAUDE.md/.cursorrules/.windsurfrules/harness.mdc reduced to pointers; setup scripts narrowed; `scripts/check-sync.mjs` added as a drift regression guard. Fixed a `setup.sh` perl multi-`-e` bug found during verification. Committed as f34eb77. | `.workspace/`, `.claude/commands/`, `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.windsurfrules`, `harness-core/*` (same set), `setup.ps1`, `setup.sh`, `scripts/check-sync.mjs`, `scripts/validate.sh`, `package.json`, `README.md` | `.workspace/plans/2026-07-13-harness-upgrade-p1-p5.md` |
| 2026-07-13 | P2 done: added `HARNESS-VERSION` + `harness-manifest.json` + `upgrade.ps1`/`upgrade.sh`/`upgrade.py` so existing generated projects can pull in framework updates. `setup.ps1`/`setup.sh` now write `.harness-meta.json`. Verified end-to-end (generate → simulate staleness → upgrade → diff) on both Windows and Mac/Linux paths; found and fixed 3 real bugs during verification: ADR-001's `{{DATE}}` placeholder regression, language-pack-overlaid files (settings.json/ci.yml/husky) being silently downgraded when misclassified as language-agnostic, and CRLF/LF checkout noise causing spurious "changed" reports. Documented the version-bump rule in `AGENTS.md` + `README.md`, added `FRAMEWORK-CHANGELOG.md`. | `harness-core/HARNESS-VERSION`, `harness-core/harness-manifest.json`, `upgrade.ps1`, `upgrade.py`, `upgrade.sh`, `setup.ps1`, `setup.sh`, `AGENTS.md`, `README.md`, `FRAMEWORK-CHANGELOG.md` | `.workspace/plans/2026-07-13-harness-upgrade-p1-p5.md` |
