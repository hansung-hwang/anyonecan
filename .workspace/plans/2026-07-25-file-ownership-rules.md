# File Ownership Rules — tell projects what they may edit

- **Date**: 2026-07-25
- **Status**: Done (all phases O0-O5 complete and verified 2026-07-26; `HARNESS-VERSION` bumped to 1.6.0; not yet
  committed/pushed)
- **Target release**: Harness 1.6.0 (ships framework-owned files → bump **is** required, unlike the tooling plan)
- **Origin**: user proposal — *"생성된 하위 프로젝트에서 수정 가능한 부분과 업그레이드를 위해 접근 불가능한 부분을
  하네스 프레임워크가 규칙으로 명시해줘야 한다"* — validated against real evidence below.
- **Related**: `.workspace/plans/2026-07-25-upgrade-tooling-safety-and-dry-run.md` (makes the *mechanism* safe) and
  `.workspace/plans/2026-07-25-apply-harness-1.5.0-to-homographormer.md` (the incident that exposed both).

## Goal

A generated project must be able to answer, without reading framework source: **"can I edit this file, and what
happens to it on upgrade?"** Today it cannot, and that gap already destroyed work.

## Evidence — the project did nothing wrong

Homographormer hand-wrote `docs/how-to/multi-agent-collaboration.md`. The 1.5.0 upgrade would silently overwrite
it. Investigating *why the project made that mistake* shows *it wasn't a mistake*:

- The **shipped `AGENTS.md` says nothing** about file ownership, upgrade, or overwriting — verified by grep on
  `harness-core/AGENTS.md`. Same for the shipped `CLAUDE.md`. No shipped `docs/how-to/` guide covers it either.
- The **only** ownership signal a generated project has is its copied `harness-manifest.json`. Homographormer's
  copy (generated at 1.3.0) lists under `docs/how-to/`:
  `git-workflow.md`, `testing-guide.md` — **and nothing else.**
  So by its own best available information, `docs/how-to/multi-agent-collaboration.md` was an unclaimed path.
- The framework later claimed that path (1.4.0). **`harness-manifest.json` is not in `frameworkOwned`**, so
  `upgrade` never refreshes the project's copy — its ownership map silently goes stale, and staleness is exactly
  what creates the trap.

Root cause, precisely stated: **the framework asks projects to respect a boundary it never tells them about, using
a map it hands over once and then lets rot.**

## Design decisions

### D1 — Three tiers, not two

"Framework's vs yours" is too coarse; the manifest already encodes three distinct behaviors:

| Tier | Upgrade behavior | Examples |
|---|---|---|
| **Yours** — edit freely | Never touched | `AGENTS.md`, `CLAUDE.md`, `README.md`, all source, build config (`pyproject.toml`/`package.json`/`pom.xml`), linter config, `.workspace/STATUS.md`, `.workspace/worklog.md`, `.workspace/plans/*.md` (except `README.md`), `docs/adr/**`, the `*project-rules*` arch test |
| **Framework's** — do not edit | Overwritten if unmodified | `HARNESS-VERSION`, `.claude/commands/**`, `docs/how-to/**`, `scripts/validate.sh`/`validate.ps1`, `scripts/lint-format-hook.sh` (Python only), the `*dependencies*` arch test, `.editorconfig`, `.github/PULL_REQUEST_TEMPLATE.md`, `.workspace/plans/README.md`, `scripts/status-context.sh`, `.claude/settings.json`, `.github/workflows/ci.yml`, `.husky/pre-commit` |
| **Customizable, at a cost** | Your version kept; new template arrives as `<file>.new` for manual merge | any Framework's-tier file you deliberately modified — e.g. Homographormer's `lint-format-hook.sh` path guard and its arch-test exclusion |

**Gate O0 verification note (2026-07-26)**: the table above was checked directly against `harness-manifest.json`
and was **wrong** — it was missing `HARNESS-VERSION` and, critically, `scripts/lint-format-hook.sh` (Python-only,
`languageSpecific`) and `scripts/validate.ps1`. `scripts/lint-format-hook.sh` is exactly the file Homographormer
customized (its Windows path guard) — the original table's own worked example named the file without the table
listing its actual manifest path. Fixed above. This is itself the evidence for D4: a hand-maintained list drifts
immediately, even in the very document proposing to prevent drift — confirms **D4(b) guard**, not generate, and
confirms the shipped `file-ownership.md` (Phase O1) must not hand-list per-language paths either; it must be
generated from or mechanically checked against the manifest by `check-sync.mjs` (O2), not hand-copied like this
illustrative table was.

### D2 — The single highest-value rule: **don't create new files inside framework-owned directories**

The tier table alone would not have prevented the incident — the project didn't *edit* a framework file, it
*created* one in a framework-owned directory (`docs/how-to/`). The rule must say so explicitly, and must name where
project-specific content goes instead. The framework already established this pattern for arch tests
(`bootstrapLanguageSpecific` seeds a project-owned `*project-rules*` file precisely so custom checks don't get
squeezed into the framework-owned dependencies test) — D2 generalizes that existing idea to docs and commands.

Needs a decision at Gate O0: the project-owned location for custom guides. Candidates: `docs/guides/`,
`docs/project/`, `docs/investigations/` (the manifest comment already references an "investigations" pattern from a
real project). **Recommendation: `docs/guides/`** — obvious, parallel to `docs/how-to/`, no prior meaning.

### D3 — Ship it twice: always-on summary + full guide

Mirrors exactly how 1.4.0 shipped Handoff-and-Reporting (short always-loaded `AGENTS.md` section + detailed
`docs/how-to/` guide), for the same reason: the rule must be in context at edit time, the rationale doesn't need to be.

**Critical asymmetry to handle:** `AGENTS.md` is user-owned, so an `AGENTS.md` section reaches **new projects only**.
The guide is framework-owned, so it reaches **existing projects via upgrade**. Existing projects therefore get the
guide automatically but must add the `AGENTS.md` summary by hand — the same manual step as registering a new
command. The upgrade-tooling plan's Phase U3 (post-upgrade reminder) should mention it.

### D4 — Derive from the manifest, or guard against drift

A hand-maintained ownership table in two documents will drift from `harness-manifest.json` on the very next
manifest change — the identical failure mode this plan exists to fix. Two options:

- **(a) Generate** the tier tables from the manifest at setup/upgrade time.
- **(b) Guard**: extend `scripts/check-sync.mjs` so every manifest path must appear in the ownership doc and vice
  versa — direct precedent in the 1.4.0 manifest-registration guard, which catches exactly this class of omission.

**Recommendation: (b)** — cheaper, no templating machinery, and this repo already trusts check-sync for this job.

### D5 — Make `harness-manifest.json` framework-owned

Root cause fix for the staleness half of the problem. It is pure framework metadata; `upgrade` reads the
*framework's* copy, so the project's copy is purely informational — and being informational is exactly why it must
stay accurate. Adding it to `frameworkOwned` makes upgrade refresh it every time.

## Phases and Gates

### Phase O0 — Design gate — ✅ Closed 2026-07-26

- [x] Confirm the D1 three-tier split and that its lists match `harness-manifest.json` exactly today. **Checked
      directly against the manifest — it did not match** (missing `HARNESS-VERSION`, `scripts/lint-format-hook.sh`,
      `scripts/validate.ps1`). Fixed above; see the Gate O0 verification note.
- [x] Decide the project-owned docs location (D2). **Decided: `docs/guides/`**, as recommended.
- [x] Decide D4: generate vs. guard. **Decided: guard via `check-sync.mjs`**, as recommended — reinforced by the
      D1 table's own drift found during this gate.
- [x] Confirm D5 (manifest becomes `frameworkOwned`). **Decided: proceed now** — plan 1's U2 fix landed and is
      committed (`a5b022f`), so a project that edited its manifest copy now gets `.new`, not an overwrite.
- [x] Confirm version: this ships framework-owned files (guide + `AGENTS.md` section) → `HARNESS-VERSION` bump
      required. **Decided: minor → 1.6.0.**

### Phase O1 — The rule itself

- [ ] New `harness-core/docs/how-to/file-ownership.md`: the three-tier table, the D2 "don't create files in
      framework directories" rule with the recommended alternative location, how `.new` merges work, and how to
      check a path's tier (`harness-manifest.json`, refreshed each upgrade per D5).
- [ ] New short `## File Ownership` section in `harness-core/AGENTS.md` — tier summary in ~6 lines plus the D2
      rule, pointing at the guide. Placed near `Validation`/`Steering Loop` (where edit-time decisions happen).
- [ ] Register the guide in `harness-manifest.json` `frameworkOwned` (check-sync's existing guard enforces this).
- [ ] Root-repo copies of both, per this repo's dual-copy convention.

### Phase O2 — Stop the map from rotting — ✅ Done + verified 2026-07-26

- [x] Added `harness-manifest.json` to `frameworkOwned` (D5).
- [x] Extended `scripts/check-sync.mjs` (D4b, guard #4): parses `file-ownership.md`'s Framework tier from between
      `<!-- framework-tier:start/end -->` markers (backtick-quoted paths), builds the manifest's expected set from
      `frameworkOwned` + every `languageSpecific` array, and fails on any set difference in either direction.
- [x] **Verified by deliberately breaking it, both directions, not by assuming**:
      (a) added `harness-manifest.json` to the manifest but forgot it in the doc → guard correctly failed
      ("missing manifest path: harness-manifest.json"), caught a real omission during this same phase, fixed;
      (b) added a bogus manifest-only path (`some/bogus/new-path.md`) → guard correctly failed; reverted.
      (c) added a bogus doc-only path (`totally/extra/path.md`) → guard correctly failed ("lists a path absent
      from the manifest"); reverted. All three scenarios confirmed, doc and manifest now back to their intended
      clean state, `pnpm validate` passes end-to-end.

### Phase O3 — Make the rule reachable from where mistakes happen — ✅ Done 2026-07-26

- [x] `AGENTS.md` **Steering Loop** — confirmed every path it sends an agent to (linter config, `AGENTS.md`,
      `docs/adr/`, `HARNESS-CHANGELOG.md` in `harness-core`; `eslint.config.js`, `AGENTS.md`, `docs/adr/`,
      `HARNESS-CHANGELOG.md` at root) is **Yours** tier — none are in `frameworkOwned`/`languageSpecific`. Added a
      one-line pointer to **File Ownership** in both copies (worded differently per copy: harness-core's talks
      about a generated project's own tiers; root's talks about `harness-core/` paths needing manifest
      registration).
- [x] `.workspace/plans/README.md` (both copies): added a note that a plan proposing edits to a Framework's/
      Customizable-tier path (harness-core copy) or a manifest-registered `harness-core/` path (root copy) must say
      so explicitly in **Approach**.
- [x] **Found, out of scope, not fixed**: while reading both copies of `plans/README.md` for this phase, found they
      have drifted independently of file-ownership — root's copy is missing the entire "Owner" field and
      "Parallelization" block that 1.4.0 added to harness-core's copy. Not part of this plan's scope (file
      ownership, not general dual-copy sync); flagged in `STATUS.md` as a separate follow-up.

### Phase O4 — Verification — ✅ Passed 2026-07-26

- [x] **Fresh-generation matrix** (TS/Python/Java, via disposable `setup.ps1` runs, non-interactive piped stdin):
      `## File Ownership` section present in every `AGENTS.md` (count 1 each); `docs/how-to/file-ownership.md`
      present in every project; `harness-manifest.json` present in every project; **byte-identical** to the
      `harness-core` source in all six cases (guide × 3 languages, manifest × 3 languages); zero `{{...}}`
      leftovers in either file.
- [x] **Upgrade matrix on a real disposable project**: generated a project from the pre-file-ownership commit
      (`a5b022f`, plan 1's commit) via its own `setup.ps1`, then upgraded it with this session's current tooling
      (forcing the per-file loop past the "already up to date" short-circuit by temporarily staling the test
      project's own `HARNESS-VERSION`, same technique as the 1.4.0/M5 precedent). Confirmed: `file-ownership.md`
      delivered as `added`; `AGENTS.md` byte-**identical** before/after (SHA-256 hash matched, `## File Ownership`
      count stayed `0`) — the D3 asymmetry confirmed structurally, not assumed.
      **Real finding, not anticipated in the original design**: `harness-manifest.json` itself (D5's new
      `frameworkOwned` entry) landed in the **"newly managed"** bucket on this first post-1.6.0 upgrade, not a
      silent refresh — because no baseline existed for it before D5. This is correct per D1's own logic, but means
      Acceptance Criterion 3 ("refreshed by every upgrade") only fully holds *starting from the second* upgrade.
      Verified the self-healing: resolved the one `.new` (copied it over, matching what any project that never
      hand-edited its manifest would do), forced the loop again, and confirmed the *next* upgrade reports
      "no file content changes" for it — refreshes cleanly from then on. **Documented this one-time caveat in the
      FRAMEWORK-CHANGELOG.md and README.md entries (Phase O5) rather than treating it as a defect** — it is the
      correct application of the tooling plan's own D1 fix to a newly-tracked path, and is strictly safer than a
      silent overwrite would have been.
- [x] **The real test — reproduced under the new rules, live, twice**: two fresh `general-purpose` subagents, no
      shared context, each pointed at an independent copy of the freshly-generated TS project and given an
      undirected task ("write a short internal guide on X, save it wherever's appropriate — don't ask me where").
      Neither prompt mentioned `docs/guides/`, `file-ownership.md`, or this verification's purpose. **Both agents
      independently created their file at `docs/guides/<name>.md`**, both explicitly citing `AGENTS.md`'s File
      Ownership section as the reason. Verified the actual files exist on disk with real content (not just trusting
      the agents' self-report) and confirmed `docs/how-to/` in both project copies still contains only the original
      four framework files — no stray project file landed there.
- [x] `check-sync` (all four guards) and full `pnpm validate` (typecheck/lint/test) confirmed passing throughout.

### Phase O5 — Docs — ✅ Done 2026-07-26

- [x] `FRAMEWORK-CHANGELOG.md` `[1.6.0]` entry added (root cause, guide, `AGENTS.md` section, D5 + its one-time
      caveat, check-sync guard #4 + its 3-way break-test verification, Steering Loop/plans-README pointers, and
      the full O4 verification summary). `HARNESS-VERSION` bumped `1.5.0` → `1.6.0`.
- [x] Root `README.md`: added a "Which files are which?" paragraph in Framework Versioning & Upgrades, covering
      `file-ownership.md`, the `docs/guides/` rule, and the manifest's new self-refresh behavior including its
      one-time `.new` on first upgrade past 1.6.0.
- [x] Updated the Homographormer plan (`2026-07-25-apply-harness-1.5.0-to-homographormer.md`): retargeted from
      1.3.0→1.5.0 to **1.3.0→1.6.0** throughout (title, upgrade path, H0 pre-flight, branch name, acceptance
      criteria); added a new Phase H2 step to relocate the merged guide to `docs/guides/`, which is what actually
      closes the recurring-`.new` gap Acceptance Criterion 7 originally just warned about (now rewritten to say
      so, citing this plan's own live-agent test as the evidence the mechanism works).

## Acceptance Criteria

1. ✅ A generated project can determine any file's tier from always-loaded `AGENTS.md` plus one shipped guide,
   without reading framework source. *(O1 + O4 fresh-generation matrix.)*
2. ✅ The rule explicitly forbids creating new files inside framework-owned directories and names where to put
   them. *(O1 §2 of the guide + `AGENTS.md`'s File Ownership section.)*
3. ✅ `harness-manifest.json` in a generated project is refreshed by every upgrade — no more stale ownership maps.
   *(D5 + O2; holds from the second post-1.6.0 upgrade onward — see O4's real finding on the necessary one-time
   `.new` on the first upgrade, documented rather than treated as a defect.)*
4. ✅ `check-sync` fails if the manifest and the ownership doc disagree. *(O2, verified by deliberately breaking
   it three ways — a real omission plus two synthetic breaks, all caught, all fixed.)*
5. ✅ A fresh agent, given a guide-writing task, chooses the project-owned location (verified by live run, not
   review). *(O4: two independent fresh-agent runs, both chose `docs/guides/`, files confirmed to exist on disk.)*
6. ✅ Existing projects receive the guide via upgrade; the `AGENTS.md` summary is documented as a manual step.
   *(O4 upgrade matrix confirms delivery + `AGENTS.md` untouched; O5's README/changelog entries document the
   asymmetry as intentional, matching every other `AGENTS.md`-only addition's precedent.)*

**All six acceptance criteria met, 2026-07-26. Plan ready to close out** (pending user review / commit — nothing
pushed yet). **Known follow-up, not part of this plan's scope**: `.workspace/plans/README.md`'s root vs
`harness-core` copies have drifted independently (root is missing the "Owner" field and "Parallelization" block
from 1.4.0) — found during O3, flagged in `STATUS.md`, not fixed here.

## Risks

| Risk | Mitigation |
|---|---|
| Ownership doc drifts from the manifest — the exact failure being fixed | O2's check-sync guard, verified by deliberately breaking it. |
| `AGENTS.md` section never reaches existing projects (user-owned by design) | Accepted and documented (D3); the guide carries the full rule, and the tooling plan's U3 reminder surfaces it at upgrade time. |
| D5 overwrites a project that edited its manifest copy | Sequence after the tooling plan's U2 fix, which converts that into a `.new`. Recorded in O0. |
| Rule exists but agents ignore it | O4's live-agent test is the only real evidence; treat a failure there as the rule being badly worded, not the agent being wrong — same posture as the T3 escalation-note finding. |
| Three overlapping plans confuse sequencing | Explicit order: tooling (U2) → this (O2/D5) → Homographormer upgrade. |

## Out of scope

- Mechanically *preventing* writes to framework-owned paths (a hook or `check-agent-scope`) — this plan is the
  prose contract; enforcement teeth remain deferred, consistent with 1.5.0's n=2 posture.
- Restructuring what is framework-owned vs. user-owned. This plan documents the existing boundary; it does not
  move it (except D5, which is metadata, not content).
