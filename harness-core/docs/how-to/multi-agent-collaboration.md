# Multi-Agent Collaboration

Operating rules for dividing work on this project across multiple AI sessions or sub-agents at once, so work stays
reviewable, ownership stays unambiguous, and shared project state (`.workspace/`, generated/derived artifacts)
doesn't drift or duplicate.

> **Applicability — this activates only for multiple actors.**
> Read this when multiple sessions or sub-agents touch this repository **at the same time**. If you're working
> alone across turns/sessions, most of §2–3, §6–7, §9–10, and §12 are dormant (illustrative examples below, not an
> exhaustive list — the applicability notice is the actual test).
> The rules that apply **regardless of actor count** — clean handoff, SHA-fixed review, requirement→location
> reporting, validation command+environment evidence — live in `AGENTS.md`'s **Handoff and Reporting** section, the
> single source loaded every session. This guide is the multi-actor layer on top of that.

## 0. When parallelization is worth it

Adding an agent has a fixed cost: **a new agent re-reads the codebase from zero** (a fork inherits context instead,
at the cost of a context copy — see §12). Only parallelize when the benefit clears that cost.

Worth it — **all** of the following hold:

- The branches of work are genuinely **independent**; a later task doesn't build on an earlier task's output.
- Each branch requires **substantial independent exploration** — different external material, different modules.
- The sets of files each branch touches **don't overlap**.

Typically worth it: writing tests for several unrelated modules in parallel; researching several independent
external dependencies/libraries at once; implementing two features that touch entirely separate parts of the
codebase.

Not worth it: writing tests for code already loaded in the Coordinator's context; a refactor with a sequential
dependency (extracting a shared helper, then implementing something on top of it) — running these in parallel only
adds re-review cost without a speed gain.

## 1. Basic principles

1. Exactly one Coordinator at a time.
2. Each agent works in its own branch and worktree.
3. Divide work by **file scope**, not just by feature.
4. Shared docs and generated/derived files are Coordinator-only.
5. Don't parallelize two tasks that need to edit the same file.
6. **Follow `AGENTS.md`'s Handoff and Reporting section as-is** — clean handoff, SHA-fixed review,
   requirement→location reporting, command+environment evidence, cross-reference checks on doc edits. Multi-actor
   work just makes violations more expensive; the rule itself applies at any actor count.
7. **Dependent tasks gain nothing from parallelization** (§0) — if a later task builds on an earlier one's output,
   sequential is cheaper once re-review cost is counted.

Recommended shape for a multi-agent session:

```text
Coordinator
├─ Implementation Agent(s) (one per independent module/file scope)
├─ Test Agent
└─ Research/Review Agent (if the task needs independent investigation, not just implementation)
```

Three to four concurrent actors including the Coordinator is a reasonable ceiling — prioritize genuinely
independent work over adding headcount.

## 2. Roles and responsibilities

### 2.1 Coordinator

- Owns the active plan and its priorities.
- Decomposes work into independent units and assigns file ownership.
- Finalizes shared interfaces/schemas before assignment.
- Reviews and cherry-picks/merges agent results.
- Runs the project's full validation (`./scripts/validate.sh`) and regenerates any derived artifact once, after
  integration.
- Updates `STATUS.md`, `worklog.md`, and the plan checklist.
- Runs `/done` at session close.

Coordinator-only files: `AGENTS.md`, `.workspace/STATUS.md`, `.workspace/worklog.md`, `.workspace/plans/**`, any
generated/derived artifact, lockfiles, and build manifests.

### 2.2 Implementation Agent

Owns one module or file scope per agent — never assign two agents to the same file scope in one wave.

Allowed: the source files explicitly assigned for this task.

Prohibited: `.workspace/**`, `AGENTS.md`, other agents' assigned files, any generated/derived artifact.

### 2.3 Test Agent

Writes or updates tests for code already implemented or being implemented in parallel by an Implementation Agent.

Allowed: the test files explicitly assigned.

Prohibited: production source code outside the assignment (report a needed fix to the Coordinator instead of
silently editing it), `.workspace/**`, `AGENTS.md`.

### 2.4 Research/Review Agent

Investigates external material (a library's license, an API's behavior, prior art) or performs an independent
review pass, without editing source.

Allowed: `docs/**` (findings write-ups), review notes in the assigned scope.

Prohibited: production source code, `.workspace/**`, `AGENTS.md`.

### 2.5 Execution Agent

Runs a long external job (a build pipeline, a deployment, a data/training run) that has to happen once, not in
parallel with itself — used when a task needs isolation from session limits or external resource contention, not
for parallel speed.

Allowed: whatever the job's own output directory is; never runs the same job concurrently with another Execution
Agent.

Prohibited: everything not explicitly part of the job's assigned scope.

## 3. Worktree setup

Give each agent its own worktree and branch, resolved **outside** this repository's own tree:

```powershell
git worktree add ..\<project-name>-agent1 -b agent/task-1
git worktree add ..\<project-name>-agent2 -b agent/task-2
```

`..\` resolves to the parent of this project's own directory — a sibling worktree there, not a subdirectory, so it
never shows up as an untracked path inside `git status` for this repo. If the parent directory is itself inside
another tracked repository, resolve the worktree path further up, outside every tracked tree.

The Coordinator reviews and brings in finished agent work:

```powershell
git cherry-pick <agent-commit>
```

Cherry-pick is easier to manage than merge for small, independent units of work.

Claude Code's Agent tool can create and clean these up automatically — see §12.

## 4. What makes a good task unit

- Completion criteria fit in one sentence.
- The allowed file scope is explicit.
- It can be tested independently, without another agent's work.
- It finishes in one or a small number of commits.

Good: *"Add input validation to the `createUser` handler and its test. Scope limited to that handler and its test
file."*

Bad: *"Finish the user-management feature."*

## 5. Task assignment template

```markdown
## Goal

Concrete deliverable.

## Background

Related plan items and decisions already made.

## Base SHA

- Base SHA: the fixed commit every agent branch must fork from.

## Allowed files

- path/a.ts

## Prohibited files

- .workspace/**
- AGENTS.md
- files owned by another agent
- any generated/derived artifact

## Completion criteria

- What "done" mechanically means (a check passes, a section exists, a table is filled)

## Validation command

Exact command to run, including working directory and any environment flags.

## File ownership

- The single writer for each integration-point file in this wave
- Files the Coordinator must not touch concurrently

## Commit

One self-contained commit; specify the message format.

## Completion report

- Summary of changes
- Validation result
- Commit SHA
- Risks discovered
- Integration work the Coordinator still needs to do
```

## 6. File ownership table

This is the **durable default** — who owns a path in general. §5's per-task template has its own `File ownership`
field for the **per-task override** (e.g. temporarily handing a Coordinator-owned integration point to one agent for
a wave). When they conflict, the task assignment wins for that task only; this table is the fallback.

| Path | Default owner | Sub-agent edits |
|---|---|---|
| `AGENTS.md` / `CLAUDE.md` | Coordinator | Prohibited |
| `.workspace/**` | Coordinator | Prohibited |
| Any generated/derived artifact, lockfiles, build manifests | Coordinator | Prohibited |
| Source files (by module/file scope) | One Implementation Agent per scope | Only the assigned scope |
| Test files | Test Agent(s), scoped to their assignment | Only assigned files |
| `docs/**`, `docs/adr/**` | Assigned agent, if any | Only assigned files |

## 7. Conflict-avoidance rules

### No concurrent writers on one file

If two tasks need the same file, run them sequentially. Don't assign both to different agents in the same wave.

### Freeze shared fixtures first

If a wave depends on shared scaffolding (a new schema shape, a shared fixture, a new directory), the Coordinator
commits that first and records the resulting SHA as the wave's Base SHA. No agent branches until that commit exists.

### Regenerate derived files exactly once, after integration

```text
each agent edits its source files
→ Coordinator merges
→ full validation (./scripts/validate.sh)
→ Coordinator regenerates any derived artifact once
```

### Single writer for shared docs

Sub-agents do not edit: `STATUS.md`, `worklog.md`, the active plan's checkboxes, `AGENTS.md`, or run `/done`.

## 8. Agent completion report format

```markdown
## Result

- Branch:
- Commit:
- Files changed:
- Tests added:
- Validation command:
- Validation result:

## Findings

- Product issues found:
- Deviations from the plan:
- Open risks:

## Coordinator action needed

- Integration files to update after merge:
- Whether any derived artifact needs regeneration:
- Whether docs need updating:
```

Sub-agents do not adopt results as official, update shared docs, regenerate derived artifacts, or run `/done`.

## 9. Coordinator merge procedure

1. Check the agent's report and its declared file scope.
2. Mechanically verify no disallowed file is included — don't eyeball it:

   ```powershell
   git diff --name-only <base-sha>..<agent-head>   # compare against the allowlist
   ```

3. Review the diff and commit boundaries.
4. Run the relevant tests on the agent's branch.
5. Cherry-pick onto the Coordinator branch.
6. Re-run the relevant tests after merge.
7. Run full validation after all agents for the wave are merged.
8. Regenerate any derived artifact exactly once.
9. Update the plan checklist and `STATUS.md`.
10. Only the Coordinator runs `/done` at session close.

## 10. Failure and rework

If an agent's result has a problem, send that same agent a scoped follow-up rather than the Coordinator making a
large direct edit:

```text
The current commit is missing a test for the X edge case.
Keep the same allowed-file scope and add one follow-up commit on the same branch.
Do not touch STATUS, the plan, or any derived artifact.
```

## 11. Next-session start prompt

```text
Run /start, read the active plan, and proceed multi-agent.

You are the Coordinator this session.
Give each sub-agent its own branch/worktree and enforce:

1. Only the Coordinator edits .workspace/**, AGENTS.md, and any derived artifact.
2. Every agent gets an explicit allowed/prohibited file list.
3. Never assign the same file to two agents.
4. Sub-agents report test results and commit SHA only — they do not run /done.
5. After merging, the Coordinator runs full validation, regenerates derived artifacts, and updates the plan.

Split <task> into independent units first, propose file ownership and dependencies, then run in parallel.
```

Or, for Claude Code specifically, run `/coordinate` to generate this plan directly from the active task.

## 12. Tool appendix

This section's mechanics are implemented directly by Claude Code's Agent tool; other tools use the manual
branch/worktree flow in §3.

- **Claude Code — `isolation: "worktree"`**: creates a temporary git worktree per agent automatically, replacing
  the manual `git worktree add` in §3; auto-cleans up if the agent makes no changes. Use manual worktrees only when
  they need to persist across sessions.
- **Claude Code — `subagent_type: "fork"`**: inherits the current conversation's context instead of re-deriving it.
  Use it to continue work that already has context loaded — a fresh `Agent` call always starts from zero, which is
  why small tasks are cheaper to do directly than to delegate (§0).
- **Claude Code — `SendMessage`**: sends a follow-up to an already-running agent with context intact — this is what
  §10's "scoped follow-up to the same agent" means in practice. Calling `Agent` again loses that context.
- **Verification happens in the Coordinator's own loop**, not in another sub-agent. Delegating review/re-verification
  defeats the point — the Coordinator is the one actor guaranteed to see the final merged state.
- Sub-agents never run `/done` (§8). Only the Coordinator does.
- **Other tools** (Codex, manual sessions): use `git worktree add`/`git cherry-pick` from §3 directly; the task
  contract in §5 and the report format in §8 are tool-neutral and apply unchanged.

## 13. Working as a team (multiple people)

Same coordination model — **only the integration gate changes: a pull-request review replaces the Coordinator's
cherry-pick.** Most of the underlying support already exists: `AGENTS.md`'s "Multiple team members" note
(per-branch `STATUS.md`, append-only `worklog.md`) and the "PRs without tests" rule both already assume PR-based
integration.

| Concern | Multi-agent (one human, N agents) | Multiple humans |
|---|---|---|
| Isolation | worktree/branch per agent | branch per person/feature |
| **Integration gate** | Coordinator cherry-picks/merges | **PR review + merge** |
| Shared journal | Coordinator-only writes `.workspace/` | per-branch `STATUS.md`; append-only `worklog.md` |
| Handoff/report | clean tree + SHA, requirement→location | the same rules, expressed as a good PR description |
| No lock | coordination notes are a record, not a lock | `.workspace/` is not a cross-branch lock; coordinate via PRs |

When multiple people work this repository at once: the always-on Handoff and Reporting rules apply to a PR exactly
as they apply to an agent handoff — a clean branch, a `requirement → file/symbol/test location` PR description, and
validation command+environment evidence as PR evidence. `.workspace/` state stays advisory, not a lock, across
branches with different file snapshots. `.workspace/plans/README.md`'s optional `Owner` field records who owns a
task's plan; `worklog.md` rows may optionally include an author column when useful.

**Team roles** (who works on which part of the codebase — e.g. a backend/frontend/data split) are a separate,
richer layer than this section covers; see your project's own planning docs if that's what you need — this guide's
scope is coordination mechanics, not role assignment policy.

## 14. Why these rules exist

The problems this guide standardizes are shared-state and reporting failures, not code-quality failures — a
reviewed diff can be entirely correct while the surrounding coordination still breaks in specific, repeatable ways:

- A file finishes review, then grows before commit — without re-checking `git status` immediately before
  committing, unreviewed code can enter a commit believed to be fully reviewed. → SHA-fixed review.
- Uncommitted work from two sessions accumulates in one working tree with no clear boundary between them. →
  clean-tree handoff.
- A shared journal file drifts — duplicate `worklog.md` rows, or `STATUS.md`'s top updated while its
  Next Steps/Blockers still describe finished work. → single writer for shared docs.
- A completion report states a count ("N items addressed") while the underlying document body is actually
  unchanged and only review notes were touched. → requirement→location reporting.
- A validation claim ("N tests passed") is true in one environment and false in another because of a
  writable-temp-path or similar environment difference, not a code defect. → command+environment evidence.

Structure (who owns what file) breaks less often than these reporting/handoff failures do — that is why this
guide's basic principles (§1) point back to `AGENTS.md`'s Handoff and Reporting section rather than treating it as
multi-agent-specific: the rule protects a single actor working across turns just as much as it protects a
multi-agent session.
