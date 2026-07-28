# Project-declared excluded paths (ending Homographormer's permanent `.new`)

- **Date**: 2026-07-28
- **Status**: In Progress — **design ratified, implementation not started.**

> **Resume here (next session).** E0 is closed and the design is settled; no
> implementation file has been touched. `git status` was clean of any
> `language-packs/`, `harness-core/`, `upgrade.*`, or `setup.*` change at
> handoff (handoff SHA below). Start at **E4**, not E1 — the
> `.harnessignore` template file and its manifest registration are the
> shared artifact every other phase depends on, so building it first keeps
> E1-E3 from each inventing their own contract. Facts already gathered, so
> they don't need re-deriving:
> - Template lives at `harness-core/.harnessignore`;
>   `bootstrapIfMissing` currently holds `.workspace/STATUS.md`,
>   `.workspace/worklog.md`, `docs/adr/001-clean-architecture-layers.md` —
>   add it there (language-agnostic, so *not* `bootstrapLanguageSpecific`).
> - Five consumers to update: arch tests for all three languages
>   (`tests/arch/test_dependencies.py`, `src/tests/arch/dependencies.test.ts`,
>   `src/test/java/arch/DependencyTest.java`) and two lint hooks
>   (`scripts/lint-format-hook.sh` python, `scripts/lint-format-hook.mjs`
>   typescript). Java has no `PostToolUse` hook.
> - The Python lint hook already shells out to `python3` to parse the hook's
>   own JSON stdin, so reading a plain-text file there is trivial.

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
- [ ] **E1 — Python pack**: read `.harnessignore` in `test_dependencies.py`'s
      `collect_py_files()` and in `lint-format-hook.sh`; upstream the
      backslash normalization (bug 1 above) at the same time.
- [ ] **E2 — TypeScript pack**: same in `dependencies.test.ts` and
      `lint-format-hook.mjs`; **register the `.mjs` in the manifest** (bug 2).
- [ ] **E3 — Java pack**: same in `DependencyTest.java` via
      `Files.readAllLines`. Note the standing environment limit — no
      `mvn`/`javac` on this box, so Java verification stays structural
      (generation + code review), consistent with 1.4.0/M4 through 1.7.0.
- [ ] **E4 — manifest + bootstrap**: register `.harnessignore` under
      `bootstrapIfMissing`; confirm `scripts/check-sync.mjs`'s
      manifest-registration guard still passes; seed a commented empty file.
- [ ] **E5 — verify against real projects, not simulation**: (a) generate a
      fresh project per language and confirm the seeded `.harnessignore` is
      inert (no behavior change when empty); (b) **break-test** — add a real
      exclusion and confirm the arch test and lint hook both honor it, and
      that removing it restores the violation; (c) confirm the Windows
      backslash path is actually exercised, not assumed.
- [ ] **E6 — migrate `Homographormer` and prove the payoff**: write its two
      directories into `.harnessignore`, revert both customized files to the
      template, run `upgrade --verify` and confirm **zero** customized files
      and **zero** `.new` — the whole point of this plan. Then run its full
      `validate.sh` to prove the arch checks still exclude the research tree
      exactly as before.
- [ ] **E7 — docs + version**: bump to 1.8.0; `FRAMEWORK-CHANGELOG.md`
      entry; `README.md` Cautions currently names editing a framework file as
      "the single most common way to end up with a recurring `.new`" — it
      should now point at `.harnessignore` as the supported alternative for
      this case; `docs/how-to/file-ownership.md` likely needs the same.

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
