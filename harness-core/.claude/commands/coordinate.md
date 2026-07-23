# /coordinate — Multi-Agent Coordination Plan

Produce a coordination plan for splitting the active task across multiple agents. This command **plans only** — it
does not create branches/worktrees or spawn agents itself; a human or the calling session acts on the plan.

Full mechanics (roles, worktree setup, conflict rules, templates): `docs/how-to/multi-agent-collaboration.md`. This
command only activates that guide's conditional multi-actor layer — the always-on Handoff and Reporting rules in
`AGENTS.md` apply regardless of whether this command is used.

## Steps

### 1. Read Context

Read `AGENTS.md`, `.workspace/STATUS.md`, the active plan, any other plan marked `- **Status**: In Progress`, and
`git status`.

### 2. Decide: Multi-Agent or Single-Agent

Multi-agent is worth it only when the branches of work are independent, each needs substantial independent
exploration, and their file sets don't overlap (see the guide's §0, "When parallelization is worth it"). If not all
hold, say so explicitly and recommend single-agent instead of forcing a split.

### 3. Identify Dependencies and Wave 0

Map which sub-tasks depend on another's output — those stay sequential, not parallel. If the split needs shared
scaffolding first (a fixture, an interface, a directory), define that as Wave 0, to be committed by the Coordinator
before any agent branches.

### 4. Fix the Base SHA

After Wave 0 (if any) is committed, record that commit as the Base SHA every agent branch must fork from.

### 5. Assign One Writer Per File Per Wave

For each file in scope, assign exactly one writer for the wave. Never assign the same file to two agents in one
wave.

### 6. Generate Agent Contracts

For each agent: goal, allowed files, prohibited files, completion criteria, validation command + environment, and
the completion-report format.

### 7. Mark Shared/Generated Files Coordinator-Owned

`.workspace/**`, `AGENTS.md`, any generated/derived artifact, and lockfiles/manifests are Coordinator-only in every
wave — no agent contract may include them.

### 8. Define Integration Order and Validation

State the order agents are merged in and the exact full validation command + working directory + environment.

### 9. State Completion Authority

Only the Coordinator updates shared journals (`STATUS.md`, `worklog.md`, the plan checklist) and runs `/done`.

## Output Format

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

If step 2 concludes single-agent is the right call, output that decision and a one-line reason instead of the
template above — don't force the shape onto a task that doesn't need it.

## Notes

- This command does not create worktrees, branches, or spawn agents — it produces the plan a human or session
  then acts on.
- Non-Claude Code tools: copy this file's content and use it as a prompt.
