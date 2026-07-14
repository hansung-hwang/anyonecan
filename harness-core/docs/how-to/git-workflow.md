# Git Workflow Guide

## Commit Message Format

```
<type>(<scope>): <short description>

[optional] body — explain the reason for and context of the change

[optional] footer — related issue number (Closes #123)
```

## Type List

| Type | When to use |
|------|-----------|
| `feat` | Add a new feature |
| `fix` | Fix a bug |
| `refactor` | Improve code without changing behavior |
| `test` | Add or modify tests |
| `docs` | Write or modify documentation |
| `chore` | Build/config changes (no functional impact) |
| `perf` | Performance improvement |

## Commit Example

```
feat(user): add user profile update API

Split the update capability out of the read-only API so the
single-responsibility principle is respected.

Closes #42
```

## Branch Strategy

| Branch | Purpose |
|--------|------|
| `main` | Stable, deployable branch |
| `feat/<feature-name>` | New feature development |
| `fix/<bug-name>` | Bug fix |
| `chore/<task-name>` | Config / dependency changes |

## Pre-commit Checklist

```bash
./scripts/validate.sh   # confirm typecheck + lint + test all pass
```

- [ ] `./scripts/validate.sh` fully passes
- [ ] Tests added when business logic changes
- [ ] Architecture dependency rules respected
- [ ] No banned debug output left in code (see `AGENTS.md` Prohibited list —
      `console.log` / `print()` / `System.out.print` depending on language)
- [ ] Checked whether any `.env` file is staged

## Cautions

- Do not use `--no-verify` — hooks must not be bypassed
- Do not commit `.env` or `.env.local`
- Do not commit with no staged files
- Do not hardcode sensitive information (API keys, tokens) in code
- Add new environment variables only to `.env.example`, then inform the user
