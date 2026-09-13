# Framework capabilities, skills, and agents audit

- **Date**: 2026-09-12
- **Status**: Done

## Goal

Audit the framework source, workflow skills, and agent instructions for actionable upgrades. Exclude `eacc-agentic-mcp-server/` and `Homographormer/` entirely.

## Approach

Review fixed committed Base/Head `7888b52` plus the explicitly identified pre-existing untracked `.agents/` and `.codex/` configuration. Inspect generation, upgrade, validation, language packs, and instruction consistency. Run available checks and focused disposable reproductions. This task changes only audit/journal documents; no framework-owned implementation changes or version bump.

## Checklist

- [x] Inspect capabilities and validation coverage.
- [x] Inspect skills, agent rules, and generation/upgrade delivery.
- [x] Reproduce or substantiate findings and prioritize upgrades.
- [x] Write audit report and close out journals.

## Notes

Initial working tree had untracked `.agents/`, `.codex/`, `.claude/settings.local.json`, and the two excluded nested projects. Preserve all of them. No commit or publishing requested.

Result: `2026-09-12-framework-audit-report.md` records F1-F9, priorities,
evidence levels, exact validation commands, and limitations. Companion
`2026-09-12-framework-audit-repro.py` / `.cjs` reproduce observed defects
using disposable fixtures and inert child-process stubs. Validation passes
with Git Bash placed first on PATH; default WSL bash fails before checks.
Head remained `7888b529d192cacc142052b724d47417a8ffa44f` throughout.
Only audit and journal files are owned changes; implementation fixes are
recommendations, not completed work.
