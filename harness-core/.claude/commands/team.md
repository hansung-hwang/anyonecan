# /team — Team Roles & Project Mode

Set or change this project's Solo/Team mode, and in Team mode define roles and assign teammates. One command for
both "set up at the start" and "change anytime" — safe to re-run whenever the roster or roles need to change.

Solo is the default and adds nothing beyond this one menu item — the `## Team & Roles` AGENTS.md section and role
scoping only exist in Team mode.

## Steps

### 1. Read Current State

Read `.harness-meta.json`'s `projectMode`/`roles`/`roster` (if the file doesn't exist yet, treat the project as
Solo with no roles/roster) and `AGENTS.md`'s `## Team & Roles` section, if present.

### 2. Ask What to Do

- Currently Solo → offer to switch to Team.
- Currently Team → offer to switch to Solo, or edit the existing setup (add/remove a role, reassign a teammate,
  add/remove a teammate).

Confirm the choice before making changes.

### 3. Switching to Solo

Remove the `## Team & Roles` section from `AGENTS.md` entirely. Set `.harness-meta.json`'s `projectMode` to
`"solo"` and drop the `roles`/`roster` keys.

### 4. Switching to / Editing Team

- Present the default role catalog below. The user can keep it as-is, drop roles that don't apply, or add custom
  roles (a role is just a name + owned scope — this catalog is a starting point, not a fixed enum).
- Ask who's on the team and which role(s) each person holds (the roster). Roster entries are optional — a role can
  exist unassigned.
- Reviewer/Integrator is **not** a role to assign — it's a rotating hat, the multi-human analog of the Coordinator
  from `docs/how-to/multi-agent-collaboration.md`. Whoever reviews a given PR holds that PR's merge gate.

#### Default Role Catalog

Ownership follows the project's existing clean-architecture layers (`domain ← application ← infrastructure ←
presentation`) rather than an invented ACL system.

| Role | Responsibility | Owns (writes) | Must not touch / must delegate |
|---|---|---|---|
| **Planner / PM** | Requirements, priorities, acceptance criteria | `.workspace/plans/` intent, README product sections | Source code |
| **Architect** | Layer contracts, cross-cutting decisions | `docs/adr/`, `domain` interfaces, AGENTS `Key Invariants` | Other layers' impl details |
| **Backend** | Business logic, APIs | `application` + `infrastructure` layers | `presentation`, `domain` contracts (propose to Architect), CI |
| **Frontend** | UI, client behavior | `presentation` layer | `application`/`infrastructure` internals |
| **Data / DBA** | Schema, migrations, query performance | migrations, data-access in `infrastructure` | UI, business rules |
| **Infra / DevOps** | CI/CD, deploy, hooks, env | `.github/workflows/`, `.husky/`, `.claude/settings.json`, build config | App/domain logic |
| **QA / Test** | Test suites, coverage gates, arch tests | `tests/**`, coverage config, arch-test files | Production code (report a fix, don't silently edit) |

### 5. Write `AGENTS.md`

Replace the `## Team & Roles` section (insert it between `## Handoff and Reporting` and `## Key Invariants` if it
doesn't exist yet — the same spot `setup.*` scaffolds it) with:

1. The roster: person → role.
2. The role → ownership table, trimmed to the roles this project actually uses (plus any custom additions).
3. The in-role convention: the **active role** is set by explicit declaration ("act as the backend dev") or an
   optional branch-prefix hint (`be/`, `fe/`, `infra/`); an agent restricts edits to its active role's owned scope
   and, for anything cross-role, writes a request note to `.workspace/plans/<date>-<short-topic>-request.md`
   (create `.workspace/plans/` first if the project doesn't have it) addressed to the owning role, instead of
   editing directly — the same escalation pattern a sub-agent uses toward a Coordinator in the multi-agent guide.
   Naming the concrete file/location matters: a dry run during this feature's own development found that without
   it, an agent still escalates correctly but has to guess where the note goes.

### 6. Mirror to `.harness-meta.json`

Set `projectMode: "team"`, `roles` to the role ids actually in use, `roster` to the person→role map. If the file
doesn't exist yet, create it with just these fields — don't invent `harnessVersion`/`baselines` values, those
belong to `setup.*`/`upgrade.*`.

### 7. Report

Summarize what changed: mode, roles, roster, and confirm where in `AGENTS.md` the section now lives.

## Notes

- This command edits `AGENTS.md` and `.harness-meta.json` directly — it is not a script. Both files are user-owned;
  `upgrade.*` never touches them, so re-running `/team` is the only way this configuration changes.
- Non-Claude Code tools: copy this file's content and use it as a prompt.
