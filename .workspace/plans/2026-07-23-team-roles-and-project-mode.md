# Team Roles & Project Mode — Harness Framework

- **Date**: 2026-07-23
- **Status**: Done (all phases T0-T4 complete and committed — `2044a28`, `9c1126c`, `8b98bbb`, `c63bfae` — plus a
  post-close-out audit fix, `3a3ae41`; not yet pushed, see `STATUS.md`)
- **Target release**: Harness 1.5.0 (provisional; confirm at Gate T0)
- **Depends on**: `.workspace/plans/2026-07-22-multi-agent-coordination.md` (1.4.0). This feature builds on that
  base: the always-on Handoff & Reporting rules, the file-ownership-matrix concept, and PR-as-integration-gate.
- **Prerequisite**: 1.4.0 (multi-agent + light multi-human) should land first, since roles reuse its primitives.
- **Rev**: 2026-07-23 — **Gate T0 closed**: `/team`; 7-role catalog + QA + Reviewer-as-rotating-hat; active role by
  explicit declaration + optional branch prefix; mode/roles/roster are user data (upgrade never overwrites);
  prose-only in 1.5.0, mechanical enforcement → 1.6.0. Ready to implement once 1.4.0 lands.
- **Rev**: 2026-07-25 — **Gate T1 closed**: `setup.ps1`/`setup.sh` Solo/Team prompt, `.harness-meta.json`
  `projectMode`/`roles`/`roster`, conditional `Team & Roles` AGENTS scaffold. Verified end-to-end against real
  generations. See Gate T1 below for detail.
- **Rev**: 2026-07-25 — **Gate T2 closed**: `/team` command (root + harness-core), Workflow Prompts/CLAUDE.md
  registration, `harness-manifest.json` registration. Verified via check-sync + a fresh Team-mode generation +
  a manual dry run of the command's own edit steps. See Gate T2 below for detail.
- **Rev**: 2026-07-25 — **Gate T3 closed**: guide documents the in-role convention (both copies); two real
  agent dry runs against a live Team-mode generation, the first of which found and led to fixing a real gap
  (escalation note location was unspecified). See Gate T3 below for detail.
- **Rev**: 2026-07-25 — **Gate T4 closed — plan Done**: `HARNESS-VERSION` → 1.5.0, changelog, README; Java added to
  the fresh-generation matrix (structural); real upgrade matrix via disposable worktrees (Team data survives,
  Solo genuinely unaffected). See Gate T4 below for detail.

## Goal

Let a project declare at setup whether it is a **Solo** or **Team** project, allow that choice to be **changed at
any time**, and in Team mode let each member's **role** be defined up front so an agent automatically constrains its
work to that role's ownership scope — escalating anything outside the role instead of silently doing it.

Example roles the user named: Planner (기획자), Architect (설계자), Backend (백엔드), Frontend (프론트엔드),
DBA (DBA), Infra (인프라). These are a starting point; §"Role taxonomy" recommends a refined default catalog.

## Design Principles

1. **Solo is zero-overhead (the complexity litmus).** Solo mode must add *nothing* a solo user notices beyond, at
   most, one extra menu item. The `Team & Roles` AGENTS section and all role prompts exist only in Team mode.
2. **Reuse existing axes, don't invent a new one.** Role ownership maps onto the clean-architecture layers the
   framework already enforces (`domain ← application ← infrastructure ← presentation`) and the file-ownership
   matrix from the 1.4.0 plan. A role's "owned scope" ≈ a layer/path set. This is why the mapping is natural rather
   than a bolted-on ACL system.
3. **Data-driven, not a hardcoded enum.** Ship a *default role catalog* users pick from and edit — roles are data
   (mirroring this repo's "data-driven language packs" direction), so a team can add "ML Engineer" or drop "DBA".
4. **Convention first, mechanism later.** v1 is prose-enforced: the agent reads the role scope from always-loaded
   `AGENTS.md` and self-constrains, escalating cross-role edits (the same escalation pattern a sub-agent uses toward
   a Coordinator). Mechanical enforcement (the deferred `check-agent-scope`) later reuses the *same* ownership map —
   one data structure, two consumers.
5. **One source of truth, mirrored for tooling.** Mode + roster + role→scope live in `AGENTS.md` (always loaded, so
   it actually governs agent behavior); a machine-readable mirror lives in `.harness-meta.json` for setup/upgrade/
   the future checker. AGENTS is authoritative for behavior; the JSON is derived.
6. **User-owned settings survive upgrade.** `projectMode`, `roles`, and `roster` are *user data*. Upgrade must never
   clobber them — same discipline as the existing baseline/`.new` system for AGENTS.

## Configuration Model

- **`.harness-meta.json`** (machine-readable, already exists for language + baselines):
  ```json
  {
    "projectMode": "solo",
    "roles": ["planner", "architect", "backend", "frontend", "data", "infra", "qa"],
    "roster": { "hansung": "architect", "alice": "backend" }
  }
  ```
  Solo projects omit `roles`/`roster` (or `projectMode: "solo"` with nothing else).
- **`AGENTS.md` `## Team & Roles` section** (Team mode only; absent in Solo): human-readable roster + the
  role→ownership map + the "how the agent stays in-role" convention. This is what the agent actually reads.

## Setup & Mid-Project Switching

- **`setup.ps1` / `setup.sh`**: add a "Solo or Team?" prompt (default **Solo**). Solo → write `projectMode: "solo"`
  and add nothing else. Team → write `projectMode: "team"`, scaffold an empty `## Team & Roles` section in
  `AGENTS.md`, and tell the user to run `/team` to configure roles.
- **`/team` command** (new): one command that both **initializes** and **reconfigures**, covering "set at start" and
  "change anytime":
  - Pick roles from the default catalog (or add custom ones).
  - Assign people to roles (roster).
  - Generate the role→ownership map into the `AGENTS.md` `Team & Roles` section and mirror to `.harness-meta.json`.
  - Switch Solo↔Team, add/remove roles, reassign — all via re-running `/team`.
- **Mid-project switch** is therefore just re-running `/team`; no separate migration. Upgrade must preserve the
  user's mode/roles/roster.

## Role Taxonomy (recommended default catalog)

Refines the user's examples and adds QA (the framework is test-obsessed — "PRs without tests" is prohibited).
Ownership deliberately follows the clean-architecture layers.

| Role | Responsibility | Owns (writes) | Must not touch / must delegate |
|---|---|---|---|
| **Planner / PM** (기획자) | Requirements, priorities, acceptance criteria | `.workspace/plans/` intent, README product sections | Source code |
| **Architect** (설계자) | Layer contracts, cross-cutting decisions | `docs/adr/`, `domain` interfaces, AGENTS `Key Invariants` | Other layers' impl details |
| **Backend** (백엔드) | Business logic, APIs | `application` + `infrastructure` layers | `presentation`, `domain` contracts (propose to Architect), CI |
| **Frontend** (프론트엔드) | UI, client behavior | `presentation` layer | `application`/`infrastructure` internals |
| **Data / DBA** | Schema, migrations, query performance | migrations, data-access in `infrastructure` | UI, business rules |
| **Infra / DevOps** (인프라) | CI/CD, deploy, hooks, env | `.github/workflows/`, `.husky/`, `.claude/settings.json`, build config | App/domain logic |
| **QA / Test** (added) | Test suites, coverage gates, arch tests | `tests/**`, coverage config, arch-test files | Production code (report a fix, don't silently edit) |

Plus a **Reviewer / Integrator** — best modeled as a **rotating hat, not a fixed person**: the multi-human analog of
the Coordinator who owns the PR-merge gate. Decide at T0 whether it's a role or a hat.

Note the elegance: because ownership tracks the architecture layers, the role map is mostly derivable from the
project's existing structure rather than hand-invented.

## How the Agent Stays In-Role

- **Active role** is set by: explicit declaration ("act as the backend dev"), or a `/team`-set session role,
  optionally reinforced by branch prefix (`be/`, `fe/`, `infra/`). Keep determination explicit and simple.
- The agent reads `Team & Roles` from always-loaded `AGENTS.md`, restricts edits to the active role's owned scope,
  and for anything cross-role produces a **request / PR note** instead of editing — the same escalation the 1.4.0
  sub-agent uses toward the Coordinator. This reuses the existing pattern; it is not a new enforcement engine.

## Release Staging (recommended)

- **1.5.0** — this feature: `setup.*` Solo/Team prompt, `.harness-meta.json` `projectMode`/`roles`/`roster`,
  `AGENTS.md` `Team & Roles` section, `/team` command, default role catalog, prose-enforced role scoping. The 1.4.0
  **deferred** `/start`·`/commit`·`/review`·`/done` coordination edits *could* ride here (this line originally said
  so) — **decided not to at T4**: 1.4.0's own un-defer trigger is n=2 (a second real project where the prose
  contract demonstrably fails), which hasn't happened. T3's dry run is evidence for prose, not against it — see
  `FRAMEWORK-CHANGELOG.md`'s 1.5.0 entry for the recorded decision. Still deferred to 1.6.0.
- **1.6.0** (optional) — `scripts/check-agent-scope.*` mechanical enforcement keyed to the role→ownership map
  (also enforces per-wave agent ownership from the 1.4.0 plan), plus the still-deferred `/start`·`/commit`·
  `/review`·`/done` coordination edits. Build teeth only after the convention proves out (n=2, per 1.4.0).

## Implementation Phases and Gates

### Phase T0 — Design gate (decisions before any code)
- [x] Confirm this is 1.5.0 and lands after 1.4.0. *(Confirmed.)*
- [x] Command name. *(**`/team`** — one command for mode toggle + roster + roles + mid-project change.)*
- [x] Default role catalog + Reviewer treatment. *(**7 roles**: Planner, Architect, Backend, Frontend, Data/DBA,
      Infra/DevOps, **QA/Test**. **Reviewer/Integrator is a rotating hat, not a fixed role** — whoever reviews the PR
      holds the merge gate. Catalog is user-editable data.)*
- [x] Where the **active role** lives. *(**Explicit declaration** as primary — the user says "act as backend", or
      `/team` sets a session role — **reinforced optionally by branch prefix** (`be/`, `fe/`, `infra/`). Simple and
      low-error; no reliance on STATUS which is per-branch, and no forced branch-naming convention.)*
- [x] How upgrade preserves `projectMode`/`roles`/`roster`. *(**Treated as user data — upgrade never overwrites**,
      same discipline as AGENTS/user-owned files. The fields live in `.harness-meta.json`, baseline-tracked so a
      customized value is preserved and only additive framework defaults are backfilled if missing. Never clobber a
      user's roster.)*
- [x] Confirm Solo mode stays zero-overhead (litmus). *(Confirmed — `Team & Roles` section and role prompts exist
      only in Team mode; Solo adds nothing but the single `/team` menu item.)*
- [x] Enforcement level for 1.5.0. *(**Prose-only in 1.5.0**; the agent reads the role map from always-loaded AGENTS
      and self-constrains + escalates. Mechanical `check-agent-scope` deferred to **1.6.0**, reusing the same map.)*

#### Gate T0
**Gate T0 is fully closed (2026-07-23).** All decisions recorded above. Implementation waits only on 1.4.0 landing;
no `setup.*`/manifest/command editing starts before then. T1 may begin once 1.4.0 is merged.

### Phase T1 — Config model & setup
- [x] Add `projectMode`/`roles`/`roster` to `.harness-meta.json` (documented, defaulting to solo). *(Both scripts:
      Solo omits `roles`/`roster` entirely, matching the plan's example; Team writes empty `[]`/`{}` for `/team` to
      populate later.)*
- [x] Add the Solo/Team prompt to `setup.ps1` and `setup.sh` (keep the scripts simple; defer role detail to `/team`).
      *(Numbered menu matching the existing language/comment-language prompt style, defaults to Solo.)*
- [x] Scaffold the empty `Team & Roles` AGENTS section only when Team is chosen. *(New `{{TEAM_ROLES_SECTION}}`
      token in `harness-core/AGENTS.md`, placed after "Handoff and Reporting" / before "Key Invariants"; Solo strips
      the token to nothing (verified byte-identical to the pre-change template), Team replaces it with a heading +
      one placeholder line pointing at `/team`.)*

#### Gate T1
**Gate T1 closed (2026-07-25).** Verified end-to-end with real generation, not just code review: ran both
`setup.ps1` and `setup.sh` (the latter under Git Bash, which this Windows dev box happens to have) for Solo and
Team, across TypeScript and Python. Confirmed: (1) `.harness-meta.json` has `projectMode` in both, `roles`/`roster`
present only for Team; (2) `AGENTS.md` diff between a Solo and Team generation is exactly the `## Team & Roles`
block, nothing else moves; (3) each generated project's `validate.sh` still passes end-to-end in both modes; (4)
`node scripts/check-sync.mjs` still passes (no command added yet, so no parity/manifest changes needed this phase).
No `HARNESS-VERSION` bump yet — per the plan's own staging, that's T4, once T2/T3 land too. Committed as `2044a28`
after a user checkpoint.

### Phase T2 — `/team` command
- [x] Add `harness-core/.claude/commands/team.md` + the root copy (check-sync command-set parity — see 1.4.0 finding A).
      *(Root copy adapted for this repo's own situation: no `Key Invariants` section to anchor placement against
      — uses `Framework Versioning` instead — and no `.harness-meta.json` yet, so its Notes explain the bootstrap
      case and the distinction from `/coordinate`, mirroring how `coordinate.md`'s root/harness-core copies diverge.)*
- [x] Add `/team` to both AGENTS Workflow Prompts tables and both CLAUDE.md command lists (1.4.0 finding B).
- [x] `/team` writes the role→ownership map into AGENTS + mirrors to `.harness-meta.json`; handles init, switch, edit.
      *(Encoded as the command's own step-by-step instructions — Steps 2-4 cover init/switch/edit, Step 5 writes
      AGENTS.md, Step 6 mirrors `.harness-meta.json`. `/team` is a prompt file, not a script, so "implementation"
      and "the command's content" are the same artifact — matching how `/coordinate` works.)*
- [x] Register `team.md` in `harness-manifest.json` `frameworkOwned`; the M-guard from 1.4.0 finding E covers it.
      *(Confirmed live: `node scripts/check-sync.mjs` passes, and a fresh Team-mode generation's `.harness-meta.json`
      baselines map includes `.claude/commands/team.md` automatically.)*

#### Gate T2
**Gate T2 closed (2026-07-25).** Since `/team` is itself a prompt (no script to unit-test), verification was: (1)
`check-sync.mjs` passes with the new command registered in both copies + the manifest; (2) a fresh Team-mode
TypeScript generation actually delivers `team.md` and picks it up in its baseline hash map, confirming the
manifest-registration guard's live effect, not just the static check; (3) a manual dry run — hand-applying exactly
the edits Steps 5-6 specify (a 2-role roster into the scaffolded `AGENTS.md` section, `roles`/`roster` into
`.harness-meta.json`) — produces valid JSON and a `validate.sh` pass, confirming the target shape is sound. No live
agent actually ran `/team` end-to-end (consistent with the `/coordinate` M4 precedent: content review + dry run,
not a spawned session) — that's the deferred check in T3's own acceptance item, not this phase's.

### Phase T3 — Role-scoped agent behavior
- [x] Document the "how the agent stays in-role" convention in the guide (extend the team section — §13 "Working as
      a team", the section that already explicitly deferred role assignment to this exact feature). *(Both
      `docs/how-to/multi-agent-collaboration.md` copies: harness-core's replaces the 1.4.0 deferral note with the
      concrete convention + a pointer to `/team`'s role catalog; root's is adapted the same way `coordinate.md`'s
      copies diverge — notes this repo has no `.harness-meta.json` yet and a by-area split as the natural default
      if ever adopted here.)*
- [x] Verify an agent under a declared role self-constrains and escalates cross-role edits (dry run). *(Real
      dry runs, not simulation — see Gate T3.)*

#### Gate T3
**Gate T3 closed (2026-07-25).** Ran two real dry runs with a fresh `general-purpose` agent (zero prior context,
so it could only act on what `AGENTS.md` actually says) against a real Team-mode TypeScript generation with its
`Team & Roles` section hand-populated (2-role roster: Architect/Backend). Declared the agent's active role as
Backend and gave it a task requiring edits to `domain` interfaces + `docs/adr/` — both explicitly Architect-owned
per the role table, with `domain` contracts additionally marked "must delegate" in Backend's row.

- **Run 1** (original wording — "produces a request/PR note instead of editing directly", no location specified):
  the agent correctly declined to edit either file and instead wrote an escalation note, correctly citing the
  ownership table and the escalation sentence — but had to *infer* where to put the note (it chose
  `.workspace/plans/`, reasoning from the guide's Coordinator-report pattern and AGENTS.md's own description of
  that directory). Its own honest self-report flagged this as a real gap: "nothing in AGENTS.md loudly says STOP at
  the point of editing — the constraint only surfaces if the agent actively cross-checks the file path against the
  ownership table."
- **Fix applied immediately** (same session, before closing this gate): made the escalation note's location
  concrete — `.workspace/plans/<date>-<short-topic>-request.md`, addressed to the owning role — in `/team`'s own
  Step 5 (both copies) and the guide's new paragraph (both copies), not just in the hand-simulated test file.
- **Run 2** (fresh agent, same scenario, updated wording, different field/task to rule out memorized output):
  confirmed the fix — the agent reported the note's location was "given verbatim," not inferred, and correctly
  escalated both cross-role edits to that exact path. It flagged two smaller residual ambiguities (whether "propose
  to Architect" permits a draft edit alongside the note vs. note-only; whether a `STATUS.md` update is mandated by
  the escalation rule itself or a separate general rule) — noted here rather than chased further, consistent with
  the plan's own risk table ("prose-first ... harden with `check-agent-scope` in 1.6.0 if it proves insufficient")
  and 1.5.0's explicit prose-only enforcement scope.

This is exactly the kind of finding real end-to-end testing is supposed to surface that content review alone can't
— worth recording as a concrete instance of the plan's own risk #5 ("Agent ignores role scope") almost happening,
caught and closed within the same phase rather than shipped.

### Phase T4 — Version, docs, matrices
- [x] Bump `HARNESS-VERSION` to 1.5.0; `FRAMEWORK-CHANGELOG.md` entry.
- [x] README: document Solo/Team, `/team`, and role scoping. *(Structure tree gains `team.md`; Quick Start's
      example prompts and command list gain the mode prompt and `/team`; new "Team Roles" section after "Work
      Journal", mirroring how the guide's §13 was extended.)*
- [x] Fresh-generation matrix: Solo project has **no** `Team & Roles` section and no behavior change (litmus);
      Team project gets roles and an agent respects scope. Repeat for TS/Python/Java. *(TS/Python done at Gate T1;
      Java done here — see Gate T4. Java's `validate.sh`/`mvn` still can't run in this environment, so Java
      verification is structural only: AGENTS.md diff, `.harness-meta.json`, package-dir generation — same
      pre-existing limitation as 1.4.0's M4.)*
- [x] Upgrade matrix: a Team project keeps its `projectMode`/`roles`/`roster` across upgrade; Solo unaffected.
      *(Real upgrades via disposable `git worktree` checkouts, not simulation — see Gate T4.)*

#### Gate T4
**Gate T4 closed (2026-07-25) — plan complete, all phases done.**

- **Version/docs**: `HARNESS-VERSION` → 1.5.0; `FRAMEWORK-CHANGELOG.md` entry added; README updated (structure
  tree, Quick Start prompts/commands, new "Team Roles" section). `node scripts/check-sync.mjs` and full
  `pnpm validate` both pass with all T1-T4 changes present.
- **Fresh-generation matrix — Java** (TS/Python already verified at Gate T1): generated Solo and Team Java projects
  via `setup.ps1` (correcting the prompt order for Java's extra base-package question — mode prompt precedes it).
  Confirmed: AGENTS.md diff between Solo/Team is exactly the `Team & Roles` section (same litmus as TS/Python);
  `.harness-meta.json` has `projectMode`/`roles`/`roster` correctly, `basePackage` unaffected; Java package
  directory structure (`domain`/`application`/`infrastructure`/`presentation`) generated normally under both modes.
  `mvn`/`javac` remain unavailable in this environment (`winget` blocked on an interactive ToS prompt, same as the
  1.4.0/M4 and the 1.4.0-caveat-closure sessions) — Java's `validate.sh` itself is still unverified end-to-end here.
- **Upgrade matrix**: used real disposable projects via `git worktree`, not simulation, mirroring the 1.4.0/M5
  technique. **Test A (Team-mode upgrade)**: generated a Team TypeScript project from the pre-T4 commit (`8b98bbb`,
  HARNESS-VERSION 1.4.0, already has T1-T3's Solo/Team code), hand-populated real `roles`/`roster` data (not just
  the empty scaffold), then ran the current tree's `upgrade.ps1` against it. Confirmed: `projectMode: "team"`,
  `roles: ["architect","backend"]`, `roster: {"hansung":"architect","alice":"backend"}` all survived byte-for-byte;
  `harnessVersion` correctly advanced to 1.5.0; `git diff --stat` inside the project showed only
  `.harness-meta.json` and `HARNESS-VERSION` changed — `AGENTS.md` and `team.md` untouched (nothing to update,
  since neither changed content between T3's commit and now); `validate.sh` still passes post-upgrade. **Test B
  (genuinely pre-1.5.0 Solo project)**: generated from `52820ab` (right after the 1.4.0 caveat closure, before any
  Solo/Team code existed at all — no mode prompt, no `team.md`), then upgraded to current. Confirmed: `team.md`
  delivered as a new file, the guide updated (both newly-registered/changed frameworkOwned files); `.harness-meta.json`
  gained **zero** `projectMode`/`roles`/`roster` keys (upgrade only ever mutates `baselines`/`harnessVersion`, never
  invents new top-level fields) — "Solo unaffected" confirmed structurally, not just asserted; `AGENTS.md` untouched
  (it isn't frameworkOwned, so upgrade never touches it regardless); `validate.sh` still passes post-upgrade.
- All temporary worktrees and generated directories removed after verification, outside every tracked repository.

**Plan status: Done.** All four implementation phases (T1-T4) and both design/implementation gates are closed. Nine
commits so far this session's 1.5.0 work: `2044a28` (T1), `9c1126c` (T2), `8b98bbb` (T3); T4 not yet committed at
the time this gate was written — see `STATUS.md` for the exact uncommitted diff.

### Post-close-out audit (2026-07-25)

Checked every in-scope item against the actual files after T4 closed, not just re-reading the plan — same practice
as 1.4.0's post-close-out audit. Two findings:

1. **Recorded-decision gap (docs only, no code).** 1.4.0 named an explicit condition for un-deferring `/start`·
   `/commit`·`/review`·`/done` coordination edits ("n=2 — a second real project where the prose contract
   demonstrably fails") and this plan's own Release Staging said they "can ride here too." 1.5.0 shipped without
   them, correctly (n=2 hasn't happened — T3's dry run found an under-specification, not a scope-violation
   failure), but nothing recorded *that this was a decision*. Fixed: `FRAMEWORK-CHANGELOG.md`'s 1.5.0 entry and
   this plan's Release Staging section both now state the deferral explicitly, per 1.4.0's own instruction to
   record it as "a decision, not an omission."
2. **Real gap found via a live `/team` run — acceptance criterion #2 had never actually been exercised.** Every
   prior verification of `/team` was content review or a *manual* dry run (hand-editing files to simulate what
   the command would produce). Ran an actual fresh agent against a real Solo-mode generated project, handed it
   `.claude/commands/team.md` and a switch-to-Team scenario, and let it follow the command for real:
   - **Run 1** (Solo→Team from scratch, exercising the "insert into AGENTS.md" path Gate T2/T3's dry runs never
     hit — they only ever filled an *existing* scaffold): structurally clean — correct insertion point, correct
     spacing, correct `.harness-meta.json` mutation. But the agent's own report flagged that `/team`'s
     `.harness-meta.json` instructions had no example JSON shape, so it inferred kebab-case role ids and a
     person→role roster direction — a different agent could plausibly have chosen differently (e.g. Title-Case
     ids, or role→people instead of person→role).
   - **Fix applied**: added an explicit "**Use this exact shape**" clause + worked JSON example to `/team`'s
     Step 6 (both copies).
   - **Run 2** (edit path: add a multi-word role + give a person two roles) initially *appeared* to still show
     the gap — but the test's target project had been generated before the fix, so its bundled `team.md` copy was
     stale; not a real failure, a test-setup mistake. Corrected by copying the fixed `team.md` in and re-running
     the identical scenario fresh (**Run 3**).
   - **Run 3** confirmed the fix for multi-word role ids (kebab-case derivation, zero inference — matched the
     worked example exactly) but surfaced one smaller residual ambiguity: the phrase "gets a `roles` array"
     could mean either a bare array as the roster value, or an array nested under a literal `roles` key. Tightened
     the wording once more (both copies) to state explicitly: "a bare JSON array of role-id strings directly as
     that person's value (not nested under any key)." Not re-verified with a fourth live run — the wording is now
     unambiguous on its face, and three real runs is enough evidence for a prose-only, opt-in 1.5.0 feature; this
     is the kind of judgment call the plan's own risk table anticipates ("harden ... if it proves insufficient"),
     not a promise to test every phrasing to exhaustion.
   - This is a second concrete instance (after T3's) of live testing finding what review alone didn't: acceptance
     criterion #2 ("switched anytime by re-running `/team`") is now actually exercised, not just designed for.

No further findings. Plan remains Done; the two fixes above are content changes to already-shipped 1.5.0 files
(`FRAMEWORK-CHANGELOG.md`, both `team.md` copies, this plan file) rather than new phases.

## Acceptance Criteria
1. Setup can choose Solo or Team; Solo adds zero visible overhead beyond one menu item.
2. The mode can be switched anytime by re-running `/team`, and upgrade preserves it.
3. In Team mode, roles are defined up front and an agent constrains its edits to the active role's owned scope,
   escalating cross-role changes instead of making them.
4. Role ownership maps onto the existing architecture layers; the role catalog is user-editable data.
5. All three language packs behave identically; the complexity litmus holds for Solo across all of them.

## Risks and Mitigations
| Risk | Mitigation |
|---|---|
| Team feature taxes solo users | Solo mode is literally empty; verify in the fresh-generation matrix (litmus). |
| Role scoping feels like bureaucracy | Prose-first, opt-in; roles reuse layer ownership rather than a new ACL. |
| Upgrade clobbers user roles | Treat `projectMode`/`roles`/`roster` as user data; baseline/never-overwrite. |
| Hardcoded roles don't fit a team | Ship a *default* catalog that `/team` lets users edit/extend. |
| Agent ignores role scope (prose-only) | Escalation convention in always-loaded AGENTS; harden with `check-agent-scope` in 1.6.0 if it proves insufficient. |
| Scope creep back into 1.4.0 | This is a separate plan/release; 1.4.0 stops at the light multi-human layer. |

## Notes for the Implementing Agent
- Do not start before 1.4.0 lands and Gate T0 decisions are recorded.
- This plan is design-only; every `setup.*`/manifest/command change is framework-owned and needs versioning +
  changelog discipline (see root `AGENTS.md` Framework Versioning).
- Reuse the 1.4.0 primitives (handoff rules, ownership matrix, PR gate, check-sync parity/manifest guard) — do not
  build a parallel system.
