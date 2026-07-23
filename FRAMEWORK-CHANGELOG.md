# FRAMEWORK-CHANGELOG

Changelog for **this framework's own evolution** (`harness-core/HARNESS-VERSION`).

Not to be confused with the per-project `HARNESS-CHANGELOG.md` (copied into
every generated project), which tracks agent mistakes and the rules added
to prevent them via `/fix`. This file tracks changes to the framework
itself, so a project owner running `upgrade.ps1`/`upgrade.sh` knows what
they're pulling in.

See `AGENTS.md` → "Framework Versioning" for the bump rule.

## [1.4.0] - 2026-07-23

**Opt-in multi-agent coordination layer (slim scope):**

- Root cause / evidence: a real generated-project multi-agent session (documented in that project's own
  `docs/how-to/multi-agent-collaboration.md`) survived code review cleanly, but shared state and reporting broke in
  five repeatable ways — a reviewed file grew before commit, uncommitted work from two sessions accumulated with no
  clear boundary, `worklog.md`/`STATUS.md` drifted (duplicate rows, stale sections), a completion report claimed
  nine items reflected when only review notes had changed, and a test-pass claim didn't reproduce in a different
  environment (a writable-temp-path difference, not a code defect). None of these were code-quality failures — the
  harness had nothing standardizing shared-state handoff or reporting.
- New `AGENTS.md` section **"Handoff and Reporting"** (after Work Journal, before Key Invariants): clean handoff
  (a WIP commit if commit authority exists, otherwise an explicitly declared owned diff — never a silent dirty
  handoff), fixed-SHA review (re-review if Head moves), `requirement → file/symbol/test location` reporting instead
  of counts, and command+working-directory+environment evidence on validation claims. **Applies at any actor
  count** — three of the five source incidents happened in a single session, so this isn't multi-agent-gated.
- New `docs/how-to/multi-agent-collaboration.md` guide (framework-owned, added to every project): Coordinator/
  Implementation/Test/Research-Review/Execution roles, worktree/branch isolation, Base SHA + per-wave single-writer
  ownership, task-assignment and completion-report templates, a file-ownership table, a Coordinator merge
  procedure, a Claude Code tool appendix (`isolation: "worktree"`, `subagent_type: "fork"`, `SendMessage`), and a
  "Working as a team (multiple people)" section (same model, PR review replaces the Coordinator's cherry-pick).
  Activates only when multiple sessions/sub-agents touch the repo at once; a solo user never needs to open it.
- New `.claude/commands/coordinate.md` (`/coordinate`): produces a coordination plan (Coordinator, Base SHA,
  per-agent file allow/deny lists, integration order) or an explicit single-agent recommendation when the task
  doesn't clear the parallelization-benefit bar. Plans only — never creates branches/worktrees or spawns agents
  itself.
- `.workspace/plans/README.md` template gains an optional `Owner` field and an optional `Parallelization` block
  (Coordinator, Base SHA, Wave assignments, integration order, completion authority) that `/plan` points to and
  `/coordinate` writes into; both are skipped entirely on an ordinary single-agent plan. `worklog.md`'s row format
  gained an optional author column, documented as a convention rather than a `/done.md` edit.
- `AGENTS.md`'s "Multiple team members" note gained one bullet: new Key Invariants entries are added **append-only
  to the bottom** (no reformatting/reordering) so concurrent edits from different people merge without conflict.
- **Deliberately deferred to 1.5.0** after a complexity-budget review: conditional coordination logic in `/start`,
  `/commit`, `/review`, and `/done` (would tax every user's most-used commands for a workflow only a minority uses)
  and a mechanical `scripts/check-agent-scope.*` scope checker (no second real use case yet to justify it). The one
  genuinely general rule inside the deferred `/review` edit — fixed-SHA review — is already covered by the
  always-on `AGENTS.md` Handoff and Reporting section, so single-agent review loses nothing by this deferral.
  Litmus applied throughout: *can a solo user ignore this feature and never notice it?* Everything shipped in 1.4.0
  passes that test.
- `scripts/check-sync.mjs` gained a third guard: every `harness-core` command and `docs/how-to` guide must be
  registered in `harness-manifest.json`'s `frameworkOwned`, or `upgrade` silently never delivers it to an existing
  project. Nothing previously caught a forgotten manifest entry.
- Full design record, including the complexity-budget scope cut and a companion team-roles/project-mode design
  (provisional 1.5.0, not part of this release): `.workspace/plans/2026-07-22-multi-agent-coordination.md` and
  `.workspace/plans/2026-07-23-team-roles-and-project-mode.md`.

**Incidental fix, found while verifying this release's upgrade path (not itself frameworkOwned, no version bump
required, noted here since it affects every upgrade run):**

- `upgrade.ps1`/`upgrade.py` never updated `.harness-meta.json`'s own `harnessVersion` field — only the standalone
  `HARNESS-VERSION` file was written, so a project's metadata silently kept reporting its pre-upgrade version
  indefinitely (baselines advanced correctly; only this one field was stale). Pre-existing since the 1.3.0
  baseline-tracking system. Fixed in both scripts and verified end-to-end against a real 1.3.0→1.4.0 upgrade.

## [1.3.0] - 2026-07-14

**Customization-safety for upgrade (dpkg-conffile-style protection):**

- Root cause: upgrading a project generated before 1.3.0 (`agentic-eacc-mcp-server`)
  showed that `upgrade` overwrites every framework-owned/language-specific file
  unconditionally, with no way to tell a file the project customized apart
  from one it never touched. Three real files were silently clobbered on
  that project's first upgrade (a project-added `SessionStart` hook in
  `.claude/settings.json`, a project-specific arch test appended to
  `tests/arch/test_dependencies.py`, and Python-specific wording in
  `docs/adr/001-*`) and had to be manually restored with `git checkout`
  after the fact.
- `setup.ps1`/`setup.sh` now record a baseline (LF-normalized SHA-256) of
  every frameworkOwned/languageSpecific file into `.harness-meta.json`'s new
  `baselines` map at generation time (`HARNESS-VERSION` itself excluded --
  it's an unconditional marker, not a mergeable template).
- `upgrade.ps1`/`upgrade.py` (shared by `upgrade.sh`) now branch per file:
  unmodified-since-baseline → overwrite + advance baseline; modified →
  leave the project's file alone and write the new template as `<file>.new`
  for manual merge (baseline stays at the old hash so the next upgrade
  offers the merge again); a project's file matching its `.new` exactly on
  a later run is treated as caught up and the stray `.new` is cleaned up
  automatically -- no separate "mark as merged" step needed. Projects
  upgrading from a pre-1.3.0 `.harness-meta.json` (no `baselines` map) fall
  back to the old always-overwrite behavior for one run with a warning, then
  gain baseline tracking from that point on.
- `docs/adr/001-clean-architecture-layers.md` reclassified from
  `frameworkOwned` to `bootstrapIfMissing` -- an ADR is a project decision
  record from the moment it's created (this project's own copy already had
  Python-specific wording), so upgrade should never have been overwriting it.
- New `bootstrapLanguageSpecific` manifest section seeds a project-owned
  architecture-test extension point per language (`tests/arch/test_project_rules.py`
  / `src/tests/arch/project-rules.test.ts` / `src/test/java/arch/ProjectRulesTest.java`)
  -- created once if missing, never overwritten, so a project-specific arch
  check has a home that isn't the framework-owned dependency-test file.

**Methodology backport (from real framework usage on `agentic-eacc-mcp-server`):**

- `SessionStart` hook added to all three language packs' `.claude/settings.json`,
  wired to a new frameworkOwned `harness-core/scripts/status-context.sh` that
  prints `.workspace/STATUS.md` at the start of every session -- so the
  current work snapshot is surfaced automatically instead of relying on the
  agent remembering to run `/start` or read `STATUS.md` on its own.
- `AGENTS.md` template gains a "Key Invariants (do not break)" section
  (seeded empty, with an instruction to accumulate one bullet per incident
  or non-obvious design decision) -- the project's real accumulated value
  observed was in this kind of distilled, hard-won rule, not in restating
  generic coding style.
- Work Journal section now says to update `STATUS.md` and affected docs
  **the moment** a meaningful change lands, not just at `/done` session
  close-out -- more resilient to an unplanned session end.
- Python pack's `scripts/validate.sh` now prefers `.venv/bin/python` or
  `.venv/Scripts/python.exe` over whatever `python`/`python3` resolves to on
  PATH (a bare system Python produces confusing import-not-found errors that
  look like real mypy failures); new `scripts/validate.ps1` added for native
  Windows PowerShell use, registered in the manifest.
- `start.md`'s Read Work State step now also greps `.workspace/plans/*.md`
  for any `- **Status**: In Progress` beyond the one `STATUS.md` points at,
  so a second in-flight plan isn't silently missed.

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
