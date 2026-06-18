# ADR 002 — ESLint + Prettier Toolchain

- **Date**: 2026-06-17
- **Status**: Accepted

## Decision

Separate responsibilities: ESLint (`@typescript-eslint/recommended-requiring-type-checking`) for code quality checks,
Prettier for formatting.

Auto-run on file save via the PostToolUse Hook (`scripts/lint-format-hook.mjs`).

## Rationale

- Leverages the strengths of ESLint and Prettier in their respective roles
- `@typescript-eslint/recommended-requiring-type-checking` enables type-aware linting
  — auto-detects errors like `no-floating-promises` and `await-thenable` using type information
- PostToolUse Hook auto-formats on save → eliminates manual formatting
- ESLint flat config (`eslint.config.js`) ensures v9 compatibility

## Consequences

**Allowed**
- `// eslint-disable-next-line <rule>` for specific lines (reason comment required)
- Adding build artifacts to the `ignores` array in `eslint.config.js`

**Prohibited**
- Block-level `// eslint-disable` disabling
- Adding source files to `ignores`
- Manual formatting (the hook handles it automatically)
- Arbitrary changes to Prettier config (`.prettierrc`)
