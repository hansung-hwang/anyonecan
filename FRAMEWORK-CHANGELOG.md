# FRAMEWORK-CHANGELOG

Changelog for **this framework's own evolution** (`harness-core/HARNESS-VERSION`).

Not to be confused with the per-project `HARNESS-CHANGELOG.md` (copied into
every generated project), which tracks agent mistakes and the rules added
to prevent them via `/fix`. This file tracks changes to the framework
itself, so a project owner running `upgrade.ps1`/`upgrade.sh` knows what
they're pulling in.

See `AGENTS.md` → "Framework Versioning" for the bump rule.

## [1.0.0] - 2026-07-13

- Baseline version. Established `HARNESS-VERSION` + `harness-manifest.json`
  + `upgrade.ps1`/`upgrade.sh`/`upgrade.py` so existing generated projects
  can pull in framework updates instead of staying frozen at generation time.
- Added `.workspace/` work journal (`STATUS.md`, `worklog.md`, `plans/`) and
  the `/plan`, `/done` commands so work survives an unplanned session end.
  `/start` now reads `.workspace/STATUS.md`; `/commit` hints at `/done`.
- Made `AGENTS.md` the single source of truth for project rules. `CLAUDE.md`
  shrinks to a header + `@AGENTS.md` import; `.cursorrules`/`.windsurfrules`/
  `.cursor/rules/harness.mdc` shrink to thin pointers. `setup.ps1`/`setup.sh`
  placeholder substitution narrowed to `AGENTS.md` only.
- Added `scripts/check-sync.mjs` (this repo's own drift guard between root
  and `harness-core` command files).
- `setup.ps1`/`setup.sh` now write `.harness-meta.json` in every generated
  project, capturing the answers given at generation time so `upgrade` can
  re-render templated files (e.g. Java's `{{BASE_PACKAGE}}`) later.
