# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-26
**Active plan**: `.workspace/plans/2026-07-25-apply-harness-1.5.0-to-homographormer.md` (retargeted to 1.6.0)
— **start here.** Plans 1 and 2 are both done. This is the last of the three linked plans.

## Current Goal

Three linked plans from 2026-07-25 are being executed in order; each unblocked the next:

1. **`2026-07-25-upgrade-tooling-safety-and-dry-run.md`** — ✅ **Done, committed `a5b022f`.** `--dry-run` on all
   three entry points; the baseline-safety fix (a manifest path added after a project's last upgrade, where the
   project already wrote a file there, now gets `.new` instead of silent overwrite).
2. **`2026-07-25-file-ownership-rules.md`** — ✅ **Done 2026-07-26, all 6 acceptance criteria verified, not yet
   committed.** Ships `docs/how-to/file-ownership.md`, an `AGENTS.md` File Ownership section, makes
   `harness-manifest.json` itself framework-owned (D5), and a 4th `check-sync.mjs` guard keeping the doc and
   manifest from drifting apart. `HARNESS-VERSION` bumped to **1.6.0**.
3. **`2026-07-25-apply-harness-1.5.0-to-homographormer.md`** (retargeted to 1.6.0) ← **next session starts here.**
   Upgrade the real Homographormer sub-project. Its riskiest step (manual guide rescue) no longer exists — the
   guide is protected structurally. Plan updated to add a new step: relocate the merged guide to `docs/guides/`,
   which permanently closes the recurring-`.new` behavior a project-authored file at a framework path would
   otherwise keep producing forever.

## Progress

- **Plan 1 — committed as `a5b022f`.** `pnpm validate` passed pre-commit. Full record in that plan file.
- **Plan 2 (file ownership rules) — implementation done, verification done, commit pending this session's next
  step.**
  - **O0** (design gate): all decisions confirmed as recommended (`docs/guides/` location, check-sync guard over
    generation, proceed with D5 now, minor version bump to 1.6.0). **Found and fixed a real bug during the gate
    itself**: D1's illustrative tier table was already out of sync with the actual manifest (missing
    `HARNESS-VERSION`, and — notably — `scripts/lint-format-hook.sh`, the exact file Homographormer customized).
  - **O1**: new `harness-core/docs/how-to/file-ownership.md` (three tiers, the "don't create files in
    framework-owned directories → use `docs/guides/`" rule, `.new` mechanics) + root's maintainer-framed copy; new
    `## File Ownership` section in both `AGENTS.md` copies.
  - **O2**: `harness-manifest.json` added to its own `frameworkOwned` (D5). New `check-sync.mjs` guard #4: the
    guide's Framework-tier list (between `<!-- framework-tier:start/end -->` markers) must exactly match the
    manifest's `frameworkOwned` + all `languageSpecific` paths, both directions. **Verified by deliberately
    breaking it three ways** (one real omission — forgot to list `harness-manifest.json` itself in the guide after
    adding it to the manifest — plus two synthetic breaks); all three caught, all three fixed.
  - **O3**: Steering Loop (both `AGENTS.md` copies) and `.workspace/plans/README.md` (both copies) now point at
    the ownership rule.
  - **O4** (verification, real projects not simulation): fresh-generation matrix across TS/Python/Java (guide +
    `AGENTS.md` section present, byte-identical delivery, no `{{...}}` leftovers); a real upgrade matrix using a
    disposable pre-1.6.0 project (confirmed `AGENTS.md` untouched — the D3 asymmetry — and found a real,
    correctly-designed one-time behavior: `harness-manifest.json` itself lands as "newly managed" `.new` on the
    *first* post-1.6.0 upgrade since no baseline existed for it before D5, then self-heals from the second upgrade
    onward, verified end-to-end); **the real test** — two independent fresh, zero-context `general-purpose`
    subagents given an undirected guide-writing task, neither told about `docs/guides/` or this verification's
    purpose, **both independently chose `docs/guides/`**, citing `AGENTS.md`'s File Ownership section. Verified
    the files actually exist on disk, not just trusting the agents' self-report.
  - **O5**: `FRAMEWORK-CHANGELOG.md` `[1.6.0]` entry; `HARNESS-VERSION` → 1.6.0; `README.md` documents the
    ownership contract; the Homographormer plan retargeted 1.3.0→1.6.0 throughout and gained a `docs/guides/`
    relocation step.
  - **Found, out of scope, not fixed**: `.workspace/plans/README.md`'s root and `harness-core` copies have
    drifted independently of anything this plan touches — root is missing the entire "Owner" field and
    "Parallelization" block that 1.4.0 added to harness-core's copy. Worth its own small fix in a future session.
- **Homographormer directory identity — resolved this session.** `C:\anyonecan_harness\anyonecan\Homographormer\`
  (flagged as an open discrepancy at last session's close) is confirmed to be the **real, actively-developed
  project**, not a leftover scratch copy — its own Claude Code session history spans 9 days (2026-07-17 to
  2026-07-25) with megabytes of real transcripts; the alternate candidate location
  (`C:\Users\rty10\Desktop\HomoGraphormer`) doesn't exist on disk and has no real session history. Last session's
  STATUS.md claim that "the scratch copy was deleted" referred to a *different*, separate temporary copy from that
  session's own dry-run testing — not this directory. **Not moved or otherwise touched** (only read and a
  provably-safe `--dry-run` were run against it this session); nested-repo hygiene (a full git repo sitting inside
  this framework repo's own working tree, untracked) is a structural oddity worth fixing eventually, but is the
  user's call, not made unilaterally.
- **Harness 1.4.0 and 1.5.0 — both Done, fully validated, and pushed.** `origin/main` was at `28691c5` before this
  session; plan 1 is committed locally (`a5b022f`) but **not yet pushed**; plan 2's work is implemented but **not
  yet committed**.
- `agentic-eacc-mcp-server` (external project) was upgraded 1.2.0 → 1.3.0 in an earlier session, on its still-unmerged
  `chore/harness-upgrade-1.2.0` branch (commit `e0d9c70`, on top of `d40aa6c`). Merging/pushing that branch is the
  user's call, not made in any session so far — unrelated to this repo's own work, carried forward as a reminder.

## Next Steps

1. **Review and commit plan 2's changes** (`harness-core/docs/how-to/file-ownership.md`, `docs/how-to/file-ownership.md`,
   both `AGENTS.md` copies, `harness-core/harness-manifest.json`, `scripts/check-sync.mjs`, both `.workspace/plans/README.md`
   copies, `harness-core/HARNESS-VERSION`, `FRAMEWORK-CHANGELOG.md`, `README.md`, both Homographormer/file-ownership
   plan files) — nothing from plan 2 has been committed yet.
2. **Push both commits** (`a5b022f` and plan 2's, once committed) to `origin/main` — user's call, not done
   automatically.
3. **Start plan 3** (`apply-harness-1.5.0-to-homographormer.md`, retargeted to 1.6.0) — the real upgrade against
   the real Homographormer project. This is a change to a separate, real, actively-developed project's repo, not
   this framework's own — **requires explicit user confirmation before running for real** (not just `--dry-run`),
   per this session's own risk-matching practice (a `--dry-run` is safe to run freely; a real `upgrade` that writes
   files to another project's working tree is not).
4. Small, out-of-scope follow-up noted during plan 2: fix the `.workspace/plans/README.md` root/harness-core drift
   (root is missing 1.4.0's Owner field + Parallelization block).
5. **User's call, whenever**: merge/push `chore/harness-upgrade-1.2.0` in the `agentic-eacc-mcp-server` repo.
6. **User's call, whenever a toolchain/admin environment is available**: validate the Java language pack's
   `validate.sh` (`mvn verify`) — still unconfirmed end-to-end in this environment (`winget` blocks on an
   interactive Microsoft Store ToS prompt; no JDK/Maven present).

## Blockers / Open Questions

- **None blocking.** Plan 2 is fully done and verified; plan 3 just needs the commit/push above plus explicit
  go-ahead before touching the real Homographormer repo.
- **pnpm environment note**: this session found `pnpm` missing from this Windows box's Bash-tool PATH (a prior
  session's install didn't persist as a discoverable executable — only its cache/store dirs remained). Fixed by
  `npm install -g pnpm@10 --prefix "$APPDATA/npm"` (corepack's `pnpm@11.x` shim hits the same Node 18.17
  `ERR_VM_DYNAMIC_IMPORT_CALLBACK_MISSING` incompatibility noted in earlier sessions — use `npm install -g pnpm@10`
  directly, not corepack, on this box). `pnpm validate` now passes end-to-end again.
- Environment limitation carried forward: no `mvn`/`javac` here, so any Java verification in these plans is
  structural (generation) rather than build-level — same constraint as 1.4.0/M4, 1.5.0/T4, and now 1.6.0.
- **Known false positive, don't re-investigate**: `/start`'s step 4.5 (`grep -l "Status.*In Progress"`) also
  matches `2026-07-14-harness-1.3.0-customization-safety.md` and `plans/README.md`. Both are **Done/template** —
  the grep hits *example* `- **Status**:` text inside their bodies, not their own status lines.
