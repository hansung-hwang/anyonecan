# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-25
**Active plan**: `.workspace/plans/2026-07-25-upgrade-tooling-safety-and-dry-run.md`
— **start here.** Two more plans follow it in a fixed order (see below).

## Current Goal

Three linked plans are written, committed, and ready to execute. **Nothing has been implemented yet** — they are
design-only, 66 open checklist items across the three. Execute them **in this order**; each unblocks the next:

1. **`2026-07-25-upgrade-tooling-safety-and-dry-run.md`** ← next session starts here
   Add `upgrade --dry-run`, and stop upgrade from overwriting files a project authored itself.
   *Begin at Gate U0 (5 design decisions, all with recommendations already written).*
2. **`2026-07-25-file-ownership-rules.md`**
   Ship the rule telling a project which files it may edit. Its decision D5 (make `harness-manifest.json`
   framework-owned) is **only safe after plan 1's U2 fix lands** — hence the order.
3. **`2026-07-25-apply-harness-1.5.0-to-homographormer.md`**
   Upgrade the real sub-project. Plan 1 deletes this plan's riskiest step (Phase H2, a manual file rescue), so
   running it last is materially safer and cheaper.

Executing plan 3 alone, out of order, is still *safe* — its Phase H2 exists precisely to cover the gap — but costs
a manual rescue step the framework work makes unnecessary.

## Progress

- **Harness 1.4.0 and 1.5.0 — both Done, fully validated, and pushed.** `origin/main` = `28691c5`; working tree
  clean. 1.5.0 (team roles & project mode) shipped this session along with a post-close-out audit that found and
  fixed two more real gaps. Full records in `.workspace/plans/2026-07-22-*` and `2026-07-23-*`.
- **Homographormer analysis — done, evidence-based, nothing modified.** A faithful copy of the project was made in
  scratch at its exact git HEAD, the real `upgrade.py` was run against it, and the copy was deleted. The real
  project is **untouched** — verified still at `HARNESS-VERSION` 1.3.0 with a clean `git status`.
  - **Good news, verified**: upgrade touches **zero** source files (nothing under `src/`, `HomoGraphormer/`, or
    research dirs). The user's hard requirement — no impact on the sub-project's own code — holds structurally.
  - **The hazard**: its hand-written 22 KB Korean multi-agent guide (custom agent roles, Phase-0 wave
    assignments) would be silently overwritten. Two of its files also need `.new` merges
    (`scripts/lint-format-hook.sh` Windows path guard, `tests/arch/test_dependencies.py` exclusion) — both are
    real fixes that must survive.
  - **Root cause, and the project is blameless**: the shipped `AGENTS.md`/`CLAUDE.md` say nothing about file
    ownership, and the only machine-readable map (`harness-manifest.json`) is copied once at setup and never
    refreshed. Homographormer's copy showed `docs/how-to/multi-agent-collaboration.md` as an unclaimed path.
  - **Timing note**: that project has two In-Progress plans of its own (`repro-hab-baselines`,
    `final-benchmarking-v2`). Its research work is unaffected by the upgrade, but the two `.new` merges touch a
    per-edit hook and the arch test — so do the upgrade on a branch at a natural boundary, not mid-benchmark.
- `agentic-eacc-mcp-server` (external project) was upgraded 1.2.0 → 1.3.0 in an earlier session, on its still-unmerged
  `chore/harness-upgrade-1.2.0` branch (commit `e0d9c70`, on top of `d40aa6c`). Merging/pushing that branch is the
  user's call, not made in any session so far — unrelated to this repo's own work, carried forward as a reminder.

## Next Steps

1. **Start plan 1** (`upgrade-tooling-safety-and-dry-run`) at **Gate U0** — five decisions, each with a written
   recommendation, then Phase U1 (`--dry-run` first, because it makes U2 testable).
2. Then plan 2, then plan 3, per the order above.
3. **User's call, whenever**: merge/push `chore/harness-upgrade-1.2.0` in the `agentic-eacc-mcp-server` repo.
4. **User's call, whenever a toolchain/admin environment is available**: validate the Java language pack's
   `validate.sh` (`mvn verify`) — still the one thing about Java never confirmed end-to-end in this environment
   (`winget` blocks on an interactive Microsoft Store ToS prompt; no JDK/Maven present).

## Blockers / Open Questions

- **None blocking.** All three plans have their design written; plan 1's Gate U0 has open *decisions*, but each
  carries a recommendation, so a session can proceed without waiting on anything external.
- Environment limitation carried forward: no `mvn`/`javac` here, so any Java verification in these plans is
  structural (generation) rather than build-level — same constraint as 1.4.0/M4 and 1.5.0/T4.
- **Known false positive, don't re-investigate**: `/start`'s step 4.5 (`grep -l "Status.*In Progress"`) also
  matches `2026-07-14-harness-1.3.0-customization-safety.md` and `plans/README.md`. Both are **Done/template** —
  the grep hits *example* `- **Status**:` text inside their bodies, not their own status lines. Only the three
  2026-07-25 plans are genuinely In Progress.
