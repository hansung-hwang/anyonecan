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

| Language | Validation Tools | Architecture Test | Coverage Gate (CI) |
|----------|-----------------|-------------------|---------------------|
| TypeScript | tsc + ESLint + Vitest | `src/tests/arch/dependencies.test.ts` (5-check parity) | domain ≥ 80% (`vitest run --coverage`) |
| Python | mypy + ruff + pytest | `tests/arch/test_dependencies.py` (5-check parity) | domain ≥ 80% (`pytest --cov-fail-under=80`) |
| Java | Maven + Checkstyle + JUnit5 | `src/test/java/arch/DependencyTest.java` (ArchUnit, 5-check parity) | project-wide ≥ 80% (`mvn verify -P coverage`, JaCoCo) |

All three languages enforce the same 5 architecture checks (layer
dependency direction, domain purity, no circular refs, file naming, domain
file → test file exists) and ban the same items (`.only()`/pinned tests,
debug print statements, type-checking escape hatches) via each language's
linter — see each language pack's `harness-manifest.json` entry and
`AGENTS.md`'s Prohibited list.

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
│   │       ├── coverage.md    # Coverage check
│   │       ├── coordinate.md  # Multi-agent coordination plan (opt-in)
│   │       └── team.md        # Solo/Team mode + role scoping (opt-in)
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
Project mode: 1=Solo / 2=Team
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
# /coordinate # optional — plan a multi-agent split, only when tasks are genuinely independent
# /team       # optional — set up Solo/Team mode and role scoping, or change it any time
# /done       # at session end — log progress so the next session can resume instantly
```

---

## After Generating: What's Yours vs. the Framework's

The single most useful thing to know on day one, because it decides what a
later `upgrade` may overwrite. Your project ships with the full contract at
`docs/how-to/file-ownership.md`; this is the short version.

| Tier | Examples | What `upgrade` does |
|---|---|---|
| **Yours** | `AGENTS.md`, `CLAUDE.md`, `README.md`, all source code, build/linter config, `.workspace/STATUS.md`·`worklog.md`·`plans/*.md`, `docs/adr/**`, `.harnessignore`, the `*project-rules*` arch test | **Never touched.** Edit freely. |
| **Framework's** | `.claude/commands/**`, `docs/how-to/**`, `scripts/validate.*`, `scripts/lint-format-hook.*`, the `*dependencies*` arch test, `.editorconfig`, hook/CI config, `harness-manifest.json` | Overwritten when you haven't changed them. |
| **Customizable, at a cost** | any Framework's-tier file you deliberately edit | Your version is kept; the new template arrives as `<file>.new` for you to merge. |

`harness-manifest.json` in your project is the machine-readable source of
truth for which paths are which, and `upgrade` refreshes it every run so it
can't go stale.

**The one rule worth memorizing: don't create new files inside a
framework-owned directory.** A future release can claim any path inside
`docs/how-to/` or `.claude/commands/` — and if your own file already sits
there, `upgrade` has no way to know it's yours. Put project-specific
documentation in **`docs/guides/`** instead; the framework will never claim
that directory. (Same idea the arch tests already use: your custom checks
belong in the `*project-rules*` file, never appended into the
framework-owned `*dependencies*` one.)

**Two things you own that the framework can't update for you:** `AGENTS.md`
and `CLAUDE.md`. `upgrade` prints a reminder by hand in three cases: a new
slash command (add it to `AGENTS.md`'s Workflow Prompts table and
`CLAUDE.md`'s command list); a new `AGENTS.md` **section** shipped by a
later framework release — 1.4.0's "Handoff and Reporting" and 1.6.0's "File
Ownership" both landed this way, and a project generated before either
release won't have them unless you add them yourself; and, since 1.7.0, a
section your `AGENTS.md` **already has** whose *template body* changed since
your last upgrade — the heading matches so nothing looks missing, but the
framework's own wording moved on. `upgrade`/`--dry-run`/`--verify` all
compare your `AGENTS.md`'s headings against the current template for the
first two, and a per-section content hash (recorded in `.harness-meta.json`,
never comparing your own prose) for the third — so a section you translated
or rewrote never gets flagged as if it were wrong, only ever "the framework's
version changed, go look".

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

**Multiple sessions or sub-agents on the same project at once** is opt-in and
adds nothing to a single-agent project: `AGENTS.md`'s "Handoff and
Reporting" section (clean handoff, fixed-SHA review, requirement→location
reporting) applies at any actor count, while `/coordinate` and the plan
template's optional `Parallelization` block only activate when you use them.
Full model: `docs/how-to/multi-agent-collaboration.md`.

---

## Team Roles

Also opt-in, and orthogonal to the coordination above — `/coordinate` splits *one task* across agents; `/team` sets
*standing* ownership of the codebase. Solo (the default) adds nothing beyond one setup prompt and one command.
Choosing Team at setup, or running `/team` at any point afterward, lets you assign a role — Planner, Architect,
Backend, Frontend, Data/DBA, Infra/DevOps, QA/Test by default, or your own — to each person, mapped onto the same
clean-architecture layers this framework already enforces rather than a separate ACL system. An agent working under
a declared role restricts its edits to that role's owned files and escalates anything cross-role as a request note
instead of editing directly, reusing the same escalation pattern a sub-agent already uses toward a Coordinator.
Enforcement is by convention (`AGENTS.md` + the multi-agent guide) as of 1.5.0 — see
`docs/how-to/multi-agent-collaboration.md` §13 for the full model and `/team`'s own command file for the default
role catalog.

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
(the answers given at generation time, plus a baseline hash of every managed
file). When the framework improves, existing projects don't have to stay
frozen at their generation date.

### The upgrade workflow

**1. Branch first** — especially on a real project with work in flight.
`upgrade` writes into your working tree and never commits, so a branch keeps
`main` clean regardless of what you decide afterwards.

```bash
git checkout -b chore/harness-upgrade
```

**2. Preview with `--dry-run`** (`-DryRun` on Windows). It runs the *exact
same* per-file classification a real run does — including when your version
marker already matches the framework's, so a file that was hand-reverted or
deleted since your last upgrade still gets caught — and writes **zero**
bytes. Always safe, on any project, at any time.

```bash
.\upgrade.ps1 -ProjectDir "C:\projects\my-service" -DryRun   # Windows
./upgrade.sh /path/to/my-service --dry-run                   # Mac / Linux
```

Related: **`--verify`** (`-Verify`) runs the same read-only classification
but is meant for scripting rather than reading — it exits non-zero only if a
file the framework previously delivered has since gone missing (a
customized or newly-managed file is a legitimate state, not a failure).
Useful in CI as a "did something delete a managed file" check.

**3. Read the preview** (see the table below), then run it for real — same
command, without the flag.

**4. Resolve any `.new` files.** Diff each against your version, merge by
hand, delete the `.new`. Nothing is finished while a `.new` remains.

**5. Register new slash commands, and add any missing `AGENTS.md` sections,**
if the run reported either — those files are yours, so `upgrade` can't edit
them for you. Both are printed the same way: a list of what's missing and
where it belongs.

**6. Validate and commit.** Run your project's own `./scripts/validate.sh`,
confirm `git diff` shows nothing you didn't expect, then commit.

### Reading the output

| Bucket | Meaning | Action |
|---|---|---|
| `added` | New framework file you didn't have | none |
| `updated` | You never changed it; took the new version | none |
| `bootstrapped` | Was missing; seeded once, never overwritten again | none |
| `customized locally … <file>.new` | **You edited it.** Your version kept | merge the `.new`, then delete it |
| `newly managed by the framework … <file>.new` | The framework claimed a path where **you already had a file**. Yours kept | merge the `.new`, then delete it |
| `overwritten (no baseline recorded)` | Pre-1.3.0 project, one-time migration | review with `git diff` |
| `skipped` | Source missing, or needs metadata this project lacks | usually harmless; read the reason |
| `… were previously delivered … now missing` | A managed file the framework wrote before is gone from disk | real run restores it; `--verify` exits non-zero on this |
| `AGENTS.md section(s) … missing` | A framework-authored section (e.g. 1.4.0's Handoff and Reporting, 1.6.0's File Ownership) isn't in your `AGENTS.md` | add it by hand, or ignore if deliberate |
| `AGENTS.md section(s) you already have changed …` | A section you already have moved on in the template since your last upgrade (1.7.0+) | diff against `harness-core/AGENTS.md`, pull in by hand if it applies to you |

Once a merged file matches its template exactly, the next run treats it as
caught up, advances its baseline, and deletes the stray `.new` automatically
— there's no separate "mark as resolved" step. If it *never* matches exactly
(a heavily customized or translated file), the `.new` reappears every run.
That's not a bug — it's the only honest signal available without a real
three-way merge. To end it permanently, move your version to a path the
framework doesn't own (e.g. `docs/guides/`).

### Cautions

- **`upgrade` never commits.** Changes are left in your working tree
  deliberately, so you review before they become history.
- **Never create files inside `docs/how-to/` or `.claude/commands/`.** A
  future release can claim that exact path. Use `docs/guides/` for your own
  documentation. This is the single most common way to end up with a
  recurring `.new`.
- **Editing a framework-owned file is allowed but not free.** It's never
  unsafe — your change is never discarded — but every future upgrade will
  offer you a merge instead of applying cleanly. If what you actually need is
  to exclude a vendored/reference directory from the arch tests and lint
  hooks, use `.harnessignore` instead (project root, one pattern per line) —
  it's yours, `upgrade` never touches it, and it keeps the arch test and lint
  hook byte-identical to the template forever.
- **Don't edit your project's `harness-manifest.json`.** It's purely
  informational (upgrade reads the *framework's* copy, never yours), so
  editing it buys nothing and costs you the automatic refresh.
- **Upgrading a project generated before 1.6.0**: the first run hands your
  `harness-manifest.json` over as a one-time `.new` rather than refreshing it
  in place, because no baseline existed for that path before. Diff it,
  replace yours, delete the `.new` — it refreshes silently from then on.
- **Upgrading a project generated before 1.3.0** (no `baselines` map at all):
  the first run overwrites framework-owned files unconditionally, with a
  loud warning, and gains customization protection from that point on. Review
  that run's `git diff` carefully.

### Contributing to the framework itself

Any change to a framework-owned file requires bumping
`harness-core/HARNESS-VERSION` and logging it in `FRAMEWORK-CHANGELOG.md`
(see `AGENTS.md` → "Framework Versioning"). "Framework-owned" means exactly
the paths in `harness-core/harness-manifest.json`'s `frameworkOwned` +
`languageSpecific` sets — `scripts/check-sync.mjs` fails the build if the
manifest and the shipped ownership guide ever disagree.

---

## Adding a New Language Pack

`setup.ps1`/`setup.sh` discover language packs by globbing
`language-packs/*/pack.json` — no edits to the setup scripts themselves are
needed to add a language.

1. Create `language-packs/<language>/` directory
2. Write `pack.json` (display name, menu order, aliases, AGENTS.md rules +
   banned items, install-tool candidates) plus the required files:
   - `scripts/validate.sh` — validation command for that language
   - `scripts/lint-format-hook.*` — for PostToolUse hook (optional; use the
     extension your pack's `.claude/settings.json` invokes — `.sh` for Python,
     `.mjs` for TypeScript). If you add one, register it in
     `harness-manifest.json` under `languageSpecific.<language>` or `upgrade`
     will never manage it — TypeScript's went unregistered until 1.8.0.
   - `.claude/settings.json` — hook configuration
   - `.github/workflows/ci.yml` — CI configuration, named typecheck/lint/test steps
   - Architecture tests implementing the 5-check parity matrix (layer
     dependencies, domain purity, no cycles, file naming, domain→test
     existence)
3. Register the pack's `scripts/validate.sh`, arch-test path(s),
   `.claude/settings.json`, `.github/workflows/ci.yml`, and
   `.husky/pre-commit` under `languageSpecific` in
   `harness-core/harness-manifest.json`, so `upgrade` knows which files to
   update for that language
4. Confirm framework self-validation passes with `pnpm validate`, then
   generate a project with the new language end-to-end and confirm
   `AGENTS.md` and `.harness-meta.json` render correctly

Full contract: `docs/how-to/adding-a-language-pack.md`.
