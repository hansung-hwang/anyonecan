# ADR 003 — Vitest Testing Framework

- **Date**: 2026-06-17
- **Status**: Accepted

## Decision

Use Vitest instead of Jest as the testing framework.

## Rationale

- **ESM-native support** — works without additional transform config in `"type": "module"` projects
- **Fast execution** — Vite-based transform runs TypeScript files directly, no build step needed
- **Jest-compatible API** — same interface (`describe`, `it`, `expect`), zero migration cost
- **Native coverage** — built-in V8 engine coverage via `@vitest/coverage-v8`

## Consequences

**Allowed**
- Custom configuration via `vitest.config.ts` (create if needed)
- Coverage report generation with `pnpm test:coverage`
- Test files co-located with source files or placed in `src/tests/`

**Prohibited**
- Installing Jest or any other test framework alongside Vitest
- Submitting business logic PRs without tests
- Keeping domain logic coverage below 80%
- Committing `it.only` / `describe.only` (allowed locally for debugging only)
