# File Ownership

Which files in this project you may edit freely, which the framework manages and will overwrite on `upgrade`, and
what happens if you edit one of those anyway. Answering "can I edit this file?" should never require reading
framework source — this guide plus `harness-manifest.json` is the whole answer.

## 1. The three tiers

Every path in this project falls into exactly one of three tiers. **`harness-manifest.json` is the source of
truth** — your project's copy, refreshed by every `upgrade`. The Framework tier below is a hand-written mirror of
it, but not an unchecked one: the framework repo's `scripts/check-sync.mjs` fails its build whenever this list and
the manifest disagree, so a drift gets caught before it ships rather than silently rotting here. If the two ever
*do* disagree in your copy, believe the manifest — that's what `upgrade` actually reads.

### Yours — edit freely, `upgrade` never touches these

`AGENTS.md`, `CLAUDE.md`, `README.md`, `HARNESS-CHANGELOG.md`, all source code, build config
(`package.json`/`tsconfig.json`/`pyproject.toml`/`pom.xml`/etc.), linter config, `.workspace/STATUS.md`,
`.workspace/worklog.md`, `.workspace/plans/*.md` (except `plans/README.md`, which is framework-owned), `docs/adr/**`,
`.harnessignore`, and the project-specific `*project-rules*` architecture test
(`src/tests/arch/project-rules.test.ts` / `tests/arch/test_project_rules.py` /
`src/test/java/arch/ProjectRulesTest.java`, depending on language). Some of these are seeded once by
`setup`/`upgrade` if missing (`STATUS.md`, `worklog.md`, ADR 001, `.harnessignore`, the project-rules test) — but
once created, they're never touched again. They're yours from the moment they exist.

`.harnessignore` lists vendored/reference/research paths the framework's arch tests and lint hooks should skip —
edit it instead of hand-patching a Framework's-tier file when you need to exclude a directory (see its own header
comment for the pattern syntax).

### Framework's — do not edit; `upgrade` overwrites these when you haven't customized them

<!-- framework-tier:start -->
- `HARNESS-VERSION`
- `.claude/commands/adr.md`
- `.claude/commands/commit.md`
- `.claude/commands/coordinate.md`
- `.claude/commands/coverage.md`
- `.claude/commands/done.md`
- `.claude/commands/fix.md`
- `.claude/commands/plan.md`
- `.claude/commands/review.md`
- `.claude/commands/start.md`
- `.claude/commands/team.md`
- `.claude/commands/test.md`
- `.editorconfig`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `docs/how-to/file-ownership.md` (this file)
- `docs/how-to/git-workflow.md`
- `docs/how-to/multi-agent-collaboration.md`
- `docs/how-to/testing-guide.md`
- `.workspace/plans/README.md`
- `scripts/status-context.sh`
- `scripts/validate.sh`
- `scripts/validate.ps1` (Python projects only)
- `scripts/lint-format-hook.sh` (Python projects only)
- `scripts/lint-format-hook.mjs` (TypeScript projects only)
- `src/tests/arch/dependencies.test.ts` (TypeScript projects only)
- `tests/arch/test_dependencies.py` (Python projects only)
- `src/test/java/arch/DependencyTest.java` (Java projects only)
- `.claude/settings.json`
- `.github/workflows/ci.yml`
- `.husky/pre-commit`
- `harness-manifest.json`
<!-- framework-tier:end -->

Only the paths matching your project's language pack actually exist on disk — the language-specific ones for the
other two languages are listed for completeness, not because they're present in your project too.

### Customizable, at a cost — your version is kept, but every upgrade re-offers the merge

Any Framework's-tier file you deliberately modify falls into this tier automatically — there's no separate list,
because it's not a fixed set of paths, it's a *state* any framework-owned file can be in. See §3 for exactly what
happens.

## 2. Don't create new files inside framework-owned directories

The single highest-value rule in this guide. A framework-owned *directory* (`.claude/commands/`, `docs/how-to/`,
`scripts/` for the specific files listed above) can gain new paths in a future framework release — and if you've
already put a file of your own at that exact path, `upgrade` has no way to know it's yours (see §3's "newly
managed" case). Avoiding the collision is cheaper than recovering from it.

**Put project-specific documentation in `docs/guides/` instead of `docs/how-to/`.** `docs/how-to/` is exclusively
framework-owned reference material; `docs/guides/` doesn't exist in the manifest and never will — it's yours,
permanently, for anything project-specific: a customized multi-agent workflow, an onboarding doc, an internal
runbook. Same idea already established for architecture tests: your project-specific checks belong in
`*project-rules*` files (§1), never appended into the framework-owned `*dependencies*` test.

## 3. How the `.new` protection works

You never lose work to an upgrade, but you also never get silent auto-merges. Two related cases:

- **You edited a Framework's-tier file directly** (e.g. added a line to `.claude/settings.json`). `upgrade`
  detects your copy no longer matches its recorded baseline, leaves your file untouched, and writes the incoming
  template alongside it as `<file>.new`.
- **The framework claimed a path you'd already written to** (the §2 collision). Same outcome — your file is left
  alone, the template arrives as `<file>.new` — reported separately as "newly managed by the framework" so you know
  *why* a `.new` appeared for a file you never knowingly customized.

Either way: diff your file against its `.new`, merge by hand, delete the `.new`. If the merge makes your file
match the incoming template byte-for-byte, the *next* upgrade recognizes that and stops offering it as a merge. If
it doesn't match exactly — likely for anything substantially customized — the `.new` keeps reappearing on every
future upgrade. That's not a bug; it's the only honest signal available without a real three-way merge.

## 4. Checking a path's tier yourself

1. Look it up in your project's `harness-manifest.json`: in `frameworkOwned` or your language's
   `languageSpecific` list → Framework's tier. In `bootstrapIfMissing` or your language's
   `bootstrapLanguageSpecific` list → Yours (seeded once, never overwritten). Not listed at all → Yours.
2. When unsure whether editing a Framework's-tier file is safe: it's never *unsafe* — `upgrade` will never discard
   your change, per §3. It just means every future upgrade offers you a merge instead of applying cleanly.

**Keeping your manifest copy current.** `harness-manifest.json` is itself Framework's-tier as of harness 1.6.0, so
`upgrade` refreshes it like any other managed file — which is what stops the ownership map going stale, the
original reason this whole contract exists. Two caveats worth knowing:

- **Upgrading a project created before 1.6.0**: the first upgrade past 1.6.0 hands your manifest over as
  `harness-manifest.json.new` rather than refreshing it in place. That's the §3 "newly managed" case doing its job
  — before 1.6.0 there was no recorded baseline for this path, so `upgrade` can't prove your copy is untouched.
  Diff it (it's almost certainly just the newer manifest), replace yours, delete the `.new`. From then on it
  refreshes silently.
- **If you edit your manifest copy**, it becomes customized like any other Framework's-tier file, and `upgrade`
  will only ever offer `.new`s instead of refreshing it. Since your copy is purely informational — `upgrade` reads
  the framework's own manifest, never yours — editing it buys nothing and costs you the auto-refresh. Don't.
