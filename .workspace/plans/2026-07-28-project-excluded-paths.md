# Project-declared excluded paths (ending Homographormer's permanent `.new`)

- **Date**: 2026-07-28
- **Status**: Done — shipped as 1.8.0, all of E1-E7 complete (2026-07-29).

> **Closed 2026-07-29.** All of E0-E7 done in one session (see checklist
> below for what each phase actually delivered). Nothing left to resume —
> `Homographormer` is on `chore/harness-upgrade-1.8.0` (commit `3b10776`,
> not merged to `main` — that's still the project owner's call, see E6),
> and the framework repo's own `git status` at handoff has the expected
> `harness-core/`, `language-packs/*/`, `setup.sh`, `README.md`,
> `FRAMEWORK-CHANGELOG.md` changes plus the new
> `harness-core/.harnessignore` and untracked `Homographormer/`, all
> uncommitted pending the user's review.

## Goal

Let a project declare "these directories hold vendored / reference / research
code — framework tooling must skip them" **without editing a framework-owned
file**. Today the only way to express that is to edit the arch test and the
lint hook directly, which permanently reclassifies both as customized and
regenerates a `.new` for each on every upgrade, forever.

Target outcome: `Homographormer` carries **zero** customized framework files,
and its future upgrades are genuinely just "run the command, validate, commit".

## Approach

### Is this justified? (the n-bar, answered honestly)

**The relevant precedent is 1.6.1's `STDLIB_ROOTS` fix**, and its bar was
**two occurrences on one project**, not two projects —
`FRAMEWORK-CHANGELOG.md:126-127` states it plainly: *"The same project had
already re-added the same two names once before, during its 1.2.0 → 1.3.0
upgrade — this cost it manual work twice."*

`Homographormer` has now paid this cost **three times** — the same two files
were re-offered as `.new` at 1.3.0→1.6.0, 1.6.0→1.6.1, and 1.6.1→1.7.0 — and
will pay it at every future upgrade with no end condition.

**Counter-argument, stated rather than buried**: `README.md`'s Cautions
already documents this as designed behavior ("Editing a framework-owned file
is allowed but not free... every future upgrade will offer you a merge
instead of applying cleanly"). One could argue the system is working as
intended and the project should simply absorb the cost.

**Why proceeding anyway**: the `STDLIB_ROOTS` case involved *losing work*
(names had to be re-added), which is strictly worse per occurrence than this
case, where the customization survives and the cost is recurring review.
But this case is **unbounded** — there is no version at which it stops, and
it is paid by every upgrade of a project the framework is otherwise trying
to make cheap to upgrade. Also, unlike a project quirk, the underlying need
("this tree contains code I didn't write and don't want linted or
arch-checked") is general, not specific to this project.

### What the two customizations actually are

Both express the same single idea:

1. `tests/arch/test_dependencies.py` — adds `EXCLUDED_SOURCE_DIRS =
   {"HomoGraphormer_original"}` and a `collect_py_files()` helper that filters
   it out of every arch check.
2. `scripts/lint-format-hook.sh` — adds a `case` guard skipping
   `*/HomoGraphormer/*` and `*/src/HomoGraphormer_original/*`, plus a
   `tr '\\' '/'` normalization because Windows delivers `file_path` with
   backslashes.

### Where the exclusion list lives — decided by Java

Three candidate homes were considered; **the Java language pack settles it**:

| Option | Verdict |
|---|---|
| `.harness-meta.json` (new key) | **Rejected.** Java's arch test has *no JSON parser available* — `pom.xml` carries only junit + archunit, and the JDK ships none. Reading an exclusion list there would force a JSON dependency into every generated Java project purely for this. |
| Language-native config (`pyproject.toml` / `package.json` / `pom.xml`) | **Rejected.** Three parsers, three locations, and all three are user-owned build files the framework can't seed consistently. Worst option for cross-language parity. |
| **Plain-text `.harnessignore`** (one pattern per line, `#` comments) | **Chosen.** Readable with zero dependencies in all four consumers: bash (`while read`), Node (`readFileSync().split`), Python (`read_text().splitlines()`), Java (`Files.readAllLines`, already imported). |

`.harnessignore` is **user-owned** and registered as `bootstrapIfMissing` —
seeded once (empty, with explanatory comments), never overwritten. That is
what makes the framework-owned scripts generic again: with no project name
hardcoded, both files go back to byte-identical-to-template, and the
recurring `.new` ends permanently.

Matching semantics (keep deliberately small): patterns match against the
**forward-slash-normalized path relative to the project root**; a bare name
matches any path segment. No globbing engine, no negation — those can be
added later if a real case demands, and cannot be removed once shipped.

### Scope across languages

Consumers needing the exclusion, verified against the manifest:

- **Arch tests — all three**: `tests/arch/test_dependencies.py` (python),
  `src/tests/arch/dependencies.test.ts` (typescript),
  `src/test/java/arch/DependencyTest.java` (java).
- **Lint hooks — two**: `scripts/lint-format-hook.sh` (python),
  `scripts/lint-format-hook.mjs` (typescript). Java wires no `PostToolUse`
  hook at all.

### Two real bugs found while researching this — both in scope

1. **The template's Python lint hook has no Windows path normalization.**
   `Homographormer` hit this for real (its own comment dates it 2026-07-19:
   backslash `file_path` made the exclusion pattern silently not match) and
   fixed it *only in its own copy*. The template is still unfixed, so every
   Windows Python project would hit the same bug the moment it adds an
   exclusion. The `tr '\\' '/'` normalization must be upstreamed as part of
   this work, not left as a project-local patch.
2. **`language-packs/typescript/scripts/lint-format-hook.mjs` is not in
   `harness-manifest.json`.** It is copied at generation (via the language
   pack overlay) and actively wired by that pack's `.claude/settings.json`
   (`node scripts/lint-format-hook.mjs`), but `upgrade` has never managed it
   — so every TypeScript project's copy is frozen at its generation date and
   no fix to it has ever reached an existing project. This is exactly the
   failure mode `AGENTS.md` warns about ("must be registered in
   `harness-manifest.json` or `upgrade` silently never delivers it"). It has
   to be registered here regardless, since this plan changes that file.

### Version bump

Unlike 1.7.0, this one is unambiguous: the files being changed
(`language-packs/*/tests/arch/*`, `language-packs/*/scripts/lint-format-hook.*`)
**are** manifest-owned, so `AGENTS.md` → Framework Versioning requires a bump
outright. New capability, no breaking manifest change → **1.8.0** (minor),
plus a `FRAMEWORK-CHANGELOG.md` entry.

## Checklist

- [x] **E0 — design gate closed 2026-07-28**, user confirmed with no
      changes: `.harnessignore` at project root, match semantics as stated
      above, `bootstrapIfMissing` (user-owned). Exact rule fixed here so all
      five consumers implement the same thing: normalize the path to forward
      slashes and take it relative to the project root; a pattern containing
      no `/` matches if **any path segment equals it**; a pattern containing
      `/` matches if the normalized relative path **contains it as a
      substring**. Blank lines and `#` comments ignored. No globbing, no
      negation.
- [x] **E1 — Python pack** (2026-07-29): `collect_py_files()` and
      `test_file_naming_convention()` in `test_dependencies.py`, and
      `lint-format-hook.sh`, all read `.harnessignore` via a shared
      `is_ignored()`/inline-bash equivalent. Backslash normalization (bug 1)
      upstreamed into the bash hook. Live-verified: pytest catches a real
      violation, `.harnessignore` suppresses it, removing the entry restores
      it; hook live-tested with a genuine Windows backslash path against
      both an excluded file (untouched) and a non-excluded file (reformatted
      by ruff).
- [x] **E2 — TypeScript pack** (2026-07-29): same in `collectTsFiles()`
      (`dependencies.test.ts`) and `lint-format-hook.mjs`; **`.mjs`
      registered in the manifest** (bug 2) under `languageSpecific.typescript`,
      `docs/how-to/file-ownership.md`'s Framework tier updated to match.
      Live-verified via `vitest run` against a real generated project:
      baseline inert (15/15 pass), break-test violation caught, suppressed
      by `.harnessignore`, restored on removal; hook live-tested with a real
      Windows path the same way as Python.
- [x] **E3 — Java pack** (2026-07-29): `DependencyTest.java` reads
      `.harnessignore` via `Files.readAllLines`, applied through a custom
      ArchUnit `ImportOption` (covers all `ClassFileImporter`-based checks)
      plus the same `isIgnored()` helper in the file-existence check. No
      `mvn`/`javac` on this box, so verification stayed structural
      (generation + code review + confirming `{{BASE_PACKAGE}}`
      substitution is byte-identical to the template) — consistent with
      1.4.0 through 1.7.0.
- [x] **E4 — manifest + bootstrap** (2026-07-29): `.harnessignore` registered
      under `bootstrapIfMissing`; `scripts/check-sync.mjs` passes; seeded
      commented-empty template at `harness-core/.harnessignore`.
- [x] **E5 — verify against real projects, not simulation** (2026-07-29):
      generated one project per language via `setup.sh` into scratch
      (Java needed a real base package, TypeScript/Python didn't). All (a)
      seeded-empty-is-inert, (b) break-test-then-restore, and (c)
      real-Windows-backslash-path checks done live, not simulated — see E1/E2
      above for specifics. **Found and fixed an unrelated pre-existing bug
      along the way**: `setup.sh`'s `python3`-subprocess capture picks up a
      trailing `\r` on this box's Windows `python3` (text-mode stdout), which
      silently broke Java's `postGenerate` detection and left
      `{{BASE_PACKAGE}}` unsubstituted — fixed by stripping `\r` from
      `PACKS_RAW`/`INSTALL_DATA` in `setup.sh` (not manifest-owned, no
      version bump required, folded into 1.8.0's changelog entry anyway).
- [x] **E6 — migrate `Homographormer` and prove the payoff** (2026-07-29):
      new branch `chore/harness-upgrade-1.8.0` off the existing
      `chore/harness-upgrade-1.7.0` (continuing the established sequential-
      branch pattern; merging any of the four to `main` is still the project
      owner's call, unchanged from the 1.7.0 handoff note). Wrote
      `HomoGraphormer` + `HomoGraphormer_original` into `.harnessignore`,
      reverted both customized files to the (now `.harnessignore`-aware)
      template — both byte-identical to `language-packs/python`'s copies.
      `upgrade.sh Homographormer --verify` reports **"OK: no file content
      changes (already current)"** — zero customized files, zero `.new`.
      Full `scripts/validate.sh` (mypy + ruff + pytest, 14 tests) passes;
      the two lint-hook exclusions live-tested with real Windows paths
      (untouched); committed as `3b10776`.
- [x] **E7 — docs + version** (2026-07-29): `harness-core/HARNESS-VERSION`
      → 1.8.0; `FRAMEWORK-CHANGELOG.md` entry added (covers the feature, the
      two upstreamed bugs, and the `setup.sh` `\r` fix); `README.md`'s
      "Editing a framework-owned file is allowed but not free" Caution and
      its tier table now mention `.harnessignore`; `harness-core/AGENTS.md`
      and `docs/how-to/file-ownership.md` (Yours-tier prose + Framework-tier
      list) updated to match. `check-sync.mjs` and `pnpm validate` both
      clean at session end.

## Notes

- **The real measure of success is E6**, not E1-E4. If `Homographormer` ends
  with zero customized framework files, the feature worked; if it still needs
  a hand-edit for some reason the design didn't anticipate, that's a finding
  worth recording rather than papering over.
- **Deliberately not building**: a glob/negation syntax, per-tool exclusion
  scoping (e.g. "skip lint but still arch-check"), or exclusion of anything
  outside these five consumers. No evidence any is needed; all are additive
  later, and none can be walked back once shipped.
- **Still deferred, unchanged**: the `agentsSectionAliases` map for
  translated `AGENTS.md` headings (n=1, un-defer trigger is a second
  non-English project) — noted here only so the two aren't confused; they're
  unrelated.
- Direct predecessors: `.workspace/plans/2026-07-28-agents-section-drift-detection.md`
  (1.7.0, same session) and the 1.6.1 `STDLIB_ROOTS` work recorded in
  `.workspace/plans/2026-07-27-upgrade-feedback-from-eacc-1.6.0.md`, whose
  n-bar reasoning this plan reuses.
