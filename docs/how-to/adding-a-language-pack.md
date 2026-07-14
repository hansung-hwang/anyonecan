# Adding a Language Pack

A language pack is an overlay copied on top of `harness-core/` by
`setup.ps1`/`setup.sh` (see `language-packs/typescript`, `/python`, `/java`
for reference implementations). This is the **contract** a new pack must
satisfy so setup, CI, and `upgrade` all pick it up automatically.

## 1. Directory layout

```
language-packs/<language>/
  pack.json                        # required — see schema below
  scripts/validate.sh              # required — typecheck + lint + test entrypoint
  scripts/validate.ps1             # optional — native Windows PowerShell equivalent
  scripts/lint-format-hook.sh       # optional — PostToolUse auto-format hook
  .claude/settings.json            # required — hook wiring for this language
  .github/workflows/ci.yml         # required — CI pipeline
  <arch tests>                     # required — see the 5-check matrix below
  <project-rules seed>              # required — bootstrapLanguageSpecific seed, see §6
  <language-specific source/config># build files, sample domain code, etc.
```

`pack.json` itself is **setup-time metadata only** — `setup.ps1`/`setup.sh`
delete it from the generated project after copying the pack. Every other
file in the pack directory is copied into the generated project as-is
(and then run through the standard `{{PLACEHOLDER}}` substitution pass).

## 2. `pack.json` schema

```json
{
  "language": "typescript",
  "display": "TypeScript",
  "order": 1,
  "default": true,
  "aliases": ["1", "ts", "typescript"],
  "rules": [
    "- No `any` → use `unknown` + type guards",
    "- ... one bullet per line, rendered into AGENTS.md's Coding Rules section"
  ],
  "banned": "`any` · `@ts-ignore` · ... — rendered into AGENTS.md's Prohibited section",
  "postGenerate": "java-packages",
  "install": {
    "candidates": [
      {
        "tool": "pnpm",
        "check": "pnpm",
        "run": "pnpm install",
        "retryFix": "pnpm approve-builds esbuild",
        "successMessage": "pnpm install complete"
      }
    ],
    "notFoundMessage": "pnpm not found. Run manually: pnpm install"
  }
}
```

| Field | Required | Notes |
|---|---|---|
| `language` | yes | lowercase identifier; matches the `language-packs/<language>/` directory name and `.harness-meta.json`'s `language` field |
| `display` | yes | human-readable name shown in the setup menu and AGENTS.md header |
| `order` | yes | integer controlling menu display order (does not need to be contiguous) |
| `default` | no | set `true` on exactly one pack — used when the user presses Enter without typing a choice |
| `aliases` | yes | strings that select this pack when typed at the "Enter number" prompt (case-insensitive); conventionally includes the menu number, a short code, and the full name |
| `rules` | yes | array of Markdown bullet lines substituted into `{{LANGUAGE_RULES}}` in `AGENTS.md` (joined with `\n`) |
| `banned` | yes | single string substituted into `{{BANNED_ITEMS}}` in `AGENTS.md` |
| `postGenerate` | no | opaque string flag for language-specific extra generation steps. Currently only `"java-packages"` is recognized (prompts for a base package and creates `src/main/java/<pkg>/{domain,application,infrastructure,presentation}` + substitutes `{{BASE_PACKAGE}}`). Add a new value + handle it in both `setup.ps1` and `setup.sh` if your language needs its own post-generation step — this is an intentional escape hatch rather than a fully generic plugin system |
| `install` | yes | `candidates`: ordered list of `{tool, check, run, retryFix?, successMessage}` tried in order — the first whose `check` command exists on PATH is run (via `run`; if it fails and `retryFix` is set, `retryFix` runs once and `run` is retried); `notFoundMessage` is shown if no candidate's tool is found. Use `"run": ""` for a language whose "install" step is just confirming a tool is present (e.g. Java/Maven, which downloads deps on first build) |

## 3. `scripts/validate.sh`

Must run typecheck + lint + test and exit non-zero on any failure. This is
what `/commit`, the Stop hook, and CI all invoke — everything else in the
pack should be built to make this one entrypoint meaningful. If your
language's tooling resolves a different interpreter/toolchain depending on
PATH (e.g. Python venvs), detect and prefer the project-local one explicitly
— a fallback to a bare system tool produces confusing errors that look like
real failures. Provide `scripts/validate.ps1` too if native Windows
PowerShell usage is common for the language (see the Python pack).

## 4. `.claude/settings.json` + CI

Wire a PostToolUse hook (auto-format/lint after Write/Edit, if the language
has a fast formatter) and a Stop hook that runs `scripts/validate.sh`.
`.github/workflows/ci.yml` should run the same checks as named steps
(typecheck / lint / test separately, not one bundled "validate" step) plus
a coverage gate scoped to `src/domain/**` (or the closest equivalent — see
the Java pack's `pom.xml` comment for a case where domain-scoped coverage
wasn't feasible and project-wide was used instead, documented as a
deliberate scope reduction).

## 5. Arch-test parity matrix

Every language pack must enforce the same 5 checks (see
`language-packs/*/`'s existing arch tests for reference implementations):

| Check | Purpose |
|---|---|
| Layer dependency direction | `domain ← application ← infrastructure ← presentation`, unidirectional |
| Domain purity | `domain` doesn't import external libraries |
| No same-layer circular refs | no cycles within a layer |
| File naming convention | enforces the pack's naming rule (kebab-case/snake_case/PascalCase) |
| Domain file ⇒ test file exists | every domain source file has a matching test |

## 6. Register with the upgrade manifest

Add the pack's `scripts/validate.sh` (+ `validate.ps1` if you provide one),
arch-test path(s), `.claude/settings.json`, `.github/workflows/ci.yml`, and
`.husky/pre-commit` under a new key in `harness-manifest.json`'s
`languageSpecific` map, so `upgrade.ps1`/`upgrade.sh` know which files to
refresh for projects generated with this language. If any of the pack's
files use `{{PLACEHOLDER}}` tokens beyond the standard set (`PROJECT_NAME`,
`PROJECT_DESCRIPTION`, `AUTHOR`, `DATE`, `BASE_PACKAGE`), list them under
`needsSubstitution` too.

Also add a project-owned architecture-test seed file (e.g.
`tests/arch/test_project_rules.py`) under `bootstrapLanguageSpecific` for
this language — created once if missing, never overwritten by `upgrade`, so
a project-specific arch check has somewhere to live that isn't the
framework-owned dependency-test file `upgrade` refreshes. See the existing
three packs' `test_project_rules`/`project-rules.test`/`ProjectRulesTest`
files for the expected empty-seed shape.

`.claude/settings.json` should wire a `SessionStart` hook running
`bash scripts/status-context.sh` (frameworkOwned, language-agnostic) in
addition to your pack's own hooks — this surfaces `.workspace/STATUS.md` at
the start of every session automatically.

## 7. Verify end-to-end

Generate a project with the new language via `setup.ps1`/`setup.sh` and
confirm:
- No `pack.json` in the output
- `AGENTS.md`'s Coding Rules / Prohibited sections match `pack.json`'s
  `rules`/`banned`
- `.harness-meta.json` has the right `language`
- `scripts/validate.sh` actually passes on the generated sample code
- If applicable, generate → mutate a framework-owned file → run `upgrade` →
  diff, to confirm the manifest entries are correct (see the P2 lesson in
  `FRAMEWORK-CHANGELOG.md`: anything a language pack overlays must be
  `languageSpecific`, never `frameworkOwned`, or upgrading with an unknown
  language silently downgrades the project)
- Generate → confirm `.harness-meta.json`'s `baselines` map has an entry for
  every `languageSpecific` file for this language → hand-edit one of those
  files → run `upgrade` → confirm it's left alone and a `<file>.new` appears
  instead of being silently overwritten (see the 1.3.0 lesson in
  `FRAMEWORK-CHANGELOG.md`)
