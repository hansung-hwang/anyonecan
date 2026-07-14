# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-14
**Active plan**: `.workspace/plans/2026-07-13-harness-upgrade-p1-p5.md` (Done — all 5 phases complete)

## Current Goal

The 5-phase harness-upgrade plan is complete (P1–P5). No active plan.
Working tree has uncommitted P4+P5 changes staged for a single commit (see
below) — this is the next immediate action, not a new task.

## Progress

- **P1–P3** done and committed in prior sessions (f34eb77, cf39a92, 834a40b).
- **P4 done** (team collaboration layer): PR template (harness-core +
  root), how-to docs (`git-workflow.md`, `testing-guide.md`) moved into
  `harness-core/docs/how-to/` and generalized for all languages (closes a
  real gap — these never reached generated projects before), multi-member
  `.workspace/` conflict guidance, named CI steps (Typecheck/Lint/Test) for
  TS and Python.
- **P5 done** (data-driven language packs): `pack.json` per language;
  `setup.ps1`/`setup.sh` rewritten to discover packs via glob instead of
  hardcoded switches; `docs/how-to/adding-a-language-pack.md` contract doc;
  README updated. Verified end-to-end on Windows via `setup.ps1` for all 3
  languages + alias matching + default fallback. `setup.sh` only
  syntax-checked (`bash -n`), not run end-to-end (no Mac/Linux in this
  session).
- HARNESS-VERSION bumped 1.0.0 → 1.2.0 (one release covering P4+P5, per
  user's request to hold the commit until both were done).

## Next Steps

1. **Commit P4+P5** (user approves the message) — this is the immediate
   next action, not deferred work.
2. Recommend the user run `setup.sh` for real on a Mac/Linux machine once,
   to confirm the P5 rewrite actually works end-to-end there (unverified
   in this session — see Blockers below).
3. No further phases planned. If new framework work comes up, start a new
   plan via `/plan`.

## Blockers / Open Questions

- This is a Windows-only sandbox: `setup.sh`/`upgrade.sh` changes can be
  syntax-checked but never actually executed end-to-end here. Every
  Mac/Linux-path change this framework has made (P2's upgrade.sh/upgrade.py,
  P5's setup.sh rewrite) carries this same unverified-in-practice caveat.
- pnpm is not on PATH in this shell — `pnpm validate` must be run by the
  user, or `bash scripts/validate.sh` after confirming pnpm is reachable.
- No Java/Maven in this environment — P3's Java arch-test additions and
  JaCoCo profile remain unverified beyond XML well-formedness/manual
  review from prior sessions.
