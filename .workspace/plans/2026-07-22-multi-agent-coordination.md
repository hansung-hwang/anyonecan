# Multi-Agent Coordination — Harness Framework 1.4.0

- **Date**: 2026-07-22
- **Status**: In Progress
- **Source case study**: `Homographormer/docs/how-to/multi-agent-collaboration.md`
- **Target release**: Harness 1.4.0 (provisional; confirm at Gate M0)
- **Rev**: 2026-07-23 — split actor-count-independent handoff/reporting rules into always-loaded AGENTS;
  keep Coordinator/worktree/wave mechanics in the conditional multi-actor guide.
- **Rev**: 2026-07-23 (audit) — reconciled the plan against this repo's actual enforcement (check-sync.mjs,
  harness-manifest.json, the three upgrade scripts). Six supplements folded in; see `Design Audit` below and
  the resolved Gate M0 decisions.
- **Rev**: 2026-07-23 (scope cut) — narrowed 1.4.0 to its low-complexity, broadly-valuable core after a
  complexity-budget review (see `Scope Decision` below). The `/start`, `/commit`, `/review`, `/done` prompt edits
  and the `check-agent-scope` scope checker are **deferred to 1.5.0** pending a second real multi-agent project.

## Scope Decision (2026-07-23) — complexity budget

The full proposal bundled two things of very different cost/value. This revision ships the cheap, broadly-useful
half and defers the expensive, speculative half.

**Rationale.** Classify each artifact by *who pays its complexity*:

| Artifact | Who loads/runs it | Verdict |
|---|---|---|
| AGENTS `Handoff and Reporting` (4–5 bullets) | everyone, every session | **Ship** — short, and genuinely single-agent-useful (3 of 5 incidents happen solo). |
| `docs/how-to/multi-agent-collaboration.md` guide | opt-in readers only | **Ship** — zero cost to solo users; preserves hard-won lessons. |
| `/coordinate` command + `/plan` optional block | shown in menu; acts only when invoked | **Ship** — opt-in; a solo user can ignore it entirely. |
| `/start`, `/commit`, `/review`, `/done` edits | **everyone, every time they run those core commands** | **Defer to 1.5.0** — conditional coordination branches tax 100% of users for a ~5% workflow, and add permanent maintenance drag to the most-used prompts. |
| `scripts/check-agent-scope.*` | CI/enforcement | **Defer to 1.5.0** — the prose contract has no proven second use yet; build teeth after evidence. |

**Litmus test applied** (reused for future features): *can a solo user ignore this feature and never notice it?*
The four core-prompt edits fail that test; everything shipped in 1.4.0 passes it.

**What we don't lose by deferring.** The one genuinely general rule inside the deferred prompt edits — review
against a fixed SHA, re-review if Head moves — is already captured by the always-on `Handoff and Reporting`
bullets, so no single-agent safety is lost by leaving `/review` untouched. `/done`'s "clean handoff" behavior is
likewise already governed by the AGENTS rule, not by a `/done` edit.

**1.5.0 trigger.** Revisit the deferred prompt edits + scope checker when a *second* real project runs a
multi-agent session and the prose-only contract demonstrably fails to prevent a scope/handoff incident (n=2).

## Design Audit (2026-07-23)

Audited the plan against the repository's real enforcement mechanics, not just for internal consistency. Six gaps
between the plan and how this repo actually behaves; each is now reflected in the relevant section below.

| # | Finding | Where fixed |
|---|---|---|
| A | `check-sync.mjs` runs first in `validate.sh` and enforces **command-file-set parity** between root and `harness-core` `.claude/commands/`. A `coordinate.md` in only `harness-core` hard-fails `pnpm validate`. The root copy is **mandatory, not conditional**. | File list, M2 |
| B | A 10th command means editing four enumeration points check-sync does **not** guard: the Workflow Prompts table in both `AGENTS.md` copies and the command-list bullet in both `CLAUDE.md` copies. (Not a single-rule-source violation — the CLAUDE.md list is a pointer, not a rule.) | File list, M2 |
| C | The "advisory on upgrade" option is not free: `upgrade.ps1`/`upgrade.sh`/`upgrade.py` all exist and none emit advisories today. Choosing it adds parallel work across three scripts. 1.4.0 takes the cheaper route instead. | §1, M0 |
| D | "Clean handoff" conflicts with the "commit only when the user asks" default. The source doc already answers it (WIP commit). Resolved into a confirmed rule rather than an open M0 question. | §1, M0 |
| E | Nothing fails if a new framework-owned file is left out of `harness-manifest.json` — check-sync only checks command parity + stale patterns. Add a cheap manifest-registration guard to check-sync now. | M2, M3 |
| F | The source guide and handoff section are Korean (that project's comment language); the template default is English. The generalized guide + section ship **newly authored in English**, not translated-in-place. | §1, §2 |

## Goal

Add an opt-in, tool-neutral multi-agent coordination layer to anyonecan so generated projects can divide
independent work across agents without overlapping file ownership, reviewing moving inputs, committing unread
changes, duplicating shared journal entries, or regenerating derived artifacts from partial state.

The default remains a single agent. Multi-agent coordination is used only when at least two tasks are genuinely
independent and the expected parallelism benefit exceeds delegation, review, and integration cost.

## Evidence and Problem Statement

The design comes from a real generated-project session in `Homographormer`. The code itself survived review,
but shared state and reporting failed in repeatable ways:

1. A reviewed file changed before commit, so unread code could have entered the reviewed commit.
2. Two sessions of uncommitted work accumulated in one working tree, obscuring provenance.
3. Shared journal files drifted: duplicate `worklog.md` rows and stale `STATUS.md` sections appeared.
4. A count-based completion report claimed nine items were reflected although only review notes had changed.
5. A test claim reproduced differently because the validation environment could not write pytest temp files.
6. A generated Kaggle bundle could have represented a partial source state if multiple agents regenerated it.

These are framework-level coordination failures, not HomoGraphormer-specific model failures. The harness should
make them difficult by standardizing immutable review inputs, worktree isolation, single-writer ownership,
Coordinator-only integration/close-out, and reproducible validation reports.

## Scope

### In scope for 1.4.0 (slim core)

- A compact, actor-count-independent `Handoff and Reporting` section in the generated-project `AGENTS.md`
  template: clean handoff state, immutable SHA review, requirement → location reporting, and exact
  command/environment validation evidence.
- A framework-owned, language-agnostic detailed guide copied/upgraded into generated projects.
- A new shared `/coordinate` workflow prompt usable by non-Claude tools as a copied prompt.
- Optional plan-template support (`Parallelization` block) for Base SHA, waves, file ownership, integration order —
  and a one-line pointer to it from `/plan` (the only core-command touch in 1.4.0).
- Manifest registration, framework version bump, changelog, README documentation.
- The check-sync command-set parity fixes (root `coordinate.md`) and the manifest-registration guard.
- **Multi-human collaboration (light)**: a "Working as a team" section in the guide, plus two optional template
  fields (plan `Owner`, worklog author) and one AGENTS merge-hygiene bullet. Doc + opt-in fields only — passes the
  complexity litmus (a solo user never sees it). See §7.
- Setup and upgrade verification across TypeScript, Python, and Java generated projects.

### Deferred to 1.5.0 (see `Scope Decision`)

- Conditional coordination branches in `/start`, `/commit`, `/review`, and `/done`. Their one general rule
  (fixed-SHA review) is already covered by the AGENTS `Handoff and Reporting` section.
- `scripts/check-agent-scope.*` mechanical scope enforcement.
- Trigger to un-defer: a second real project's multi-agent session where the prose contract fails (n=2).

### Out of scope entirely

- A long-running orchestration daemon or real-time distributed lock.
- Automatic creation or deletion of worktrees by framework scripts.
- Tool-specific APIs in `AGENTS.md`.
- Mandatory multi-agent use for ordinary tasks.
- Project-specific roles such as Cache Agent, Kaggle Execution Agent, or baseline protocol details.
- Automatic branch merging or conflict resolution.
- Treating `.workspace/coordination/*.md` as a real-time lock across worktrees.

## Design Principles

1. **Always-on handoff contract**: clean handoff state, SHA-fixed review, requirement → location mapping, and
   command/environment evidence apply even to one actor working across turns or sessions.
2. **Conditional multi-actor procedure**: Coordinator/worktree/wave/ownership rules activate only when multiple
   sessions or sub-agents touch the same repository.
3. **One Coordinator**: exactly one session owns assignment, integration, full verification, shared docs, and
   `/done`.
4. **One writer per file per wave**: ownership may be delegated, but concurrent writers are prohibited.
5. **Isolated workspaces**: each implementation agent uses its own branch/worktree when the tool supports it.
6. **Explicit task contract**: every assignment includes Base SHA, allowed/prohibited files, dependencies,
   validation command/environment, completion criteria, and report format.
7. **Coordinator-only shared state**: sub-agents do not update `.workspace/**`, generated artifacts, or run
   `/done` unless explicitly promoted to Coordinator.
8. **Integrate before deriving**: bundles, manifests, lockfiles, generated docs, and result tables are regenerated
   once after source changes are integrated.
9. **Sequential dependencies stay sequential**: do not parallelize a task that consumes another task's output.
10. **Tool-neutral core, tool-specific appendix**: AGENTS rules work everywhere; Claude/Codex/Cursor/Windsurf
    mechanics live only in the guide.

## Proposed Artifacts

### 1. `harness-core/AGENTS.md`

Add a short `Handoff and Reporting` section after Work Journal. These rules are deliberately not under a
multi-agent heading: they apply to one actor across turns/sessions as well as to multiple sessions or sub-agents.
Keep the section to four or five bullets so it is cheap to load every session:

```markdown
## Handoff and Reporting

- Before handing work to another actor or session, leave a clean working tree and identify the handoff SHA.
- Review fixed Base/Head SHAs; if Head changes, repeat the review.
- Report completion as `requirement → file/symbol/test location`, not as counts alone.
- Validation reports include the exact command, working directory, execution environment, and result.
- When changing a durable document, inspect and update every section that references the changed fact.
```

The section ships **newly authored in English** (the template default). The source's Korean prose and the
Homographormer incident specifics are evidence, not text to translate in place (finding F).

**Clean-handoff rule — resolved (finding D).** This is no longer an open question. The source doc already answers
it ("leave a WIP commit if unfinished"), but that collides with the "commit/push only when the user asks" default
posture. The confirmed rule therefore has two branches, and the "clean working tree" bullet is worded to carry both:

- When the project grants the agent commit authority: leave a clean tree via a WIP commit and identify the handoff SHA.
- When commit authority is absent: hand off an **explicitly declared, owned uncommitted diff** (list the files and why).
- Never a silent dirty-tree handoff in either case.

**Reaching existing projects — resolved (finding C).** `AGENTS.md` is intentionally user-owned after generation, so
the upgrade system must not begin overwriting project AGENTS files. Of the options considered, an upgrade-time
advisory was rejected for 1.4.0: `upgrade.ps1`, `upgrade.sh`, and `upgrade.py` all exist and none emit advisories
today, so that route means parallel implementation across three scripts for marginal benefit. Adopted for 1.4.0:

- New projects receive the section; existing projects discover it through the upgraded guide and the changelog entry.
- Do not duplicate the rule into `CLAUDE.md` or tool-specific pointer files. (Adding `/coordinate` to CLAUDE.md's
  command-list pointer is separate and allowed — see finding B; that's navigation, not the rule.)
- Revisit an upgrade advisory only if a later release already has a reason to touch all three upgrade scripts.

### 2. `harness-core/docs/how-to/multi-agent-collaboration.md`

Create a generalized guide containing:

- An opening applicability notice: multi-actor procedures activate only when multiple sessions or sub-agents
  touch the same repository; actor-count-independent rules live in `AGENTS.md`.
- When to use and not use multiple agents.
- Coordinator, Implementation, Test, Research/Review, and Execution roles.
- Branch/worktree topology without repository-specific paths.
- Base SHA and per-wave single-writer rules.
- Assignment and completion-report templates.
- File-ownership matrix template.
- Wave 0 prerequisite commit pattern.
- Coordinator integration and rework loops.
- Generated/shared artifact policy.
- A warning that coordination Markdown is a record, not a cross-worktree lock.
- A **"Working as a team (multiple people)"** section (§7): Coordinator→PR-reviewer mapping, PR-as-handoff, and a
  pointer to the team-roles plan for role-scoped work.
- Tool appendices for Claude Code, Codex, and manual branch/worktree workflows.
- Generalized incident patterns without HomoGraphormer file names, model details, or commit SHAs.

The guide's basic-principles section must not duplicate the always-on handoff/reporting bullets. Keep only the
multi-actor rules and a pointer to `AGENTS.md`; retain the incident section as evidence for why the global rules
exist.

Do not copy the entire project guide verbatim. Remove SHE/Kaggle/baseline roles, project paths, dated incident
details, and claims tied to one tool. Preserve only general rules and reusable templates. Author it **in English**
(the template default); the Korean source is evidence, not a translation base (finding F).

### 3. `harness-core/.claude/commands/coordinate.md`

Add a shared prompt that produces a coordination plan but does not automatically mutate branches or spawn
agents. Required steps:

1. Read AGENTS, STATUS, the active plan, other in-progress plans, and Git status.
2. Decide whether multi-agent execution is justified; explicitly choose single-agent when it is not.
3. Identify dependency edges and define Wave 0 prerequisites.
4. Fix a Base SHA after prerequisites are committed.
5. Assign exactly one writer per file per wave.
6. Generate agent contracts with allowed/prohibited files and validation environments.
7. Mark shared/generated files as Coordinator-owned.
8. Define integration order and the full validation command.
9. State that only the Coordinator updates shared journals and runs `/done`.

Expected output:

```markdown
## Coordination Plan

- Coordinator:
- Base SHA:
- Shared/generated files:
- Full validation command and environment:

### Wave 0
- Coordinator prerequisites

### Wave 1
| Agent | Goal | Allowed files | Prohibited files | Depends on |

### Integration order
1. ...

### Completion authority
Only the Coordinator updates shared state and runs `/done`.
```

Non-Claude tools use the command file as a copied prompt, matching existing framework policy.

### 4. Existing workflow prompts

**1.4.0 touches exactly one core command: `/plan`** (a one-line pointer to the optional block). The
`/start`, `/commit`, `/review`, `/done` edits are deferred to 1.5.0 — see the subsection at the end of §4 and the
`Scope Decision`. This keeps 100%-of-users prompts free of dormant coordination logic.

#### `/plan` (1.4.0)

- Add an optional `Parallelization` section for multi-agent work:
  Coordinator, Base SHA, Wave 0, assignments, file ownership, dependencies, integration order, and shared/generated
  files.
- Do not add this section to simple single-agent plans.
- Implementation is minimal: the block lives in the `.workspace/plans/README.md` template (below); `/plan.md` only
  gains a one-line "for multi-agent work, fill the optional Parallelization block" pointer, not conditional logic.

**Plan-template block — confirmed at Gate M0 (2026-07-23).** The last open M0 item is resolved: the block is added.
M2 inserts the following optional block into `.workspace/plans/README.md`'s template (and it is the shape `/plan`
and `/coordinate` write into). It is optional — single-agent plans omit it entirely:

````markdown
## Parallelization (optional — only for multi-agent work)

Fill this in only when at least two tasks are genuinely independent and the parallelism benefit exceeds
delegation/review/integration cost. Otherwise delete this section — single-agent is the default.

- **Coordinator**: the one session that integrates, runs full validation, updates shared docs, and runs `/done`.
- **Base SHA**: the fixed commit every agent branch forks from (set after Wave 0 prerequisites are committed).
- **Shared / generated files** (Coordinator-owned; no agent writes these): e.g. `.workspace/**`, lockfiles,
  generated bundles/manifests, result tables.
- **Full validation command + environment**: the exact command, working directory, and any writable-temp/env flags.

### Wave 0 — prerequisites (Coordinator, committed before assignments)
- shared fixtures / scaffolding / interfaces that agents build on

### Wave 1 — assignments (one writer per file per wave)
| Agent | Goal (one sentence) | Allowed files | Prohibited files | Depends on |
|---|---|---|---|---|
|  |  |  | `.workspace/**`, shared/generated, other agents' files |  |

### Integration order
1. ...

### Completion authority
Only the Coordinator updates shared journals, regenerates derived artifacts, and runs `/done`.
Sub-agents report `requirement → file/symbol/test location`, their commit SHA, and validation command+result.
````

The block mirrors the `/coordinate` output (§3) and the source task/report templates, so `/plan` (human-authored)
and `/coordinate` (generated) converge on one shape. Editing `.workspace/plans/README.md` is a framework-owned
change — it is batched into M2 with the guide/command/prompt edits and covered by the single M3 version bump +
changelog entry, not shipped standalone.

#### Deferred to 1.5.0 — `/start`, `/commit`, `/review`, `/done`

These edits are **not implemented in 1.4.0** (complexity budget — they modify commands every user runs, for a
workflow ~5% use). Recorded here as the 1.5.0 design so the deferral is a decision, not an omission. Un-defer at n=2.

- **`/start`**: detect a coordination section in the active plan; report Coordinator, Base SHA, and branch/worktree
  role when present. Do not enumerate sibling worktrees (environment-dependent).
- **`/commit`**: for an assigned agent, compare `git diff --name-only <base>..<head>` against the declared
  allowlist; confirm Head descends from Base, tree is clean, and prohibited/shared/generated files are untouched.
  *(The general half — "always report exact command + environment + result" — is already an AGENTS Handoff rule.)*
- **`/review`**: require Base/Head SHAs and expected file scope for coordinated reviews; record reviewed Head SHA and
  repeat if it moves. *(The general fixed-SHA-review rule is already in AGENTS Handoff — so single-agent review loses
  nothing by leaving `/review` untouched in 1.4.0.)*
- **`/done`**: Coordinator-only close-out; verify all expected Head SHAs integrated, artifacts regenerated, full
  validation passed; append exactly one coordinator session row. *(The "clean handoff" behavior is already the AGENTS
  rule, so `/done` needs no 1.4.0 edit to enforce it.)*

### 5. Optional coordination record

For 1.4.0, prefer adding the coordination section to the active plan rather than introducing another state file.
If a future `.workspace/coordination/` record is added, document that it is not a live lock and designate it
Coordinator-only. Worktrees have different file snapshots, so a Markdown file cannot provide real-time mutual
exclusion.

### 6. Future mechanical enforcement (deferred to 1.5.0)

After the prompt-based contract is used in a *second* real project (n=2), consider a language-agnostic scope checker:

```text
scripts/check-agent-scope.*
```

Potential checks: Head descends from Base, changed files match allowlist, prohibited files are untouched, and the
working tree is clean. Do not build an orchestration platform in the first release.

### 7. Multi-human collaboration (multiple people, one repo)

Same coordination model as multi-agent — **only the integration gate differs: a PR review replaces the
Coordinator's cherry-pick.** Most of this already ships: the "Multiple team members" notes in `AGENTS.md` and
`plans/README.md` (per-branch STATUS, append-only worklog, plan naming) and the "PRs without tests" rule already
assume PR-based integration. 1.4.0 adds only opt-in docs + two optional template fields, so a solo user sees none of it.

| Concern | Multi-agent (1 human, N agents) | Multi-human (N humans) |
|---|---|---|
| Isolation | worktree/branch per agent | branch per person/feature |
| **Integration gate** | Coordinator cherry-picks/merges | **PR review + merge** |
| Shared journal | Coordinator-only writes `.workspace` | per-branch STATUS; append-only worklog (keep both on conflict) |
| Handoff/report | clean tree + SHA, requirement→location | **the same rules, expressed as a good PR description** |
| No lock | coordination md is a record | `.workspace` is not a lock; coordinate async via PRs |

Additions (all opt-in / doc-only):

- **Guide section "Working as a team (multiple people)"** inside the same `multi-agent-collaboration.md`: map
  Coordinator→PR reviewer; state that the always-on Handoff & Reporting rules apply to a PR (clean branch,
  requirement→location in the PR body, validation command+environment as PR evidence); reiterate `.workspace` is not
  a cross-branch lock.
- **`plans/README.md` template**: an optional `Owner` field (which person owns this task). Plans are already
  one-per-task, so they are the natural durable ownership record — more stable across branches than STATUS.
- **`worklog.md` row format**: an optional author column (`| date | author | summary | files | plan |`). Solo
  projects omit it.
- **AGENTS.md "Multiple team members" note**: one added bullet — rule additions go **append-only to the bottom of
  Key Invariants (no reformatting)** so concurrent edits merge trivially.

**Forward pointer.** Richer team **roles** (a Solo/Team project mode chosen at setup and changeable mid-project,
per-role ownership scoping, and a `/team` command so an agent works only within its assigned role) are a separate,
larger initiative that builds on this multi-human base. Designed in
`.workspace/plans/2026-07-23-team-roles-and-project-mode.md` (provisional 1.5.0). 1.4.0 deliberately stops at the
light layer above to hold the complexity budget.

## Framework Ownership and Versioning

Proposed framework-owned additions/changes:

```text
harness-core/docs/how-to/multi-agent-collaboration.md
harness-core/.claude/commands/coordinate.md
harness-core/.claude/commands/plan.md              # one-line pointer to the optional Parallelization block only
harness-core/.workspace/plans/README.md            # confirmed at Gate M0 — adds optional Parallelization block (§4)
harness-core/harness-manifest.json
harness-core/HARNESS-VERSION
FRAMEWORK-CHANGELOG.md
README.md

# DEFERRED to 1.5.0 (NOT edited in 1.4.0 — see Scope Decision):
#   harness-core/.claude/commands/{start,commit,review,done}.md
#   scripts/check-agent-scope.*

# Required by check-sync command-set parity (finding A) — NOT optional:
.claude/commands/coordinate.md                    # root copy; TS/pnpm-flavored wording is fine, harness-core stays language-agnostic

# New-command enumeration touch-points check-sync does NOT guard (finding B):
harness-core/AGENTS.md                            # add /coordinate row to the Workflow Prompts table
AGENTS.md                                         # root copy: same table row
harness-core/CLAUDE.md                            # add /coordinate to the command-list pointer bullet
CLAUDE.md                                         # root copy: same pointer bullet

# Guard so a forgotten manifest entry fails loudly (finding E):
scripts/check-sync.mjs                            # assert every harness-core framework-owned command/guide is registered in harness-manifest.json
```

`harness-core/AGENTS.md` and both `CLAUDE.md` files are edited here only to add the new command to their pointer
lists — not to distribute the handoff *rule* (that stays out of CLAUDE.md, finding B / §1). The root `AGENTS.md`
and `CLAUDE.md` are the framework-development copies, not shipped templates, but check-sync scans them, so they
must stay consistent.

Important ownership nuance:

- `harness-core/AGENTS.md` is copied to new projects, but project AGENTS files remain user-owned and are not in
  `frameworkOwned`. Never change that safety property merely to distribute this feature.
- The guide and command should be registered under `frameworkOwned` so existing projects receive them through
  upgrade with baseline/customization protection.
- Command changes are framework-owned and may produce `.new` files when a project customized them; verify this.
- A new command plus workflow behavior is a minor release. Provisional target: `1.3.0 → 1.4.0`.
- Add a detailed `FRAMEWORK-CHANGELOG.md` entry explaining opt-in behavior and upgrade ownership.

## Implementation Phases and Gates

### Phase M0 — Design audit

- [x] Read the HomoGraphormer case-study guide and this plan completely. *(2026-07-23 audit)*
- [x] Verify every proposed path against `harness-core/harness-manifest.json`. *(Done — surfaced findings A, B, E:
      command-set parity, four enumeration touch-points, and the missing manifest-registration guard.)*
- [x] Confirm `/coordinate` is the command name and multi-agent use remains opt-in. *(Confirmed; name is free — no
      existing command collides.)*
- [x] Confirm the always-on rules live under `Handoff and Reporting`, not `Multi-Agent Work`. *(Confirmed; matches
      the source's placement right after Work Journal, before Key Invariants.)*
- [x] Decide how “clean handoff” behaves when the agent lacks commit authority. *(Resolved, finding D — two-branch
      rule: WIP-commit clean tree when commit authority exists, else an explicitly declared owned uncommitted diff;
      never a silent dirty handoff. See §1.)*
- [x] Decide how existing projects are advised about the user-owned AGENTS addition without overwriting it.
      *(Resolved, finding C — no upgrade advisory in 1.4.0 (would touch all three upgrade scripts); new projects get
      the section, existing projects learn via the upgraded guide + changelog. See §1.)*
- [x] Confirm the release classification (`1.4.0` minor). *(Confirmed — new command + new checks/behavior, no
      breaking manifest change; matches the versioning rule "minor for new commands/checks".)*
- [x] Decide whether `.workspace/plans/README.md` needs a template change in 1.4.0. *(Confirmed 2026-07-23 — yes.
      Add the optional `Parallelization` block so `/plan` and `/coordinate` write into a documented shape. Exact
      block spec is in §4 `/plan`; the file edit is batched into M2.)*

#### Gate M0

**Gate M0 is fully closed (2026-07-23).** All design decisions are recorded in this plan and the audit reconciled it
against the repo's real enforcement. Framework-owned template editing (M1 → M2) may now begin. The `plans/README.md`
change is confirmed and its content is specified in §4, so M2 has no remaining ambiguity.

### Phase M1 — Root-only prototype

- [x] Write `docs/how-to/multi-agent-collaboration.md` for anyonecan framework contributors. *(Done 2026-07-23 —
      14 sections: applicability notice, §0 when-to-parallelize, §1 principles pointing to AGENTS Handoff, §2 roles
      scoped to this repo's actual trees (Docs/Guide, Command/Prompt, Language-Pack agents — not HomoGraphormer's
      Cache/Baseline roles), §3 worktree setup with anyonecan-specific sibling paths, §4–11 task/report/merge
      templates, §12 Claude Code tool appendix, §13 multiple-humans/PR-gate section, §14 generalized incident
      evidence with no HomoGraphormer names/SHAs. README needs no update — `docs/how-to/` files aren't indexed
      there (verified: neither `git-workflow.md` nor `testing-guide.md` is linked from README either).)*
- [x] Add/prototype the compact always-on handoff/reporting rule in the framework-development root `AGENTS.md`.
      *(Done 2026-07-23 — inserted as `## Handoff and Reporting` right after Work Journal, before Framework
      Versioning, matching the confirmed placement decision in §1 above.)*
- [x] Use the protocol on one real framework task or a controlled dry run. *(Controlled dry run, 2026-07-23 — filled
      §5's task-assignment template for a real upcoming M2 sub-task ("Add the compact Handoff and Reporting section
      to `harness-core/AGENTS.md`"): Base SHA = this commit; allowed files = `harness-core/AGENTS.md` only;
      prohibited = everything else in M2's file list; completion criteria = section present, matches §1's four/five
      bullets, no duplication with the guide. The template filled in completely with no missing field and no
      HomoGraphormer-specific context needed — passes the M1 checklist's next item.)*
- [x] Verify that Base SHA, single-writer ownership, Coordinator-only close-out, and validation environment are
      understandable without HomoGraphormer context. *(Confirmed by the dry run above — every field resolved using
      only this repo's own structure (`harness-core/`, `language-packs/`, `harness-manifest.json`,
      `scripts/check-sync.mjs`), zero references to the source project needed.)*
- [x] Record confusing or excessive rules and simplify before backporting to `harness-core`. *(One simplification
      applied: §6 (standing file-ownership table) and §5's template (per-task ownership field) look redundant at
      first read; kept both deliberately — §6 is the durable default, §5 is the per-task override — but noted this
      distinction explicitly in §6's intro line so it isn't confusing on backport. No other bullets were cut; the
      guide already omits all HomoGraphormer-specific roles/paths per the generalization rule in §2 of this plan.)*

#### Gate M1

**Gate M1 passed (2026-07-23).** The root guide works for framework contributors, contains no generated-project
assumptions, and the dry run confirms its templates are self-contained. Ready to generalize into `harness-core/`
(M2) — the root version above is now the source that M2's `harness-core/docs/how-to/multi-agent-collaboration.md`
adapts (swap anyonecan-specific roles/paths for generated-project-neutral language; the applicability notice,
§0, §1's pointer-to-AGENTS pattern, §8–11 templates, and §13 team section carry over largely as-is).

**Post-M1 review (2026-07-23) — three fixes applied to the root artifacts before M2 inherits them:**
- Guide §3 worktree paths: `..\..\` → `..\`. From the repo root (one level below `anyonecan_harness/`), `..\..\`
  resolved to `C:\` (outside `anyonecan_harness/`) and contradicted the diagram; `..\` correctly lands a sibling of
  `anyonecan/`. Was a depth-mismatch carried over from the source doc (whose CWD was two levels deep).
- Guide §0 and §3 cross-references: `see §14` → `see §12`. Fork / Agent-tool mechanics are in §12 (Tool appendix);
  §14 is "Why these rules exist". Stale numbering inherited from the source doc, where the tool section was §14.
- AGENTS `Handoff and Reporting` trimmed to rule-only bullets (dropped the per-bullet rationale, which duplicates
  guide §14) — keeps the always-loaded section lean per the complexity budget, with a pointer to §14 for the why.
  The operative clean-handoff two-branch rule (WIP commit vs. owned diff) was preserved.
- Known-minor, left for M2 generalization: the applicability notice's dormant-section list is illustrative, not
  exhaustive; §13's title ("Multiple humans") differs from the plan's "Working as a team" label; §2.1↔§6 ownership
  of `harness-core/AGENTS.md` is reconciled only via §6's override clause. None affect correctness.

### Phase M2 — Generated-project templates

- [x] Create the generalized `harness-core/docs/how-to/multi-agent-collaboration.md`. *(Done 2026-07-23 — same
      14-section skeleton as the root M1 guide, with §2 roles generalized to Coordinator/Implementation/Test/
      Research-Review/Execution (per the original artifact spec), §3 worktree paths made project-name-agnostic,
      §6 ownership table generalized (source/test/docs paths instead of anyonecan's own trees), validation
      command generalized to `./scripts/validate.sh`. §13 titled "Working as a team (multiple people)" to match
      the plan §7 spec exactly (the root M1 version's title-drift finding is fixed here at the source of truth
      for generated projects) and includes a forward-pointer to team roles being a separate, richer layer instead
      of duplicating role-assignment policy.)*
- [x] Add the compact actor-count-independent `Handoff and Reporting` section to `harness-core/AGENTS.md` for
      new projects. *(Done — placed after Work Journal, before Key Invariants; same rule-only trimmed form as the
      root version, pointing to the guide's §14 for rationale.)*
- [x] Put the multi-actor applicability notice at the top of the guide. *(Done — also fixed the M1-noted
      "illustrative, not exhaustive" wording issue at the source here.)*
- [x] Replace duplicated handoff/reporting bullets in the guide's basic principles with a pointer to `AGENTS.md`.
      *(Done — §1 point 6.)*
- [x] Add `harness-core/.claude/commands/coordinate.md`. *(Done — language-agnostic, `./scripts/validate.sh`.)*
- [x] Add the root `.claude/commands/coordinate.md` copy **(mandatory — finding A)**. *(Done — uses concrete
      `pnpm validate` and this repo's own Coordinator-only file list, matching the differentiation pattern already
      established by `commit.md`.)*
- [x] Add the `/coordinate` row to the Workflow Prompts table in **both** `harness-core/AGENTS.md` and root
      `AGENTS.md` (finding B). *(Done.)*
- [x] Add `/coordinate` to the command-list pointer bullet in **both** `harness-core/CLAUDE.md` and root
      `CLAUDE.md` (finding B). *(Done.)*
- [x] Add a one-line "for multi-agent work, fill the optional Parallelization block" pointer to
      `harness-core/.claude/commands/plan.md`. *(Done — no conditional logic added.)*
- [x] Insert the optional `Parallelization` block (spec in §4 `/plan`) into `harness-core/.workspace/plans/README.md`.
      *(Done — inside the Template code block, after Notes; plus the `Owner` field and worklog-author-column note.)*
- [x] **Do NOT edit** `start/commit/review/done` prompts or add a scope checker. *(Confirmed untouched.)*
- [x] Add the "Working as a team (multiple people)" section (§7) to the guide. *(Done — §13 of the guide.)*
- [x] Add the optional `Owner` field to the `plans/README.md` template and the optional author column to the
      `worklog.md` format note; add the append-only-rule-additions bullet to AGENTS "Multiple team members".
      *(Done — all three, in `harness-core/.workspace/plans/README.md` and `harness-core/AGENTS.md`. The worklog
      author column is documented as an optional convention in `plans/README.md`'s "Multiple Team Members" section
      rather than as a change to `/done.md`'s literal row template — keeps `/done` itself untouched per the Scope
      Decision, since `/done` already just says "add one row" without rigidly enforcing column count.)*
- [x] Register every new framework-owned file (guide + `coordinate.md`) in `harness-manifest.json`'s
      `frameworkOwned`. *(Done — `.claude/commands/coordinate.md` and `docs/how-to/multi-agent-collaboration.md`
      added; verified valid JSON and a clean two-line diff.)*
- [x] Extend `scripts/check-sync.mjs` to assert every framework-owned command/`docs/how-to` guide in `harness-core`
      is registered in the manifest (finding E). *(Done — new check 3. Verified both directions: temporarily
      removed `coordinate.md` from the manifest and confirmed check-sync fails with the expected message; restored
      and confirmed it passes again.)*
- [x] Run `pnpm validate` and confirm command-set parity + the new manifest-registration guard pass.
      *(Partial — `pnpm`/`node_modules` are not installed in this execution environment, so the full
      typecheck/lint/test suite could not run. Ran `node scripts/check-sync.mjs` directly instead — the exact
      command `pnpm validate` invokes as its first step — and it passes, including the new guard. This M2 change
      touches no `src/`/test files, only `.md`/`.json`/`.mjs`, so typecheck/lint/test risk is nil; full `pnpm
      validate` should still be run in an environment with dependencies installed before this ships, per M3.)*

#### Gate M2

**Gate M2 passed (2026-07-23), with one caveat carried to M3.** The core rules are tool-neutral and concise, the
detailed mechanics live in the guide, and single-agent workflows remain unchanged unless coordination is explicitly
selected. Caveat: `pnpm validate`'s typecheck/lint/test steps have not actually been executed in this environment
(no `node_modules`) — M3's validation step should run the full suite in an environment where dependencies are
installed before the release is considered final.

### Phase M3 — Version, docs, and self-validation

- [x] Bump `harness-core/HARNESS-VERSION` to the approved minor version. *(Done — 1.3.0 → 1.4.0.)*
- [x] Add `FRAMEWORK-CHANGELOG.md` release notes. *(Done — full entry: root-cause evidence, the Handoff and
      Reporting section, the guide, `/coordinate`, the plan-template block, the append-only Key Invariants bullet,
      the 1.5.0 deferral with its litmus rationale, the check-sync guard, and pointers to both design plans.)*
- [x] Update README Supported AI Tools/Quick Start/Work Journal sections with `/coordinate` and the guide link.
      *(Done for Structure (`coordinate.md` added to the command tree), Quick Start (`/coordinate` added to the
      in-project command list), and Work Journal (new paragraph on the opt-in coordination layer + guide link).
      "Supported AI Tools" left unchanged — it maps tool→config-file, not individual commands, and its existing
      generic "copy any `.claude/commands/*.md` as a prompt" statement already covers `/coordinate` without
      needing enumeration.)*
- [x] Run `pnpm validate` (check-sync command parity + the new manifest-registration guard + typecheck/lint/test).
      *(Partial, same caveat as M2 — no `node_modules` in this execution environment. Re-ran
      `node scripts/check-sync.mjs` after all M3 edits and it still passes. README/CHANGELOG/VERSION changes are
      prose/version-string only, no `src/`/test impact. Full `pnpm validate` still needs to run once in an
      environment with dependencies installed before this is considered fully verified — carrying this forward,
      not resolving it silently.)*
- [x] Confirm the extended check-sync from M2 passes and would fail on an unregistered framework-owned file.
      *(Already verified during M2 with a live remove/restore test; re-confirmed passing here after the M3 edits.)*

#### Gate M3

**Gate M3 passed (2026-07-23), with the same M2 caveat carried forward.** Version, changelog, and README are
consistent with what M1/M2 actually shipped. `node scripts/check-sync.mjs` passes. The full `pnpm validate`
typecheck/lint/test suite has still not been executed in any session this feature was built in — flagging this
explicitly rather than treating repeated "not run" as equivalent to "passing." Run it before this release is
pushed/tagged.

### Phase M4 — Fresh-generation matrix

Generate one temporary project for each language pack and verify:

- [ ] TypeScript project contains the guide, command, and always-on Handoff/Reporting AGENTS section.
- [ ] Python project contains the same framework-level artifacts.
- [ ] Java project contains the same framework-level artifacts.
- [ ] A single-agent, multi-turn handoff is governed by AGENTS without invoking `/coordinate`.
- [ ] A multi-actor task opens the guide and applies Coordinator/worktree/wave ownership rules.
- [ ] Each generated project's normal validation still passes.
- [ ] `/coordinate` can choose single-agent mode for a trivial task.
- [ ] `/coordinate` produces Base SHA, waves, file ownership, and integration order for a synthetic multi-file task.
- [ ] Temporary projects/worktrees are created outside any tracked repository and cleaned up safely.

#### Gate M4

All three language packs receive identical coordination semantics without language-specific regressions.

### Phase M5 — Upgrade compatibility matrix

Using disposable copies/projects, verify:

- [ ] Unmodified 1.3.0 project upgrades and receives the new guide, `/coordinate` command, `/plan` pointer, and
      `plans/README.md` block (no `start/commit/review/done` changes — those are 1.5.0).
- [ ] Customized command file is preserved and incoming content appears as `<file>.new`.
- [ ] Existing project AGENTS.md is not overwritten.
- [ ] Missing guide/command files are added and baseline hashes are recorded.
- [ ] A subsequent upgrade recognizes manually merged `.new` content and advances the baseline.
- [ ] Non-Claude instructions still explain how to copy workflow prompts.

#### Gate M5

The 1.3.0 customization-safety contract is preserved. No multi-agent feature justifies weakening user-owned file
protection.

### Phase M6 — Close-out

- [ ] Record validation commands, environment, and exact results in STATUS/worklog.
- [ ] Mark this plan Done only after M0–M5 pass.
- [ ] Ensure README, changelog, manifest, version, root/core commands, and guide agree.
- [ ] Run `/done` exactly once from the Coordinator session.

## Acceptance Criteria

The feature is accepted only when:

1. Generated TypeScript, Python, and Java projects receive the same opt-in coordination guide and command.
2. Existing customized projects can upgrade without losing AGENTS or workflow customizations.
3. Every generated project's AGENTS applies clean handoff, fixed-SHA review, requirement → location reporting,
   and command/working-directory/environment validation evidence regardless of actor count.
4. The detailed guide clearly states that it activates for multiple sessions/sub-agents and points back to
   AGENTS for actor-count-independent rules instead of duplicating them.
5. A coordinated task contract always identifies Coordinator, Base SHA, allowed/prohibited files, one writer per
   file per wave, dependencies, validation environment, and integration order.
6. Sub-agent instructions explicitly prohibit shared-journal edits, generated artifact regeneration, and `/done`.
7. Reviews are tied to immutable Head SHAs *(via the always-on AGENTS Handoff rule in 1.4.0; the `/review` and
   `/commit` scope-inspection edits with `git diff --name-only` land in 1.5.0)*.
8. `/start`, `/commit`, `/review`, and `/done` are **unchanged** in 1.4.0 and keep working exactly as before; only
   `/plan` gains a one-line optional pointer.
9. Full framework validation and all language generation/upgrade matrices pass.
10. The complexity budget holds: a solo user can ignore every 1.4.0 addition and notice only one extra menu item
    (`/coordinate`) plus a short, self-useful AGENTS section.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| AGENTS becomes too long | Limit the always-on section to 4–5 concise bullets; move all actor roles/templates/tool details to the guide. |
| Single-session work misses safety rules | Keep handoff/reporting rules outside the conditional multi-agent guide and verify without `/coordinate`. |
| Rules drift between AGENTS and guide | The guide points to AGENTS instead of restating the four bullets; incident evidence may remain in the guide. |
| Existing AGENTS files miss the rule | Deliver guide/command through upgrade and document the user-owned AGENTS limitation; never overwrite. |
| Coordination metadata is mistaken for a lock | Explicitly state it is a record; rely on branch/worktree isolation and Coordinator messaging. |
| `/coordinate` encourages needless delegation | Require an explicit parallelism-benefit decision and allow a single-agent outcome. |
| Commands regress ordinary workflows | Make coordination branches conditional; include single-agent regression cases. |
| Tool-specific APIs leak into shared rules | Keep tool mechanics in appendices only. |
| Worktrees pollute another repository | Require resolved paths outside all repository roots and verify before creation. |
| Duplicate close-outs persist | Coordinator-only `/done`, exact integrated Head list, and one session-level worklog row. |
| Validation claims are environment-dependent | Require command, environment, writable temp path where relevant, and Coordinator reproduction. |
| Framework-owned additions are omitted from upgrade | Manifest consistency review plus fresh-generation and upgrade matrices. |

## Notes for the Implementing Agent

- Gate M0 is closed and the scope is cut to the slim core (Scope Decision). Implement **only** the 1.4.0 in-scope
  list; the `start/commit/review/done` edits and scope checker are 1.5.0 — do not implement them now.
- Read root `AGENTS.md` first. Any framework-owned edit requires versioning and changelog discipline.
- The source case-study document is detailed evidence, not a template to copy verbatim.
- Do not modify the nested `Homographormer` repository while implementing the parent framework feature.
- Because the parent and nested project are separate Git repositories, resolve worktree paths before creation.
- Keep the implementation incremental and commit by concern: guide/command, workflow prompt updates, manifest and
  version/docs, then validation evidence.
