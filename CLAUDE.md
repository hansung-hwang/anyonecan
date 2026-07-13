# CLAUDE.md

> **⚠ This file is for framework development only.**
> To create a new project, run `setup.ps1` (Windows) or `./setup.sh` (Mac/Linux),
> then run the AI tool from the generated project directory.
>
> Claude Code reads this file plus the rules imported below.
> All project rules (architecture, coding rules, prohibited items,
> validation, steering loop) live in `AGENTS.md` — the single source of
> truth shared by every AI tool. **Edit rules there, not here.**

@AGENTS.md

## Claude Code Extras

- Slash commands live in `.claude/commands/` — see the Workflow Prompts
  table in `AGENTS.md` for what each one does (`/start`, `/plan`, `/done`,
  `/fix`, `/commit`, `/review`, `/test`, `/adr`, `/coverage`).
