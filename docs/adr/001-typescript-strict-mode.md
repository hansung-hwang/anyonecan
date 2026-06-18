# ADR 001 — TypeScript Strict Mode

- **Date**: 2026-06-17
- **Status**: Accepted

## Decision

Enable `strict: true` and additional strictness options in `tsconfig.json`.

Enabled options:
- `strict` (includes noImplicitAny, strictNullChecks, etc.)
- `noUncheckedIndexedAccess`
- `exactOptionalPropertyTypes`
- `noImplicitReturns`
- `noFallthroughCasesInSwitch`

## Rationale

- Catch runtime errors (null dereference, implicit any, etc.) at compile time
- `noUncheckedIndexedAccess` forces undefined defense on array/record index access
- `exactOptionalPropertyTypes` prevents incorrect optional property assignment
- Minimizes type-related discussion in code reviews — the compiler handles it automatically

## Consequences

**Allowed**
- `unknown` + type guard pattern for handling dynamic data
- Unavoidable `as` assertions (must include a comment explaining why)

**Prohibited**
- Direct use of `any` type
- Use of `@ts-ignore` / `@ts-nocheck`
- Unjustified `as` type assertions
- Disabling individual strict options in `tsconfig.json`
