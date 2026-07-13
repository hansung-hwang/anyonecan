# Harness Engineering Framework

## Concept

**Harness engineering** means designing an environment in advance that makes it hard for AI agents to make mistakes.
It combines type systems, linter rules, architecture tests, and workflow prompts to constrain agent behavior,
and progressively hardens the harness through a **steering loop** (`/fix`) whenever a mistake occurs.

This framework generates a new harness-enabled project from any starting point with a single run of `setup.ps1` / `setup.sh`.

---

## Supported AI Tools

The same harness rules apply regardless of which AI coding tool you use.

| Tool | Config File |
|------|-------------|
| Claude Code | `CLAUDE.md` (imports `AGENTS.md`) + `.claude/commands/` (slash commands) |
| Cursor | `.cursor/rules/harness.mdc` or `.cursorrules` (pointer to `AGENTS.md`) |
| Windsurf | `.windsurfrules` (pointer to `AGENTS.md`) |
| Codex / Antigravity / others | `AGENTS.md` |

`AGENTS.md` is the **single source of truth** for all rules. The other
files never duplicate rule content — they either import it (`CLAUDE.md`) or
point to it (Cursor/Windsurf) — so every tool always sees the same rules.

> Workflow prompts in `.claude/commands/*.md` can also be used by non-Claude Code tools
> by copying the file contents and using them as prompts.

---

## Supported Languages

| Language | Validation Tools | Architecture Test |
|----------|-----------------|-------------------|
| TypeScript | tsc + ESLint + Vitest | `src/tests/arch/dependencies.test.ts` |
| Python | mypy + ruff + pytest | `tests/arch/test_dependencies.py` |
| Java | Maven + Checkstyle + JUnit5 | `src/test/java/arch/DependencyTest.java` (ArchUnit) |

---

## Structure

```
.
├── harness-core/              # Language-agnostic core (copied into every project)
│   ├── HARNESS-VERSION        # Semver, compared by upgrade.ps1/upgrade.sh
│   ├── harness-manifest.json  # Which files upgrade is allowed to overwrite
│   ├── AGENTS.md               # Single source of truth for all rules
│   ├── CLAUDE.md               # Thin: header + @AGENTS.md import + Claude extras
│   ├── .cursorrules            # Thin pointer to AGENTS.md (Cursor legacy)
│   ├── .cursor/rules/harness.mdc  # Thin pointer to AGENTS.md (Cursor MDC)
│   ├── .windsurfrules          # Thin pointer to AGENTS.md (Windsurf)
│   ├── .claude/
│   │   ├── settings.json      # Stop hook (auto-runs validate.sh)
│   │   └── commands/          # Workflow prompts (shared across all tools)
│   │       ├── start.md       # Session start (reads .workspace/STATUS.md)
│   │       ├── plan.md        # Create a design/progress doc
│   │       ├── done.md        # Session close-out (worklog + STATUS.md)
│   │       ├── fix.md         # Error fix loop
│   │       ├── commit.md      # Pre-commit checks
│   │       ├── review.md      # Code review
│   │       ├── test.md        # Test writing
│   │       ├── adr.md         # Architecture decision record
│   │       └── coverage.md    # Coverage check
│   ├── .workspace/            # Session-to-session work journal (survives session end)
│   │   ├── STATUS.md          # Current snapshot, overwritten each close-out
│   │   ├── worklog.md         # Append-only history of completed sessions
│   │   └── plans/             # Per-task design docs with progress checklists
│   ├── .husky/pre-commit      # Auto-runs validate.sh before commit
│   ├── .github/workflows/ci.yml
│   ├── .editorconfig
│   ├── HARNESS-CHANGELOG.md
│   └── docs/adr/001-clean-architecture-layers.md
│
├── language-packs/
│   ├── typescript/            # tsconfig · ESLint · Vitest · architecture tests
│   ├── python/                # pyproject.toml · ruff · mypy · pytest
│   └── java/                  # pom.xml · Checkstyle · ArchUnit
│
├── setup.ps1                  # Project generator (Windows)
├── setup.sh                   # Project generator (Mac / Linux)
├── upgrade.ps1                 # Pull framework updates into an existing project (Windows)
├── upgrade.sh / upgrade.py     # Same, for Mac / Linux
└── FRAMEWORK-CHANGELOG.md      # This repo's own changelog (not copied into projects)
```

---

## Quick Start

```bash
git clone https://github.com/hansung-hwang/anyonecan.git
cd anyonecan
```

**Windows**
```powershell
.\setup.ps1
```

**Mac / Linux**
```bash
chmod +x setup.sh
./setup.sh
```

Follow the prompts:

```
Project name (lowercase, hyphens allowed): my-service
Project description: Order management service
Author: hansung-hwang
Language: 1=TypeScript / 2=Python / 3=Java
Comment/description language: 1=English / 2=Korean (한국어)
Output directory (default: ./my-service):
```

After completion, the script automatically:
1. Copies `harness-core/`
2. Overlays the language pack (on top of harness-core)
3. Substitutes placeholders like `{{PROJECT_NAME}}`
4. For Java: auto-generates the package directory structure
5. Installs dependencies (`pnpm install` / `uv sync` / Maven check)
6. Runs `git init` + initial commit

In the generated project:
```bash
cd my-service
claude        # when using Claude Code
# /start      # start session — reads .workspace/STATUS.md for where you left off
# /plan       # before non-trivial work — write a design doc to .workspace/plans/
# /done       # at session end — log progress so the next session can resume instantly
```

---

## Architecture Principles

Layer dependency (unidirectional):

```
domain  ←  application  ←  infrastructure  ←  presentation
```

- `domain`: Pure business logic, no external library dependencies
- `application`: Use cases, orchestrates domain
- `infrastructure`: DB, external APIs, file system
- `presentation`: UI, REST/GraphQL routers

These rules are automatically enforced by per-language architecture tests.

---

## Work Journal

Every generated project ships with `.workspace/`, so work survives an
unplanned session end and a fresh session can resume immediately:

- **`STATUS.md`** — current snapshot (goal, progress, next steps, blockers), overwritten each session close-out
- **`worklog.md`** — append-only history of completed sessions
- **`plans/`** — per-task design docs with progress checklists, written via `/plan` before non-trivial work so the user can see what's being designed and how far along it is

`/start` reads `STATUS.md` (and the active plan, if any) to resume instantly.
`/done` closes the checklist, appends to `worklog.md`, and resets `STATUS.md`.
`AGENTS.md`/`README.md` are **not** used for this — they stay lean and are
only touched when a rule, convention, or user-facing behavior actually
changes.

---

## Steering Loop

Hardens the harness so the same mistake never repeats.

```
Mistake occurs
    ↓
Run /fix  (Claude Code)  or  use fix.md prompt  (other tools)
    ↓
Classify mistake type
    ├── Auto-detectable by linter  →  Add rule to linter config
    ├── Code habit/pattern issue   →  Add to AGENTS.md (single rule source)
    └── Architecture decision      →  Write new ADR in docs/adr/
    ↓
Confirm ./scripts/validate.sh passes
    ↓
Record in HARNESS-CHANGELOG.md
    ↓
Harness hardened
```

---

## Framework Versioning & Upgrades

Every generated project carries `HARNESS-VERSION` and `.harness-meta.json`
(the answers given at generation time). When the framework itself improves,
existing projects don't have to stay frozen at their generation date:

```bash
# Windows
.\upgrade.ps1 -ProjectDir "C:\projects\my-service"

# Mac / Linux
./upgrade.sh /path/to/my-service
```

Upgrade only touches files listed as **framework-owned** in
`harness-core/harness-manifest.json` — workflow commands, hooks, arch
tests, `scripts/validate.sh`, CI config, ADR 001. It never touches
`AGENTS.md`, `CLAUDE.md`, `README.md`, `HARNESS-CHANGELOG.md`,
`.workspace/STATUS.md`/`worklog.md`/`plans/*.md`, or any build config
(`eslint.config.js`, `tsconfig.json`, `pom.xml`, ...) — those are yours.
A few files that a project might not have yet (e.g. `.workspace/STATUS.md`
for a project generated before it existed) are created only if missing,
never overwritten. Changes are left uncommitted so you can review
`git diff` before committing.

Any change to a framework-owned file requires bumping
`harness-core/HARNESS-VERSION` and logging it in `FRAMEWORK-CHANGELOG.md`
(see `AGENTS.md` → "Framework Versioning").

---

## Adding a New Language Pack

1. Create `language-packs/<language>/` directory
2. Write required files:
   - `scripts/validate.sh` — validation command for that language
   - `scripts/lint-format-hook.sh` — for PostToolUse hook (optional)
   - `.claude/settings.json` — hook configuration
   - `.github/workflows/ci.yml` — CI configuration
   - Architecture tests at `src/tests/arch/` or equivalent path
3. Add language choice and language-specific rules to `setup.ps1` / `setup.sh`
4. Register the language's `scripts/validate.sh` and arch-test path under
   `languageSpecific` in `harness-core/harness-manifest.json`, so `upgrade`
   knows which files to update for that language
5. Confirm framework self-validation passes with `pnpm validate`
