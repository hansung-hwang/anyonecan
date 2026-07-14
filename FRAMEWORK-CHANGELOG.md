# FRAMEWORK-CHANGELOG

Changelog for **this framework's own evolution** (`harness-core/HARNESS-VERSION`).

Not to be confused with the per-project `HARNESS-CHANGELOG.md` (copied into
every generated project), which tracks agent mistakes and the rules added
to prevent them via `/fix`. This file tracks changes to the framework
itself, so a project owner running `upgrade.ps1`/`upgrade.sh` knows what
they're pulling in.

See `AGENTS.md` → "Framework Versioning" for the bump rule.

## [1.2.0] - 2026-07-14

**P4 — Team collaboration layer:**

- Added `harness-core/.github/PULL_REQUEST_TEMPLATE.md` (tests included?
  validate passes? plan doc linked? ADR written? AGENTS.md updated?).
- Moved `docs/how-to/git-workflow.md` and `testing-guide.md` into
  `harness-core/docs/how-to/`, generalized to be language-agnostic (they
  previously only existed in this framework repo's own docs and were never
  copied into generated projects). `component-guide.md` stays root-only —
  it documents this repo's own TypeScript conventions, not a
  generated-project template.
- Documented multi-member `.workspace/` conflict handling
  (`.workspace/plans/README.md` + `AGENTS.md` Work Journal section, both
  copies): `STATUS.md` is a per-branch snapshot, `worklog.md` is
  append-only and should keep both sides' rows on merge conflict.
- Split the single "Validate" CI step into named `Typecheck` / `Lint` /
  `Test` steps for the TypeScript and Python language packs (and this
  repo's own root `ci.yml`), so PR failures point at the specific check
  that failed instead of a generic bash script. Java's `mvn verify` still
  runs as one step — Maven's build lifecycle doesn't split cheaply into
  separate typecheck/lint/test invocations.

**P5 — Data-driven language packs:**

- Added `language-packs/<lang>/pack.json` for typescript/python/java —
  display name, menu order, aliases, AGENTS.md rules + banned items,
  optional `postGenerate` flag, and an `install.candidates` list (tool
  check → run → optional retry-fix → success message).
- `setup.ps1`/`setup.sh` now discover language packs by globbing
  `language-packs/*/pack.json` instead of hardcoding a 3-way switch —
  adding a language no longer requires editing the setup scripts. `pack.json`
  is deleted from the generated project after the overlay copy (it's
  setup-time metadata only). Java's base-package prompt and package-dir
  generation are now keyed off `pack.json`'s `postGenerate: "java-packages"`
  flag rather than a hardcoded language check.
- Added `docs/how-to/adding-a-language-pack.md` — the full pack contract
  (required files, `pack.json` schema, the 5-check arch-test parity matrix,
  manifest registration, end-to-end verify steps). README's "Adding a New
  Language Pack" section rewritten to match.
- Verified: generated one project per language via `setup.ps1` with piped
  stdin (TypeScript, Python, Java — including Java's base-package prompt
  and `{{BASE_PACKAGE}}` substitution), plus alias-based input (`python`)
  and blank-input default-to-TypeScript. `setup.sh`'s equivalent rewrite
  was only syntax-checked (`bash -n`), not run end-to-end, on this Windows
  machine.

## [1.0.0] - 2026-07-13

- Baseline version. Established `HARNESS-VERSION` + `harness-manifest.json`
  + `upgrade.ps1`/`upgrade.sh`/`upgrade.py` so existing generated projects
  can pull in framework updates instead of staying frozen at generation time.
- Added `.workspace/` work journal (`STATUS.md`, `worklog.md`, `plans/`) and
  the `/plan`, `/done` commands so work survives an unplanned session end.
  `/start` now reads `.workspace/STATUS.md`; `/commit` hints at `/done`.
- Made `AGENTS.md` the single source of truth for project rules. `CLAUDE.md`
  shrinks to a header + `@AGENTS.md` import; `.cursorrules`/`.windsurfrules`/
  `.cursor/rules/harness.mdc` shrink to thin pointers. `setup.ps1`/`setup.sh`
  placeholder substitution narrowed to `AGENTS.md` only.
- Added `scripts/check-sync.mjs` (this repo's own drift guard between root
  and `harness-core` command files).
- `setup.ps1`/`setup.sh` now write `.harness-meta.json` in every generated
  project, capturing the answers given at generation time so `upgrade` can
  re-render templated files (e.g. Java's `{{BASE_PACKAGE}}`) later.
