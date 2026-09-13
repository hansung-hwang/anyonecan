# STATUS

**Last updated**: 2026-09-13
**Active plan**: none — `.workspace/plans/2026-09-13-framework-upgrade.md` is Done.

## Current Goal

Framework 1.9.0 is implemented and validated in the working tree. Prior 1.8.2
skills/AGENTS instruction fixes are retained. Work journals are closed out.
Commit and push to origin/main are now user-authorized. Starting Base is
`7888b529d192cacc142052b724d47417a8ffa44f`; the delivery commit carries this snapshot.

## Progress

- F1/F4: baseline metadata validation, user-file protection, same-version repair
  and merge reconciliation are covered by Python/PowerShell fixtures.
- F2/F3: local shell-free formatting, nonempty/source target protection,
  noninteractive setup, and explicit installation/git skip flags are implemented.
- F5/F6: TS AST/module resolution; Python relative imports, nested test paths,
  and exclusions; Java URI/source mapping and nested test lookup are implemented.
- F7: the prior instruction-consistency fixes remain complete.
- F8: root/template thin skills, manifest delivery, baseline protection,
  ownership docs, and instruction/link checks are implemented.
- F9: Node validation, framework contracts, and Windows/Linux language smoke CI
  are wired. pnpm is pinned to the installed and tested 10.34.5.
- Full validation passed after final path/API review.
  Generated TypeScript/Python validation and Java matcher compilation pass.

## Next Steps

No active implementation task. Exact requirement-to-file/test mapping,
execution commands and the declared owned diff are in the completed plan.
Neither nested project has been inspected or upgraded. Java 21/Maven and
hosted CI verification remain environment-dependent follow-up checks.

## Limits / Handoff

- Local Java helper checks use installed JDK 20. Java 21/Maven full integration
  and hosted Windows/Linux CI have not been executed locally.
- Codex hook runtime compatibility remains outside this delivery; existing
  `.codex/` and `.claude/settings.local.json` are untouched.
- TypeScript validation is now Node-based; Bash is required only for generator
  fixtures. HARNESS_PYTHON / HARNESS_BASH / HARNESS_JAVAC select fixture toolchains.
- Authorized commit scope includes setup/upgrade, language packs, root/template
  skills and commands, AGENTS, manifest/ownership, validation/tests/CI, package
  metadata, version/changelogs/README, and audit/plan/journals. Include new files
  when committing, particularly .agents and the contract/validation scripts.
- Pre-existing nested projects and local tool settings remain untouched.
