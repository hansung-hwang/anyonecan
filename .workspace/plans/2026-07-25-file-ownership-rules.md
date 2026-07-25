# File Ownership Rules — tell projects what they may edit

- **Date**: 2026-07-25
- **Status**: In Progress (design; no implementation started)
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
| **Framework's** — do not edit | Overwritten if unmodified | `.claude/commands/**`, `docs/how-to/**`, `scripts/validate.*`, the `*dependencies*` arch test, `.editorconfig`, `.github/PULL_REQUEST_TEMPLATE.md`, `.workspace/plans/README.md`, `scripts/status-context.sh`, `.claude/settings.json`, `.github/workflows/ci.yml`, `.husky/pre-commit` |
| **Customizable, at a cost** | Your version kept; new template arrives as `<file>.new` for manual merge | any Framework's-tier file you deliberately modified — e.g. Homographormer's `lint-format-hook.sh` path guard and its arch-test exclusion |

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

### Phase O0 — Design gate

- [ ] Confirm the D1 three-tier split and that its lists match `harness-manifest.json` exactly today.
- [ ] Decide the project-owned docs location (D2) — recommendation `docs/guides/`.
- [ ] Decide D4: generate vs. guard — recommendation guard via `check-sync.mjs`.
- [ ] Confirm D5 (manifest becomes `frameworkOwned`) and check it cannot break a project that edited its copy
      (with the tooling plan's U2 fix landed, such a project gets `.new`; without it, it gets overwritten —
      **so D5 should land after, or together with, U2**).
- [ ] Confirm version: this ships framework-owned files → `HARNESS-VERSION` bump required (minor → 1.6.0).

### Phase O1 — The rule itself

- [ ] New `harness-core/docs/how-to/file-ownership.md`: the three-tier table, the D2 "don't create files in
      framework directories" rule with the recommended alternative location, how `.new` merges work, and how to
      check a path's tier (`harness-manifest.json`, refreshed each upgrade per D5).
- [ ] New short `## File Ownership` section in `harness-core/AGENTS.md` — tier summary in ~6 lines plus the D2
      rule, pointing at the guide. Placed near `Validation`/`Steering Loop` (where edit-time decisions happen).
- [ ] Register the guide in `harness-manifest.json` `frameworkOwned` (check-sync's existing guard enforces this).
- [ ] Root-repo copies of both, per this repo's dual-copy convention.

### Phase O2 — Stop the map from rotting

- [ ] Add `harness-manifest.json` to `frameworkOwned` (D5).
- [ ] Extend `scripts/check-sync.mjs` (D4b): every `frameworkOwned`/`languageSpecific` path must appear in
      `file-ownership.md`'s Framework tier, and the doc must list no path absent from the manifest. Fail loudly on
      either mismatch.
- [ ] Verify the guard actually fails when a path is added to the manifest but not the doc (test it by breaking it
      on purpose, not by assuming).

### Phase O3 — Make the rule reachable from where mistakes happen

- [ ] `AGENTS.md` **Steering Loop** step 4 currently says "write a new ADR in `docs/adr/`" — confirm every path the
      Steering Loop sends an agent to is in the **Yours** tier (`docs/adr/**` is; `HARNESS-CHANGELOG.md` is), and
      add a pointer to the ownership rule so the loop can't send someone into framework territory.
- [ ] `.workspace/plans/README.md`: note that a plan proposing edits to framework-owned files must say so
      explicitly (this is where such a proposal would first appear).

### Phase O4 — Verification

- [ ] Fresh-generation matrix (TS/Python/Java): the `File Ownership` AGENTS section and the guide are present,
      tier tables match the manifest, no `{{...}}` leftovers.
- [ ] Upgrade matrix on a real disposable project: an existing project receives `file-ownership.md` and a
      **refreshed** `harness-manifest.json`; its `AGENTS.md` is untouched (user-owned, expected) — confirming the
      D3 asymmetry behaves as designed rather than as a surprise.
- [ ] **The real test — reproduce the original incident under the new rules**: give a fresh, zero-context agent a
      generated project and a task that naturally invites creating a project-specific guide, and check whether it
      puts the file in `docs/guides/` rather than `docs/how-to/`. Two runs, per the T3 precedent. This is the only
      check that proves the rule actually changes behavior rather than merely existing.
- [ ] Confirm `check-sync` + full `validate` pass.

### Phase O5 — Docs

- [ ] `FRAMEWORK-CHANGELOG.md` 1.6.0 entry; bump `HARNESS-VERSION`.
- [ ] Root `README.md`: mention the ownership contract in the Framework Versioning & Upgrades section.
- [ ] Update the Homographormer plan: its Phase H3/H5 manual steps get simpler once the project has the rule, and
      its "port the guide" step should relocate the project's custom guide to `docs/guides/` so the path conflict
      never recurs.

## Acceptance Criteria

1. A generated project can determine any file's tier from always-loaded `AGENTS.md` plus one shipped guide, without
   reading framework source.
2. The rule explicitly forbids creating new files inside framework-owned directories and names where to put them.
3. `harness-manifest.json` in a generated project is refreshed by every upgrade — no more stale ownership maps.
4. `check-sync` fails if the manifest and the ownership doc disagree.
5. A fresh agent, given a guide-writing task, chooses the project-owned location (verified by live run, not review).
6. Existing projects receive the guide via upgrade; the `AGENTS.md` summary is documented as a manual step.

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
