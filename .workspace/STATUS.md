# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-29
**Active plan**: none — the last active plan
(`.workspace/plans/2026-07-28-project-excluded-paths.md`) is **Done**, all
of E0-E7 complete and committed.

## Current Goal

None active. The last unit of work (Harness **1.8.0** → **1.8.1**,
`.harnessignore` project-declared excluded paths plus the audit fixes) is
shipped. Waiting on the user for the next task.

## Progress

- **Harness 1.8.0 — released and committed (`8d9c004`).** New user-owned
  `.harnessignore` lets a project exclude vendored/reference directories
  from the arch tests and lint hooks without editing a framework-owned
  file, implemented across all five consumers (Python, TypeScript, Java
  arch tests + Python/TypeScript lint hooks). Full detail: `worklog.md`'s
  2026-07-29 row and `.workspace/plans/2026-07-28-project-excluded-paths.md`.
- **Harness 1.8.1 — post-implementation audit of 1.8.0, two fixes.**
  Audited the shipped files against the plan rather than re-reading it
  (same practice as the 1.4.0/1.5.0/1.7.0 audits). Found:
  1. **Real defect**: the Python lint hook matched `.harnessignore`
     patterns against the **absolute** path, not relative to the project
     root — so 1.8.0's "one match rule, five identical implementations"
     was actually four. Any project under a directory whose name matched a
     pattern had **every** file silently skipped (exit 0, no message).
     `Homographormer` escaped only by letter case (`Homographormer` dir vs
     `HomoGraphormer` pattern). Reproduced live, fixed (relativize via
     `pwd -W` on Git Bash, plain `pwd` elsewhere; case-insensitive prefix),
     re-verified on both sides of the boundary.
  2. **Doc drift**: `README.md`'s Framework tier table still said
     `lint-format-hook.sh` after 1.8.0 registered the TypeScript `.mjs`.
     `check-sync.mjs` guards the *guide* against the manifest, not README.
  **Open, deliberately not fixed**: Java's `ImportOption` passes an
  absolute compiled-class URI to `isIgnored` while the same file's other
  call site passes a relative source path — likely the same deviation,
  plus a source-directory pattern may never match a compiled-output path.
  Unverifiable here (no `mvn`/`javac`), and fixing an unrunnable file
  blind is exactly how defect 1 shipped. Recorded in the plan.
- **Verified working by live execution during the audit** (not inference):
  `.harnessignore` delivery on fresh `setup.sh` generation for TypeScript
  *and* Java; `{{BASE_PACKAGE}}` substitution (E5's `\r` fix); bootstrap on
  a real 1.7.0 → 1.8.0 upgrade from a disposable worktree; the newly
  registered `.mjs` getting a baseline in fresh projects and a one-time
  `.new` in existing ones; and a 1.8.0 → 1.8.1 Python upgrade delivering
  the hook fix cleanly with **no** `.new` — which is how `Homographormer`
  will receive it.
- **`Homographormer` migrated to 1.8.0 in its own repo** (separate nested
  git repo, not part of this commit): branch
  `chore/harness-upgrade-1.8.0`, commit `3b10776`. `upgrade.sh --verify`
  reports zero customized files — the plan's explicit success measure
  (E6) achieved. Merge-to-`main` there remains the project owner's call,
  unchanged from every prior upgrade.
- **This session's own workspace-doc audit** (2026-07-29, before the
  commit above): found and fixed two staleness defects in `.workspace/`
  itself —
  1. `STATUS.md` (this file) had gone stale after the 1.8.0 plan finished:
     it still read "In Progress, implementation not started" a full day
     after the plan file itself and `worklog.md` both recorded it Done.
     Root cause was the same one flagged on 2026-07-26 (a plan's `Status`
     line — and by extension `STATUS.md` — gets written before the
     commit exists and nothing revisits it after): this session ended
     without running `/done`, so the close-out step never happened.
  2. `.workspace/plans/README.md` (root copy) had fallen behind the
     `harness-core/` copy's own template — missing the `Owner` field,
     the `Parallelization` section, the tier-language rewrite of the
     opening framework-owned-path paragraph, and the worklog
     author-column note. Fixed by copying `harness-core`'s version in;
     `diff` between the two is now empty.
  3. `worklog.md` had no row for 2026-07-27 even though
     `FRAMEWORK-CHANGELOG.md` (1.6.1 entry) and this file both referenced
     that date's work — the exact same append-only-history gap already
     caught and fixed once, on 2026-07-26. Added the missing row,
     reconstructed from `FRAMEWORK-CHANGELOG.md`'s 1.6.1 + tooling
     entries and commit `8f7f4aa`.
  All three fixes are folded into commit `8d9c004` alongside the 1.8.0
  release itself, plus `pnpm validate` (check-sync, typecheck, lint, 19
  tests) passing both before staging and again via the pre-commit hook.
- Everything from 2026-07-13 through 2026-07-28 (harness 1.0.0 through
  1.7.0, the team-roles feature, file-ownership rules, multiple
  `Homographormer`/`agentic-eacc-mcp-server` upgrades) is **Done** — see
  `worklog.md`.

## Next Steps

No committed next task. Candidates surfaced but not started, in rough
priority order:

1. **`Homographormer` is one patch behind**: it sits at 1.8.0 and carries
   the buggy lint hook. It is *not* currently mis-skipping anything (its
   directory casing differs from its patterns), so this isn't urgent — but
   its next upgrade should be 1.8.1, which was verified to apply cleanly
   with no `.new`. Project owner's call, as with every prior upgrade there.
2. **Needs a Java toolchain**: settle the Java `ImportOption` question
   recorded in the plan's Post-implementation audit — whether the absolute
   compiled-class URI makes source-directory patterns inert for the
   ArchUnit checks. Un-defer trigger: a working `mvn`/`javac`, or the first
   Java project that actually needs an exclusion.
3. **User's call, not urgent**: `C:\anyonecan_harness\anyonecan\Homographormer\`
   sits nested inside this repo's working tree (untracked here, own
   separate `.git`) rather than as a sibling directory. Filesystem
   organization only, not a git-history issue — same note carried since
   2026-07-28.
4. **User's call, needs a toolchain**: validate the Java language pack's
   `validate.sh` (`mvn verify`) end-to-end — still unconfirmed in this
   environment (no `mvn`/`javac`), a standing gap since 1.4.0. Shares a
   blocker with item 2.
5. **Still deferred, unchanged**: the `agentsSectionAliases` map for
   translated `AGENTS.md` headings (n=1; un-defer trigger is a second
   non-English project hitting the same false positive).
6. `Homographormer` now has four sequential unmerged upgrade branches
   (`chore/harness-upgrade-1.6.0` → `1.6.1` → `1.7.0` → `1.8.0`, each
   forked from the last). Project owner's call on whether/when to merge;
   worth knowing the chain exists before starting a future upgrade there.

## Blockers / Open Questions

- **None blocking.** Environment notes for future sessions on this box:
  - **This box's default codepage is Korean, not UTF-8.** Any **new**
    PowerShell code that reads a UTF-8 file via `Get-Content` must pass
    `-Encoding UTF8` explicitly or non-ASCII bytes silently corrupt —
    confirmed the hard way during 1.7.0.
    `[System.IO.File]::ReadAllText(path, [System.Text.Encoding]::UTF8)` is
    unaffected. Fixed everywhere it applied as of 1.7.0; re-check when
    adding a new `Get-Content` call.
  - **Python**: `python3` on PATH is a real 3.13.0 install but has none of
    mypy/ruff/pytest/torch/numpy; only miniconda's `python` does. For any
    project without its own `.venv`, use a temporary `python3` shim on
    `PATH` pointing at miniconda's `python.exe`, scoped to the one command
    that needs it (works for `validate.sh` and for `.husky/pre-commit`).
    Separately, this box's `python3` appends a trailing `\r` to captured
    stdout even for `print()`-only output (Windows text-mode) — `setup.sh`
    was patched around this in 1.8.0; watch for the same footgun in any
    new bash script that captures `python3` output via command
    substitution.
  - `pnpm` missing from Bash-tool PATH by default — fix with
    `npm install -g pnpm@10 --prefix "$APPDATA/npm"` (not corepack; its
    pnpm@11 shim hits a Node 18.17 incompatibility).
  - `setup.ps1` can't be driven from the PowerShell tool (`-NonInteractive`
    blocks `Read-Host`). Pipe stdin through Bash instead:
    `printf 'name\ndesc\nauthor\npython\nenglish\n1\n<outdir>\n' | powershell.exe -NoProfile -File ./setup.ps1`.
    `setup.sh` works directly under Git Bash and additionally prompts
    `Proceed? (y/N)`. Project names must be lowercase.
  - No `mvn`/`javac` here, so Java verification stays structural
    (generation + review) rather than build-level — same constraint since
    1.4.0.
