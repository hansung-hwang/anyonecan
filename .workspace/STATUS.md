# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-28
**Active plan**: `.workspace/plans/2026-07-28-project-excluded-paths.md` — In Progress, **design ratified, implementation not started.**

## Current Goal

Implement **project-declared excluded paths** (`.harnessignore`) — target
**1.8.0**. The design is settled and user-ratified; **no implementation file
has been touched yet.**

**Start at E4, not E1** — the `.harnessignore` template plus its manifest
registration is the shared artifact E1-E3 all depend on. The plan file's
"Resume here" block at the top carries the facts already gathered (where the
template goes, the five consumers, the current `bootstrapIfMissing` contents)
so none of it needs re-deriving.

**What it fixes**: `Homographormer` carries two permanently-customized
framework files (`scripts/lint-format-hook.sh`,
`tests/arch/test_dependencies.py`) that regenerate a `.new` on *every*
upgrade forever — three occurrences so far, no end condition — because the
only way to say "skip my vendored research dirs" is to edit them. A
user-owned plain-text `.harnessignore` that the framework's own scripts read
makes those scripts generic again, ending the recurrence. **Success is
measured by E6**: Homographormer finishing with zero customized framework
files.

**Design decided by the Java pack**: `.harness-meta.json` was rejected —
Java's arch test has no JSON parser available (its pom carries only junit +
archunit, and the JDK ships none). Plain text is the only format readable
dependency-free from bash, Node, Python, and Java alike.

## Progress

- **Harness 1.7.0 — released and committed (`2c15277`).** `AGENTS.md`
  template section drift detection: `upgrade` now reports when a section the
  project *already has* had its template body change, not just when one is
  missing. Full record in
  `.workspace/plans/2026-07-28-agents-section-drift-detection.md`. Applied to
  `Homographormer` (`3783e12`). Pre-commit ran the full `pnpm validate`
  (check-sync, typecheck, lint, 19 tests) and passed.
- **Post-implementation audit of that plan — done, found one real defect.**
  S3 had been marked `[x]` having only run `setup.ps1`; `setup.sh` was
  inferred from code review despite that checklist item explicitly saying not
  to assume parity. Ran `setup.sh` for real — parity confirmed identical
  (same hashes, key set, and key order), and `upgrade.py --verify` against
  its output is clean. Plan corrected with an audit note. Everything else in
  that plan verified present in the real files.
- **Upgrade-procedure question answered** (user asked whether an agent must
  inspect files one by one every time): **no.** `upgrade.ps1`/`upgrade.sh` is
  a designed single entry point that reads the manifest and classifies every
  managed file itself; the only step needing judgment is resolving a `.new`.
  The same project's three upgrades got monotonically cheaper
  (1.3.0→1.6.0 heavy → 1.6.0→1.6.1 light → 1.6.1→1.7.0 trivial). Sessions
  feel heavy when they *develop* the framework, which is separate work from
  applying it.
- **Two pre-existing bugs found while researching the next plan** — both
  already folded into its scope, neither fixed yet:
  1. The template's Python lint hook lacks the Windows backslash
     normalization `Homographormer` had to add to its own copy — every
     Windows Python project would hit the same bug on adding an exclusion.
  2. `language-packs/typescript/scripts/lint-format-hook.mjs` is wired by
     that pack's `.claude/settings.json` but is **missing from
     `harness-manifest.json`**, so `upgrade` has never managed it and every
     TypeScript project's copy is frozen at its generation date.
- Everything from 2026-07-25 through 2026-07-27 (harness 1.6.0, the
  Homographormer 1.6.0/1.6.1 upgrades, the plan-status audit,
  `agentic-eacc-mcp-server`'s upgrades) is **Done** — see `worklog.md`.

## Next Steps

1. **Resume the active plan at E4** (see Current Goal above and the plan's
   own "Resume here" block).
2. Small, out-of-scope follow-up from the file-ownership-rules plan: fix
   `.workspace/plans/README.md`'s root/harness-core drift (root is missing
   1.4.0's Owner field + Parallelization block).
3. `worklog.md` still has no 2026-07-27 row even though
   `FRAMEWORK-CHANGELOG.md` references that date's 1.6.1 release work —
   cosmetic, but the same append-only-history gap fixed twice before.
4. **Possible cleanup, user's call, not urgent**:
   `C:\anyonecan_harness\anyonecan\Homographormer\` sits nested inside this
   repo's working tree (untracked, own separate `.git`) rather than as a
   sibling directory. Filesystem organization only, not a git-history issue.
5. **User's call, needs a toolchain**: validate the Java language pack's
   `validate.sh` (`mvn verify`) — still unconfirmed end-to-end here.
6. **Still deferred, unchanged**: the `agentsSectionAliases` map for
   translated `AGENTS.md` headings (n=1; un-defer trigger is a second
   non-English project hitting the same false positive).
7. `Homographormer` now has three sequential unmerged upgrade branches
   (`chore/harness-upgrade-1.6.0` → `1.6.1` → `1.7.0`, each forked from the
   last). That project owner's call on whether to merge; worth knowing the
   chain exists before starting a 1.8.0 upgrade there later.

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
  - `pnpm` missing from Bash-tool PATH by default — fix with
    `npm install -g pnpm@10 --prefix "$APPDATA/npm"` (not corepack; its
    pnpm@11 shim hits a Node 18.17 incompatibility).
  - `setup.ps1` can't be driven from the PowerShell tool (`-NonInteractive`
    blocks `Read-Host`). Pipe stdin through Bash instead:
    `printf 'name\ndesc\nauthor\npython\nenglish\n1\n<outdir>\n' | powershell.exe -NoProfile -File ./setup.ps1`.
    `setup.sh` works directly under Git Bash and additionally prompts
    `Proceed? (y/N)`. Project names must be lowercase.
  - No `mvn`/`javac` here, so Java verification stays structural
    (generation + review) rather than build-level — same constraint as
    1.4.0 through 1.7.0, and it applies to this plan's **E3**.
