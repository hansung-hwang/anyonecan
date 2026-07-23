# Team Roles & Project Mode — Harness Framework

- **Date**: 2026-07-23
- **Status**: In Progress (design; no implementation started)
- **Target release**: Harness 1.5.0 (provisional; confirm at Gate T0)
- **Depends on**: `.workspace/plans/2026-07-22-multi-agent-coordination.md` (1.4.0). This feature builds on that
  base: the always-on Handoff & Reporting rules, the file-ownership-matrix concept, and PR-as-integration-gate.
- **Prerequisite**: 1.4.0 (multi-agent + light multi-human) should land first, since roles reuse its primitives.
- **Rev**: 2026-07-23 — **Gate T0 closed**: `/team`; 7-role catalog + QA + Reviewer-as-rotating-hat; active role by
  explicit declaration + optional branch prefix; mode/roles/roster are user data (upgrade never overwrites);
  prose-only in 1.5.0, mechanical enforcement → 1.6.0. Ready to implement once 1.4.0 lands.

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
  **deferred** `/start`·`/commit`·`/review`·`/done` coordination edits can ride here too, since role scoping reuses them.
- **1.6.0** (optional) — `scripts/check-agent-scope.*` mechanical enforcement keyed to the role→ownership map
  (also enforces per-wave agent ownership from the 1.4.0 plan). Build teeth only after the convention proves out.

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
- [ ] Add `projectMode`/`roles`/`roster` to `.harness-meta.json` (documented, defaulting to solo).
- [ ] Add the Solo/Team prompt to `setup.ps1` and `setup.sh` (keep the scripts simple; defer role detail to `/team`).
- [ ] Scaffold the empty `Team & Roles` AGENTS section only when Team is chosen.

### Phase T2 — `/team` command
- [ ] Add `harness-core/.claude/commands/team.md` + the root copy (check-sync command-set parity — see 1.4.0 finding A).
- [ ] Add `/team` to both AGENTS Workflow Prompts tables and both CLAUDE.md command lists (1.4.0 finding B).
- [ ] `/team` writes the role→ownership map into AGENTS + mirrors to `.harness-meta.json`; handles init, switch, edit.
- [ ] Register `team.md` in `harness-manifest.json` `frameworkOwned`; the M-guard from 1.4.0 finding E covers it.

### Phase T3 — Role-scoped agent behavior
- [ ] Document the "how the agent stays in-role" convention in the guide (extend the team section from the 1.4.0 §7).
- [ ] Verify an agent under a declared role self-constrains and escalates cross-role edits (dry run).

### Phase T4 — Version, docs, matrices
- [ ] Bump `HARNESS-VERSION` to 1.5.0; `FRAMEWORK-CHANGELOG.md` entry.
- [ ] README: document Solo/Team, `/team`, and role scoping.
- [ ] Fresh-generation matrix: Solo project has **no** `Team & Roles` section and no behavior change (litmus);
      Team project gets roles and an agent respects scope. Repeat for TS/Python/Java.
- [ ] Upgrade matrix: a Team project keeps its `projectMode`/`roles`/`roster` across upgrade; Solo unaffected.

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
