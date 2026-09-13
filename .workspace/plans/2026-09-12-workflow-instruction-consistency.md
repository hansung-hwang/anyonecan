# Workflow instruction consistency

- **Date**: 2026-09-12
- **Status**: Done

## Goal

Resolve conflicts between repository skills, shared workflow commands, and
AGENTS.md without inspecting or upgrading either nested generated project.

## Approach

Keep AGENTS.md as the repository rule source. Replace the existing local
skill body copies with relative links to the matching shared command and
AGENTS.md. Correct conflicting source/template instructions, extend the
existing check-sync guard, and regression-test actual failing fixtures.
Framework-owned command edits require a patch release (1.8.2); the guard
extension repairs existing drift checks rather than adding a new command.
Full skill delivery to generated projects remains a separate audit item.

## Checklist

- [x] Reconcile instruction precedence and workflow source/template conflicts.
- [x] Convert local skills to thin references and validate their links/frontmatter.
- [x] Add regression fixtures to check-sync and run full validation.
- [x] Update version, changelogs, audit disposition, and work journals.

## Notes

Starting HEAD: `7888b529d192cacc142052b724d47417a8ffa44f`. Prior audit and
journal changes remain uncommitted. Existing `.agents/` files are in scope
for this request; `.codex/`, local Claude settings, and nested projects are
untouched. No commit or deployment requested.

## Results and validation

- Rule precedence -> root/template `AGENTS.md`, Workflow Prompts.
- Single rule-edit target -> root/template `.claude/commands/adr.md`.
- Complete validation -> root `.claude/commands/commit.md` and `test.md`.
- Task scope, evidence, and metadata protection -> root/template
  `start.md`, `plan.md`, `review.md`, `done.md`, `commit.md`, `team.md`, `test.md`;
  generated `fix.md` follows Key Invariants and File Ownership.
- No duplicate skill procedures -> `.agents/skills/source-command-*/SKILL.md`
  links to root AGENTS.md and the matching command using relative paths.
- Regression enforcement -> `scripts/check-sync.mjs`,
  `scripts/check-sync.test.mjs`; `pnpm check-sync` runs both and is called by
  root validation and existing CI. Fixtures reject the original ADR wording,
  self-import, duplicate AGENTS references, invented config path, copied command,
  wrong workflow links, and broken links; valid CLAUDE pointer prose passes.
- Version/documentation -> `harness-core/HARNESS-VERSION` is 1.8.2,
  `FRAMEWORK-CHANGELOG.md`, `HARNESS-CHANGELOG.md`, README, and audit disposition.

All commands ran from `C:\anyonecan_harness\anyonecan`, Windows PowerShell,
Node 18.17.0; skill validation used Miniconda Python 3.13.5.

1. `node scripts/check-sync.mjs` passed. Initial sandboxed
   `node --test scripts/check-sync.test.mjs` could not copy fixtures under the
   user temp directory (EPERM); this was an environment failure before assertions.
2. `$env:PATH = 'C:\Program Files\Git\bin;' + $env:PATH; pnpm validate`
   outside the sandbox passed check-sync, its nine fixture tests, TypeScript
   typecheck/lint, and the existing architecture/domain tests.
3. `Get-ChildItem .agents/skills -Directory | ForEach-Object { & 'C:\Users\rty10\miniconda3\python.exe' 'C:\Users\rty10\.codex\skills\.system\skill-creator\scripts\quick_validate.py' $_.FullName; if ($LASTEXITCODE -ne 0) { throw "Skill validation failed: $($_.Name)" } }`
   passed for every existing skill. Linked resources were also checked by check-sync.
4. `git diff --check` passed. No generated-project install/build, external
   publishing, or Codex hook execution was performed.

## Handoff

Base/Head remains `7888b529d192cacc142052b724d47417a8ffa44f`. Owned uncommitted
changes: the root/template command files listed above, both AGENTS files,
existing `.agents/skills` wrappers, check-sync script and new test file,
package.json, root validate.sh, version/changelog/README updates, and `.workspace`
audit/plan/journal artifacts. Prior audit artifacts remain in the same owned diff.
The `.agents/` directory and new test are still unstaged/untracked; include them
with these changes when committing, since check-sync now requires the wrappers.
Pre-existing `.codex/`, local Claude settings, and both nested projects are untouched.
F7 and the instruction-conflict portion of F8 are resolved; generated-project
skill delivery and all unrelated functional audit findings remain open.
