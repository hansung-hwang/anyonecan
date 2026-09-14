# Framework 1.9.0 upgrade

- **Date**: 2026-09-13
- **Status**: Done

## Goal

Implement remaining framework audit improvements F1-F6, F8-F9 while retaining
the completed 1.8.2 instruction fixes. Exclude both nested generated projects.

## Approach

Fix baseline safety and same-version reconciliation, protect setup targets,
use shell-free formatting, resolve language imports accurately, deliver thin
skills through the manifest, and add disposable framework contract tests plus
Windows/Linux language smoke CI. Add noninteractive setup for these checks.
Framework-owned edits and new delivered files require minor version 1.9.0 and
manifest/ownership/changelog updates. Validate Java locally if tooling can be
located; otherwise record that limit and provide runnable CI coverage.

## Checklist

- [x] F1/F4: upgrade baseline validation and reconciliation fixtures.
- [x] F2/F3: shell-free hooks and safe noninteractive setup fixtures.
- [x] F5/F6: TypeScript/Python architecture correctness and Java path checks.
- [x] F8: skill delivery and manifest/ownership synchronization.
- [x] F9: framework contracts, portable validation, and language smoke CI.
- [x] Run validation, review owned diff, and close out docs.

## Notes

Starting Base/Head `7888b529d192cacc142052b724d47417a8ffa44f`. Prior audit and
1.8.2 changes are owned uncommitted work. No commit/push or nested-project
upgrade is part of this task. `.codex/` and local Claude settings are untouched.

## Requirement -> implementation -> validation

| Requirement | Implementation | Verification |
|---|---|---|
| F1/F4: preserve user files and reconcile reruns | `upgrade.py:main`, `upgrade.ps1` metadata preflight and per-file loop | `scripts/framework-contracts.py:UpgradeContracts` tests absent/empty/partial/malformed baselines, no-write failures, verify/dry-run snapshots, repair, CRLF merge, roster preservation, and customized skills |
| F2: literal file arguments | Root/TypeScript `scripts/lint-format-hook.mjs:runLocal` | `scripts/framework.test.mjs` runs actual hook processes with local fake CLIs, checking spaces, Unicode, quotes, dollar syntax, and ignores |
| F3: safe generation | `setup.ps1:Read-SetupValue` and output preflight; `setup.sh:ask` and canonical-path preflight | `SetupContracts` generates all languages with Bash and PowerShell then verifies repeated setup fails without changing existing files |
| F5: accurate TS dependencies | Root/TypeScript `dependencies.test.ts:extractImports`, `resolveLocalImport` | Node fixtures execute the shipped test module with the TS ES2022 target; allowed aliases/builtins pass and side-effect/dynamic/export/require/TSX/.js cycle violations fail |
| F6: relative imports, nested tests, ignores | Python `extract_imports`, `test_domain_modules_have_tests`; Java `isIgnoredClassLocation`, recursive test correspondence | `PythonArchitectureContracts`, generated Python validation; `JavaPathContracts` compiles the actual matcher and verifies source mapping, inner classes, and ancestor isolation |
| F8: deliver thin skills | `harness-core/.agents/skills`, manifest and ownership guides | Setup and upgrade fixtures verify delivery/baselines/customizations; check-sync verifies links and registration; quick_validate checks all template skill frontmatter |
| F9: executable framework checks | `scripts/validate.mjs`, `scripts/framework.test.mjs`, `scripts/framework-contracts.py`, `scripts/smoke-project.py`, CI matrix | Root validation and generated TypeScript/Python checks pass locally; hosted matrix execution is pending |

## Exact validation record

Working directory for repository commands: `C:\anyonecan_harness\anyonecan`.
Environment: Windows PowerShell, Node 18.17.0, pnpm 10.34.5, Miniconda Python
3.13.5, Git Bash, and JDK 20. Final full command (exit 0):

```powershell
$env:HARNESS_PYTHON = 'C:\Users\rty10\miniconda3\python.exe'; $env:HARNESS_JAVAC = 'C:\Program Files\Java\jdk-20\bin\javac.exe'; pnpm validate
```

This passes check-sync, instruction/import/hook Node fixtures, Python contracts
(including both setup/upgrader implementations and Java helper execution),
TypeScript typecheck/lint, and root architecture/domain tests. Sandbox access
to user runtime/temp paths required running this command outside the sandbox.

Template skills (all valid), same repository working directory:

```powershell
Get-ChildItem harness-core/.agents/skills -Directory | ForEach-Object { & 'C:\Users\rty10\miniconda3\python.exe' 'C:\Users\rty10\.codex\skills\.system\skill-creator\scripts\quick_validate.py' $_.FullName; if ($LASTEXITCODE -ne 0) { throw "Skill validation failed: $($_.Name)" } }
```

Local smoke projects were generated with `scripts/smoke-project.py` using the
same Python interpreter, skip-install and skip-git, then removed as disposable
fixtures. The final successful validation commands/cwds were:

- TypeScript: `node scripts/validate.mjs`, cwd
  `C:\Users\rty10\AppData\Local\Temp\harness-typescript-smoke-t5zjxk89\typescript`.
  Existing root node_modules were reused through a temporary junction, removed
  before fixture cleanup. Typecheck, lint and generated tests passed.
- Python: `C:\Users\rty10\miniconda3\python.exe -m mypy src/`,
  `C:\Users\rty10\miniconda3\python.exe -m ruff check src/ tests/`, and
  `C:\Users\rty10\miniconda3\python.exe -m pytest`, cwd
  `C:\Users\rty10\AppData\Local\Temp\harness-python-smoke-ii6aay9r\python`.
  All passed. An earlier ad-hoc TS output printer failed on cp949 after the
  underlying check succeeded; the successful UTF-8 rerun above replaces it.
- `git diff --check` passed; `git rev-parse HEAD` stayed at the starting SHA.

During final review, ArchUnit's actual API was checked against its
[1.3.0 source](https://raw.githubusercontent.com/TNG/ArchUnit/v1.3.0/archunit/src/main/java/com/tngtech/archunit/core/importer/Location.java):
`toString()` is a diagnostic wrapper, so the matcher now accepts `URI` and the
import option passes `asURI()` directly. Helper fixtures were rerun afterward.

## Limits and handoff

- Java 21/Maven full builds and hosted Windows/Linux matrix jobs were not run
  locally. The CI Java smoke seeds real layer classes, nested domain tests,
  and a deliberately invalid vendor class excluded by a source-path pattern.
- Static import checks cover literal module names. Computed runtime imports
  and nonstandard Java compiled-output directories are documented limits.
- Codex-specific hook execution is not newly claimed or distributed.
- Base/Head remains `7888b529d192cacc142052b724d47417a8ffa44f`. Owned uncommitted
  scope includes prior 1.8.2 commands/skills/AGENTS changes; setup/upgrade scripts;
  root and language-pack architecture/format/validation files; template skills,
  manifest/ownership docs; root tests, smoke generator, CI and package metadata;
  version/changelogs/README; and audit/plan/journal artifacts. New untracked files
  are required parts of this change and must be included when committing.
- Neither nested project nor pre-existing local Claude/Codex settings changed.

## Authorized Git delivery follow-up

On 2026-09-13 the user explicitly requested commit and push. This supersedes
the implementation-session no-commit scope and uncommitted handoff above.
Re-run pnpm validate with the same cwd/environment recorded above, stage only
the declared framework diff, commit, then push main to origin without force.
Commit `466ecfd1c7bfbcbb25b0050b0fce0ec94a22dd66` was pushed non-force to
`origin/main`; local and remote HEAD were confirmed equal afterward.
