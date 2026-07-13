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
- [ ] harness-core/HARNESS-VERSION (1.0.0) + copy verified in setup output
- [ ] harness-manifest.json (framework-owned path list)
- [ ] upgrade.ps1 (Windows)
- [ ] upgrade.sh (Mac/Linux)
- [ ] Version-bump rule documented in root AGENTS.md + README
- [ ] Verify: generate project with old file, run upgrade, confirm manifest files updated & user files untouched

### P3 — Hard gates
- [ ] TS: eslint no-console + no-.only rules (root eslint.config.js + language pack)
- [ ] Python: ruff T20 enabled in pyproject.toml
- [ ] Java: Checkstyle Regexp for System.out.print
- [ ] commit.md (both copies): shrink pre-scan step, point to linter
- [ ] TS: vitest coverage thresholds for src/domain + CI coverage step
- [ ] Python: --cov-fail-under CI step
- [ ] Java: JaCoCo domain rule in pom.xml
- [ ] Audit Python arch tests vs 5-check matrix; add missing (cycles, naming, test-exists)
- [ ] Audit Java arch tests vs 5-check matrix; add missing
- [ ] Java PostToolUse hook: implement or document why omitted
- [ ] Verify: each language pack's validate.sh + CI passes on generated sample

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
