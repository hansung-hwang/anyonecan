# Harness Framework Upgrade — P1~P5

- **Date**: 2026-07-13
- **Status**: In Progress

## Goal

Strengthen the framework so that every team member — regardless of AI tool
(Claude Code / Cursor / Windsurf / Codex) or language (TS / Python / Java) —
produces consistent, enforced-quality results. Five priorities, ordered:

| # | Theme | Why it matters |
|---|-------|----------------|
| P1 | Single source of truth for rules | Rule drift across 5 config files structurally breaks the "same rules for every tool" promise |
| P2 | Harness versioning & upgrade path | Generated projects are copies; without upgrades, team-wide consistency decays over time |
| P3 | Promote doc-level rules to hard gates | Rules that only live in docs don't guarantee quality |
| P4 | Team collaboration layer | Harness is currently optimized for 1 person × AI, not a team |
| P5 | Data-driven language packs | Adding a new language currently requires edits in 4+ hardcoded places |

## Approach

### P1 — Single Source of Truth (AGENTS.md as the only rule origin)

Current: identical rules duplicated in `CLAUDE.md`, `AGENTS.md`,
`.cursorrules`, `.windsurfrules`, `.cursor/rules/harness.mdc`; `/fix` only
mentions syncing two of them → drift is inevitable.

Design (applies to both `harness-core/` templates and this repo's root):

1. **AGENTS.md** keeps the full rules (Work Journal, Architecture, Coding
   Rules, Prohibited, Validation, Steering Loop, Workflow Prompts). It is
   the ONLY file where rules are edited.
2. **CLAUDE.md** shrinks to: header + `@AGENTS.md` import (Claude Code
   native import syntax) + Claude-only extras (slash commands note, hooks
   note, session-start note).
3. **.cursorrules / .windsurfrules / .cursor/rules/harness.mdc** shrink to
   thin pointers: "All rules live in AGENTS.md — read it." (Modern Cursor/
   Windsurf read AGENTS.md natively; pointers remain for old versions.)
   - `harness.mdc` keeps `alwaysApply: true` frontmatter so Cursor still
     force-loads the pointer.
4. **setup scripts**: `{{LANGUAGE_RULES}}` / `{{BANNED_ITEMS}}` substitution
   then only needs to target AGENTS.md (keep the loop but the other files no
   longer contain those placeholders).
5. **Commands** (`fix.md`, `done.md`): change "sync CLAUDE.md + AGENTS.md"
   → "edit AGENTS.md (single source)".
6. **Framework repo self-drift**: add `scripts/check-sync.mjs` comparing
   root `.claude/commands/*` vs `harness-core/.claude/commands/*` (files
   intended to be identical) and fail `pnpm validate` on drift. Root
   start/commit differ slightly today (pnpm vs validate.sh) — decide per
   file: identical-list vs root-specific list documented in the script.

### P2 — Harness Versioning & Upgrade Path

1. **`harness-core/HARNESS-VERSION`**: single line semver (start `1.0.0`).
   Copied into generated projects; setup prints it.
2. **Manifest** `harness-core/harness-manifest.json`: lists
   *framework-owned* paths (safe to overwrite on upgrade):
   `.claude/commands/*.md`, `.claude/settings.json`, `scripts/validate.sh`,
   arch test files, `.husky/pre-commit`, `.github/workflows/ci.yml`,
   `.editorconfig`, `docs/adr/001-*`, `.workspace/plans/README.md`.
   User-owned (never touched): `AGENTS.md`, `CLAUDE.md`, `README.md`,
   `HARNESS-CHANGELOG.md`, `.workspace/STATUS.md`, `.workspace/worklog.md`,
   plan files, all src/tests beyond arch tests.
3. **`upgrade.ps1` / `upgrade.sh`** in framework repo root: run from a
   generated project (`-FrameworkDir <path-to-anyonecan>` or auto via env),
   compares HARNESS-VERSION, overwrites manifest paths from harness-core +
   language pack, re-applies placeholder substitution to the new files (name,
   language rules), shows changed-file list, leaves changes uncommitted for
   review. Never touches user-owned files.
4. **Version bump discipline**: note in root AGENTS.md — any harness-core /
   language-pack change requires a HARNESS-VERSION bump + HARNESS-CHANGELOG
   entry (framework repo's own changelog).

### P3 — Hard Gates (parity matrix + enforcement)

1. **Pre-scan → linter rules** (removes manual grep from `/commit` Step 1):
   - TS: eslint `no-console: error`, `no-restricted-syntax` for
     `.only(` (`CallExpression[callee.property.name='only']`)
   - Python: ruff `T20` (print), plus `flake8-ban`-style check unneeded —
     pytest `.only` equivalent is `@pytest.mark.only` (not standard; skip)
   - Java: Checkstyle `Regexp` module for `System.out.print`
   - `/commit` pre-scan step then shrinks to "validate.sh covers this".
2. **Coverage gate — domain ≥ 80%** enforced, not documented:
   - TS: vitest.config `coverage.thresholds` scoped to `src/domain/**`,
     add `test:coverage` to validate.sh? No — keep validate fast; enforce in
     CI: add coverage step to each language ci.yml.
   - Python: `pytest --cov=src/domain --cov-fail-under=80` in CI.
   - Java: JaCoCo plugin rule (`BUNDLE`/package `*.domain*` LINE ≥ 0.80)
     bound to `verify` — runs in CI via `mvn verify`.
3. **Arch-test parity matrix** — all 3 languages enforce the same 5 checks:
   | Check | TS | Python | Java |
   |---|---|---|---|
   | Layer dependency direction | ✅ | ✅ | ✅ (ArchUnit) |
   | Domain purity (no external libs) | ✅ | ✅ | verify/add |
   | No same-layer circular refs | ✅ | add | add (ArchUnit slices) |
   | File naming convention | ✅ | add (snake_case) | add (PascalCase via Checkstyle OuterTypeFilename — may already hold) |
   | Domain file ⇒ test file exists | ✅ | add | add |
   Audit Python/Java tests first; implement missing checks.
4. **Java lint-format hook**: no good CLI formatter guaranteed — add
   PostToolUse hook only if cheap (e.g. `mvn spotless:apply` too slow →
   document why Java has no PostToolUse hook instead; Stop hook suffices).

### P4 — Team Collaboration Layer

1. `harness-core/.github/PULL_REQUEST_TEMPLATE.md`: checklist — tests
   included, validate.sh passes, plan doc linked (if non-trivial), ADR
   written (if architecture decision), AGENTS.md updated (if rule changed).
2. Move `docs/how-to/git-workflow.md`, `testing-guide.md` into
   `harness-core/docs/how-to/` (generalize TS-specific bits;
   `component-guide.md` stays root-only if TS-specific).
3. `.workspace` multi-member note (in `.workspace/plans/README.md` +
   AGENTS.md Work Journal section): STATUS.md is per-branch by nature;
   worklog.md is append-only — on merge conflict keep both rows.
4. CI: split validate into visible steps where cheap (typecheck / lint /
   test as separate named steps for TS & Python) so PR failures are
   self-explanatory.

### P5 — Data-Driven Language Packs

1. `language-packs/<lang>/pack.json`:
   ```json
   {
     "language": "typescript",
     "display": "TypeScript",
     "aliases": ["1", "ts", "typescript"],
     "rules": ["- No `any` → ...", "..."],
     "banned": "`any` · `@ts-ignore` · ...",
     "install": { "tool": "pnpm", "check": "pnpm", "run": "pnpm install" }
   }
   ```
2. `setup.ps1` / `setup.sh`: discover packs by globbing
   `language-packs/*/pack.json`; build the language menu, rules, banned
   items, and install step from pack.json. Java-specific extras
   (BASE_PACKAGE prompt, package dir generation) keyed off a
   `"postGenerate": "java-packages"` field or `language == "java"` special
   case (acceptable).
3. `docs/how-to/adding-a-language-pack.md` (framework repo): the language
   pack contract — required files (pack.json, scripts/validate.sh,
   .claude/settings.json hooks, .github/workflows/ci.yml, arch tests
   implementing the 5-check parity matrix).
4. Update README "Adding a New Language Pack" section to match.

## Checklist

### P1 — Single source of truth
- [x] harness-core: rewrite CLAUDE.md as thin file with `@AGENTS.md` import
- [x] harness-core: shrink .cursorrules / .windsurfrules / harness.mdc to pointers
- [x] harness-core: consolidate full rules into AGENTS.md
- [x] setup.ps1 + setup.sh: limit LANGUAGE_RULES/BANNED_ITEMS substitution to AGENTS.md
- [x] commands fix.md + done.md (both copies): rule edits target AGENTS.md only
- [x] Root repo: apply same thin-CLAUDE.md structure
- [x] scripts/check-sync.mjs + wire into pnpm validate (also wired as `pnpm check-sync`)
- [x] Verify: generate a test project, confirm rules render once, tools read them
  (generated via setup.ps1 — CLAUDE.md thin + `@AGENTS.md`, all 5 pointer/rule
  files substituted cleanly, no leftover `{{...}}`, all 9 commands present
  including plan.md/done.md)
- [x] Bonus fix found during verification: `setup.sh` step-4 perl
  substitution used multiple `-e` flags, which this machine's Cygwin perl
  5.42.2 fails to concatenate into one program (repros independent of
  `{{...}}` content — likely a broken/nonstandard build, but cheap and
  strictly safer to avoid). Rewrote as a single multi-statement `-e` block.
  Re-verified `setup.sh` end-to-end — output matches `setup.ps1`.

### P2 — Versioning & upgrade
- [x] harness-core/HARNESS-VERSION (1.0.0) + copy verified in setup output
  (setup.ps1/setup.sh now print "Harness version: 1.0.0" in the summary)
- [x] harness-manifest.json (framework-owned path list) — revised mid-verification:
  `.claude/settings.json`, `.github/workflows/ci.yml`, `.husky/pre-commit` moved
  OUT of frameworkOwned into each language's `languageSpecific` list (every
  language pack overlays these with its own hook wiring; treating them as
  language-agnostic silently downgraded a TS project's PostToolUse hook — see Notes)
- [x] upgrade.ps1 (Windows)
- [x] upgrade.sh + upgrade.py (Mac/Linux — upgrade.py holds the manifest-driven
  logic, matching how setup.sh already delegates to a python3 heredoc)
- [x] Version-bump rule documented in root AGENTS.md ("Framework Versioning"
  section) + README ("Framework Versioning & Upgrades" section) + new
  `FRAMEWORK-CHANGELOG.md` at repo root (not copied into generated projects,
  distinct from the per-project HARNESS-CHANGELOG.md)
- [x] Verify: generate project with old file, run upgrade, confirm manifest files
  updated & user files untouched — done via both setup.ps1+upgrade.ps1 and
  setup.sh+upgrade.sh+upgrade.py. Found and fixed 3 real bugs during
  verification (see Notes): (1) docs/adr/001's {{DATE}} placeholder was
  reintroduced unsubstituted by upgrade -- added to needsSubstitution using
  the project's original createdDate; (2) settings.json/ci.yml/husky
  language-pack overlays were being silently downgraded to the generic
  harness-core fallback -- moved to languageSpecific; (3) CRLF-vs-LF checkout
  noise caused spurious "changed" reports -- normalized before comparing.
  Confirmed: custom AGENTS.md content survives, HARNESS-VERSION advances,
  `git diff` after upgrade shows only the deliberately-reverted files.

### P3 — Hard gates
- [x] TS: eslint no-console (already existed) + no-.only rule added (root +
  language pack). Bonus: found `@ts-ignore`/`@ts-nocheck`/`@ts-expect-error`
  were only soft-banned by eslint's recommended default (allows
  `@ts-expect-error` with a description) despite AGENTS.md's outright ban —
  added an explicit `@typescript-eslint/ban-ts-comment` override to close
  the gap.
- [x] Python: ruff T20 enabled in pyproject.toml — verified live with the
  real `ruff` CLI installed in this environment (flags `print()`, silent
  otherwise); also removed two long-dead `ANN101`/`ANN102` ignores
  (deprecated by ruff, were silently no-ops) found while editing.
- [x] Java: Checkstyle `RegexpSinglelineJava` for `System.out.print*`
- [x] commit.md (both copies): pre-scan step removed — Step 1 is now just
  Validate, since the linter now covers every item that was previously
  manually grepped
- [x] TS: vitest coverage `include` narrowed to `src/domain/**` (root +
  language pack) + CI coverage step (`pnpm test:coverage`) in both ci.yml files
- [x] Python: `--cov=src/domain --cov-fail-under=80` CI step — verified live
  with real pytest+pytest-cov (installed in this environment): confirmed it
  FAILS at 67% coverage and PASSES at 100%, and that files outside
  `src/domain` don't affect the gate
- [x] Java: JaCoCo `coverage` Maven profile added to pom.xml, wired into
  `mvn verify -P coverage` in CI. **Scope note**: project-wide (BUNDLE), not
  domain-scoped like TS/Python — JaCoCo's include/exclude patterns need
  slash-separated package globs, which would require a second
  `{{BASE_PACKAGE}}`-in-slash-form template placeholder; deferred rather
  than risk unverified templating (no Java/Maven available in this session
  to test). Documented in a pom.xml comment.
- [x] Audit Python arch tests vs 5-check matrix — **already complete**, no
  changes needed (layer deps, domain purity, no cycles, snake_case naming,
  domain→test existence all present)
- [x] Audit Java arch tests vs 5-check matrix — was missing 3 of 5; added
  `domainShouldNotDependOnExternalLibraries` (ArchUnit `onlyDependOnClassesThat`),
  `layersShouldBeFreeOfCycles` (ArchUnit `SlicesRuleDefinition`), and
  `domainClassesShouldHaveMatchingTests` (plain filesystem walk, mirroring
  the TS/Python style since ArchUnit operates on compiled classes, not
  source-file existence). File-naming (PascalCase) intentionally NOT
  duplicated in ArchUnit — already enforced by Checkstyle's `TypeName`
  module, noted in a class-level comment.
- [x] Java PostToolUse hook: decided to omit. No fast, dependency-free CLI
  Java formatter is bundled by default (Spotless/google-java-format would
  need adding a Maven plugin + likely network access on first run); the
  Stop hook (`mvn verify` via validate.sh... actually `bash scripts/validate.sh`)
  already gates formatting-adjacent issues via Checkstyle. Documented here
  rather than adding an untested hook.
- [x] Verify (partial — see Notes): Python fully verified live (real
  ruff + pytest + pytest-cov). TypeScript verified only at the config/syntax
  level (`node --check` on both eslint.config.js files, valid; no pnpm/
  node_modules in this session to actually run eslint/vitest). Java verified
  only at the file-well-formedness level (pom.xml and checkstyle.xml
  confirmed well-formed XML after fixing an XML-comment `--` violation I
  introduced in pom.xml; the new ArchUnit test methods and JaCoCo profile
  were NOT compiled or run — no Java/Maven in this environment). **Action
  item for the user**: run `mvn verify -P coverage` and `pnpm validate` /
  `pnpm test:coverage` once on a generated project in an environment with
  those tools, to confirm before relying on this in production.

### P4 — Team layer
- [ ] harness-core/.github/PULL_REQUEST_TEMPLATE.md
- [ ] Move/generalize git-workflow.md + testing-guide.md into harness-core/docs/how-to/
- [ ] Multi-member .workspace note (plans/README.md + AGENTS.md, both copies)
- [ ] CI: named typecheck/lint/test steps for TS & Python packs

### P5 — Data-driven packs
- [ ] pack.json for typescript / python / java
- [ ] setup.ps1: pack.json-driven language discovery & substitution
- [ ] setup.sh: same
- [ ] docs/how-to/adding-a-language-pack.md
- [ ] README language-pack section updated
- [ ] Verify: generate one project per language end-to-end

## Notes

- Execution order P1 → P2 → P3 → P4 → P5; P1 is a prerequisite for P2
  (single origin simplifies the upgrade manifest).
- P1 risk: older Cursor/Windsurf versions that don't read AGENTS.md rely on
  the pointer files — keep pointer content self-sufficient for the critical
  rules (one-line architecture + "read AGENTS.md").
- P2 upgrade script must re-run placeholder substitution ONLY on newly
  copied files, never on user-owned files.
- P3 Java formatter: decide during implementation (Spotless speed test);
  documenting the omission is an acceptable outcome.
- Each P-phase ends with a commit (user approves message) + worklog entry
  via /done when the session closes.
- **P2 lesson (apply to P3/P5 too when they touch manifest-like lists)**:
  "framework-owned = safe to overwrite from harness-core" is only true for
  files with ONE canonical version across all languages. Anything a
  language pack overlays (hooks, CI, husky) must live under
  `languageSpecific`, never `frameworkOwned` — otherwise upgrading a known
  project with an unknown/missing language silently downgrades it to the
  generic fallback instead of just skipping. Caught this empirically by
  actually generating a project and diffing, not by inspection — worth
  repeating that pattern (generate → mutate → upgrade → diff) for any future
  manifest change.
- Local environment note: this machine's perl (Cygwin/Git-for-Windows,
  5.42.2) breaks on multiple `-e` flags; PowerShell tool's `Read-Host` also
  fails under `-NonInteractive` so `setup.ps1`/interactive scripts must be
  driven via Bash-invoked `powershell.exe -File ...` with piped stdin, not
  via the PowerShell tool directly, when input needs to be supplied.
