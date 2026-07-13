# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-13
**Active plan**: `.workspace/plans/2026-07-13-harness-upgrade-p1-p5.md`

## Current Goal

Upgrade the framework across 5 priorities so every member — any AI tool, any
language — gets consistent, enforced quality. P1, P2, P3 are done and
committed. P4 and P5 remain — resume with P4 next session.

## Progress

- **P1 done** (commit f34eb77): AGENTS.md is the single rule source across
  every AI tool; CLAUDE.md/.cursorrules/.windsurfrules/harness.mdc reduced
  to pointers; `scripts/check-sync.mjs` guards against drift.
- **P2 done** (commit cf39a92): HARNESS-VERSION + harness-manifest.json +
  upgrade.ps1/upgrade.sh/upgrade.py let existing generated projects pull in
  framework updates. Verified end-to-end on Windows and Mac/Linux; 3 real
  bugs found and fixed during verification.
- **P3 done** (commit 834a40b): documented-only rules (`.only()` ban,
  ts-comment ban, print() ban, System.out.print ban) promoted to real
  linter/Checkstyle gates across all 3 languages; domain coverage (≥80%)
  enforced in CI for TS/Python (Java is project-wide, documented why); Java
  arch test brought up to the same 5-check parity as TypeScript's (Python
  was already there). Python changes verified live with real ruff/pytest in
  this session; TS/Java only checked for syntax/XML well-formedness — no
  pnpm/node_modules or Java/Maven were available to actually run them.
- Working tree is clean. No uncommitted changes.

## Next Steps

1. **P4 — Team Collaboration Layer**:
   - `harness-core/.github/PULL_REQUEST_TEMPLATE.md` (tests included? plan
     linked? ADR written? AGENTS.md updated?)
   - Move `docs/how-to/git-workflow.md` + `testing-guide.md` into
     `harness-core/docs/how-to/` (generalize TS-specific bits;
     `component-guide.md` stays root-only)
   - Multi-member `.workspace/` note (STATUS.md is per-branch by nature,
     worklog.md is append-only — on merge conflict keep both rows) in
     `.workspace/plans/README.md` + AGENTS.md's Work Journal section
   - Named CI steps (typecheck/lint/test as separate steps) for TS & Python
2. **P5 — Data-Driven Language Packs**: `pack.json` per language
   (display name, aliases, rules, banned items, install command);
   `setup.ps1`/`setup.sh` discover languages from `pack.json` instead of
   hardcoding; `docs/how-to/adding-a-language-pack.md`; update README's
   "Adding a New Language Pack" section
3. Recommend the user run `pnpm validate && pnpm test:coverage` and `mvn
   verify -P coverage` on a generated project once in an environment with
   those tools, to confirm the P3 TS/Java changes actually work (unverified
   in this session — see Progress above)

## Blockers / Open Questions

- pnpm is not on PATH in this shell — `pnpm validate` must be run by the
  user, or `bash scripts/validate.sh` after confirming pnpm is reachable.
- No Java/Maven in this environment — the Java arch-test additions and
  JaCoCo profile from P3 are unverified beyond XML well-formedness/manual
  review. Confirm with real Maven before relying on them in production.
- Local environment quirks (not framework bugs, just notes for future
  sessions in this same sandbox): Cygwin perl breaks on multiple `-e`
  flags (already worked around in setup.sh); PowerShell tool's
  `-NonInteractive` mode can't run `Read-Host`-based scripts, so
  interactive scripts need Bash-invoked `powershell.exe -File ...` with
  piped stdin instead.
