# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-26
**Active plan**: `.workspace/plans/2026-07-25-file-ownership-rules.md`
— **start here.** Plan 1 (upgrade tooling safety) is done. One more plan follows this one (see below).

## Current Goal

Three linked plans from 2026-07-25 are being executed in order; each unblocks the next:

1. **`2026-07-25-upgrade-tooling-safety-and-dry-run.md`** — ✅ **Done, 2026-07-26.** All six acceptance criteria
   met and verified with real disposable projects (not simulation). Not yet committed/pushed.
2. **`2026-07-25-file-ownership-rules.md`** ← **next session starts here.** Ships the rule telling a project
   which files it may edit. Its decision D5 (make `harness-manifest.json` framework-owned) is now safe to
   implement — plan 1's U2 fix has landed.
3. **`2026-07-25-apply-harness-1.5.0-to-homographormer.md`** — Upgrade the real sub-project. Its riskiest step
   (the old Phase H2 manual rescue) has already been deleted now that plan 1 is done — the guide is protected
   structurally, confirmed live against the real on-disk copy (see below). Only plan 2's Phase O5 (relocating the
   guide to a project-owned path) is still outstanding before this one should be run for real.

## Progress

- **Plan 1 (upgrade tooling safety + `--dry-run`) — Done, 2026-07-26, all phases U0-U5 verified.**
  - **U0** (design gate): all four decisions confirmed as recommended — no `HARNESS-VERSION` bump (changelog-only),
    the D1 two-case baseline split confirmed as written, `--dry-run`/`-DryRun` flag naming confirmed, exit code
    always 0.
  - **U1**: `--dry-run`/`-DryRun` shipped on all three entry points (`upgrade.py`, `upgrade.ps1`, `upgrade.sh`),
    sharing one code path via `write_text()`/`remove_if_exists()` helpers that no-op when dry-run is set.
  - **U2**: the real bug — a manifest path added *after* a project's last upgrade, where the project already has
    a file there, was being **silently overwritten** (this is exactly what would have happened to Homographormer's
    hand-written Korean multi-agent guide). Fixed: that case now gets `.new` treatment in a new "newly managed by
    the framework" bucket, reported distinctly from ordinary customizations. Genuine pre-1.3.0 projects (no
    `baselines` map at all) are unaffected — still take the old overwrite path with its warning.
  - **U3**: upgrade now reminds the user, when new `.claude/commands/*.md` files are added, that `AGENTS.md`'s
    Workflow Prompts table and `CLAUDE.md`'s command list need hand-registering.
  - **U4**: verified with real disposable `git worktree` checkouts (the 1.3.0 commit `af1698f` and the
    pre-versioning commit `f34eb77`, each running its own `setup.ps1` non-interactively via piped stdin through
    `powershell.exe` directly — the PowerShell *tool* itself runs `-NonInteractive` and blocks `Read-Host` even
    with piped stdin, so `setup.ps1` must be invoked from the Bash tool instead when non-interactive generation is
    needed). Reproduced the Homographormer hazard synthetically (byte-identical original confirmed after upgrade);
    regression-checked a genuine pre-versioning project and an ordinary customized file both still behave exactly
    as before; full-tree-hashed `--dry-run` to confirm zero bytes written; cross-checked all three entry points
    agree. **Then re-ran `--dry-run` against the real on-disk Homographormer copy** (see below) and confirmed the
    guide now reports as `.new`, not overwritten.
  - **U5**: `FRAMEWORK-CHANGELOG.md` gained a "Tooling" entry (no version bump, per U0); `README.md`'s upgrade
    section documents `--dry-run` as the recommended first step; the Homographormer upgrade plan had its old
    Phase H2 (manual rescue) deleted and every cross-reference updated to match.
  - Full record: `.workspace/plans/2026-07-25-upgrade-tooling-safety-and-dry-run.md`.
- **Open discrepancy found this session, not yet resolved**: a self-contained copy of the Homographormer project
  (own `.git`, own Korean commit history, `HARNESS-VERSION` 1.3.0, ~1028 files, last touched 2026-07-25 19:00) is
  sitting **untracked** at `C:\anyonecan_harness\anyonecan\Homographormer\` — inside this framework repo's own
  working tree. This contradicts the 2026-07-25 STATUS.md snapshot, which stated the scratch analysis copy "was
  deleted" and the real project was "untouched." Flagged to the user at this session's start; not investigated
  further or deleted. **Whether this is *the* real Homographormer project (e.g., intentionally relocated) or a
  leftover scratch copy is unknown** — resolve before treating it as authoritative for anything beyond what this
  session did (a provably-safe `--dry-run`, see U4 above).
- **Harness 1.4.0 and 1.5.0 — both Done, fully validated, and pushed.** `origin/main` = `28691c5` at last push;
  today's plan-1 work (above) is committed locally to neither `origin/main` nor pushed yet — see Next Steps.
- `agentic-eacc-mcp-server` (external project) was upgraded 1.2.0 → 1.3.0 in an earlier session, on its still-unmerged
  `chore/harness-upgrade-1.2.0` branch (commit `e0d9c70`, on top of `d40aa6c`). Merging/pushing that branch is the
  user's call, not made in any session so far — unrelated to this repo's own work, carried forward as a reminder.

## Next Steps

1. **Review and commit plan 1's changes** (`upgrade.py`, `upgrade.ps1`, `upgrade.sh`,
   `harness-core/harness-manifest.json`, `FRAMEWORK-CHANGELOG.md`, `README.md`, both affected plan files) — nothing
   from this session has been committed yet. User's call on commit message/scope.
2. **Resolve the `Homographormer/` directory discrepancy** (see above) before the next session does anything with
   it beyond read-only inspection.
3. **Start plan 2** (`file-ownership-rules`) once plan 1 is committed.
4. Then plan 3 (`apply-harness-1.5.0-to-homographormer`), after plan 2's Phase O5.
5. **User's call, whenever**: merge/push `chore/harness-upgrade-1.2.0` in the `agentic-eacc-mcp-server` repo.
6. **User's call, whenever a toolchain/admin environment is available**: validate the Java language pack's
   `validate.sh` (`mvn verify`) — still the one thing about Java never confirmed end-to-end in this environment
   (`winget` blocks on an interactive Microsoft Store ToS prompt; no JDK/Maven present).

## Blockers / Open Questions

- **None blocking plan 2's start.** Plan 1 is fully done; plan 2's own design gate (if any) hasn't been opened yet
  this session — read that plan file first next session.
- **The `Homographormer/` directory identity question** (see Progress above) is a real open question, not a
  blocker for framework work, but should be resolved before plan 3 is executed for real against it.
- Environment limitation carried forward: no `mvn`/`javac` here, so any Java verification in these plans is
  structural (generation) rather than build-level — same constraint as 1.4.0/M4 and 1.5.0/T4.
- **Known false positive, don't re-investigate**: `/start`'s step 4.5 (`grep -l "Status.*In Progress"`) also
  matches `2026-07-14-harness-1.3.0-customization-safety.md` and `plans/README.md`. Both are **Done/template** —
  the grep hits *example* `- **Status**:` text inside their bodies, not their own status lines.
