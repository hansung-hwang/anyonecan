# CLAUDE.md — {{PROJECT_NAME}}

> Claude Code reads this file plus the rules imported below.
> All project rules (architecture, coding rules, prohibited items,
> validation, steering loop) live in `AGENTS.md` — the single source of
> truth shared by every AI tool. **Edit rules there, not here.**

@AGENTS.md

## Claude Code Extras

- Slash commands live in `.claude/commands/` — see the Workflow Prompts
  table in `AGENTS.md` for what each one does (`/start`, `/plan`, `/done`,
  `/fix`, `/commit`, `/review`, `/test`, `/adr`, `/coverage`, `/coordinate`).
- `.claude/settings.json` wires hooks: auto lint/format after Write/Edit,
  and auto `./scripts/validate.sh` on Stop.
