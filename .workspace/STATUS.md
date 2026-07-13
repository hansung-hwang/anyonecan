# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-13
**Active plan**: `.workspace/plans/2026-07-13-harness-upgrade-p1-p5.md`

## Current Goal

Upgrade the framework across 5 priorities so every member — any AI tool, any
language — gets consistent, enforced quality. P1 (single-source rules) is
done; P2~P5 remain.

## Progress

- **P1 done**: `AGENTS.md` is now the single rule source in both
  `harness-core/` and root. `CLAUDE.md` shrank to a header + `@AGENTS.md`
  import + Claude-only extras. `.cursorrules`/`.windsurfrules`/
  `.cursor/rules/harness.mdc` shrank to thin pointers. `setup.ps1`/`setup.sh`
  now only substitute `{{LANGUAGE_RULES}}`/`{{BANNED_ITEMS}}` into
  `AGENTS.md`. `/fix` and `/done` (both copies) now say "edit AGENTS.md
  only". Added `scripts/check-sync.mjs` (command-file parity + stale
  dual-edit-instruction grep) wired into `pnpm validate` and `pnpm
  check-sync`. Verified end-to-end by generating a TypeScript project via
  `setup.ps1` — no leftover `{{...}}` placeholders anywhere, all 9 commands
  present.
- Nothing committed yet — all P1 changes + the earlier `.workspace`/`/plan`/
  `/done` work sit uncommitted in the working tree.
- Fixed a pre-existing `setup.sh` bug found during P1 verification: this
  machine's Cygwin/Git-for-Windows perl 5.42.2 fails to concatenate
  multiple `-e` flags into one program (repros with `perl -e 'print 1' -e
  'print 2'`, unrelated to `{{...}}` content). Rewrote the step-4
  placeholder substitution to a single multi-statement `-e '...'` block.
  Re-verified `setup.sh` end-to-end (TypeScript project) — no leftover
  `{{...}}`, matches `setup.ps1` output.

## Next Steps

1. User review of P1 diff, then commit (likely as one commit covering
   `.workspace`/`/plan`/`/done` + P1 rule-consolidation, or split — ask user)
2. Start P2: HARNESS-VERSION + harness-manifest.json + upgrade.ps1/upgrade.sh

## Blockers / Open Questions

- pnpm is not on PATH in this shell — `pnpm validate` must be run by the
  user, or `bash scripts/validate.sh` after confirming pnpm is reachable.
- Should the setup.sh multi-`-e` perl issue be investigated/fixed, or is it
  specific to this machine's Cygwin perl build? Ask user before touching it
  (out of scope for the P1~P5 plan).
