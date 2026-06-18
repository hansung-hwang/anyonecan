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
| Claude Code | `CLAUDE.md` + `.claude/commands/` (slash commands) |
| Cursor | `.cursor/rules/harness.mdc` or `.cursorrules` |
| Windsurf | `.windsurfrules` |
| Codex / Antigravity / others | `AGENTS.md` |

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
│   ├── CLAUDE.md              # Claude Code rule template
│   ├── AGENTS.md              # Universal agent rule template
│   ├── .cursorrules           # Cursor legacy
│   ├── .cursor/rules/harness.mdc  # Cursor MDC
│   ├── .windsurfrules         # Windsurf
│   ├── .claude/
│   │   ├── settings.json      # Stop hook (auto-runs validate.sh)
│   │   └── commands/          # Workflow prompts (shared across all tools)
│   │       ├── start.md       # Session start
│   │       ├── fix.md         # Error fix loop
│   │       ├── commit.md      # Pre-commit checks
│   │       ├── review.md      # Code review
│   │       ├── test.md        # Test writing
│   │       ├── adr.md         # Architecture decision record
│   │       └── coverage.md    # Coverage check
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
└── setup.sh                   # Project generator (Mac / Linux)
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
# /start      # start session
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

## Steering Loop

Hardens the harness so the same mistake never repeats.

```
Mistake occurs
    ↓
Run /fix  (Claude Code)  or  use fix.md prompt  (other tools)
    ↓
Classify mistake type
    ├── Auto-detectable by linter  →  Add rule to linter config
    ├── Code habit/pattern issue   →  Add to AGENTS.md + CLAUDE.md
    └── Architecture decision      →  Write new ADR in docs/adr/
    ↓
Confirm ./scripts/validate.sh passes
    ↓
Record in HARNESS-CHANGELOG.md
    ↓
Harness hardened
```

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
4. Confirm framework self-validation passes with `pnpm validate`
