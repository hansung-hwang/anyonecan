# /test — Test Generation

Generates Vitest-based unit tests for the specified file.

## Usage

```
/test <file path>
```

Example: `/test src/domain/user/user-service.ts`

## Test Generation Rules

### File Location
- Save as `[filename].test.ts` in the same directory as the source file
- Example: `src/domain/user/user-service.ts` → `src/domain/user/user-service.test.ts`

### Test Structure
```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest'
// import the module under test

describe('[ModuleName]', () => {
  // happy path
  describe('[functionName]', () => {
    it('returns correct result for valid input', () => { ... })
    it('handles boundary values correctly', () => { ... })
    it('throws an error when [condition]', () => { ... })
  })
})
```

### Coverage Requirements
- At least one test per exported function/class
- Both happy path and edge cases included
- Written in a type-safe way without `any`

### Mocking Principles
- Only mock external dependencies (DB, API, file system)
- Do not mock domain logic itself
- Maintain type safety when using `vi.mock()`

## Auto-run After Generation

Run the following immediately after creating the test file:

```bash
pnpm validate
```

If it fails, determine whether the test or production code violates the
requirement. Fix the cause within the authorized scope; do not weaken a valid
test to make an incorrect implementation pass. Report out-of-scope fixes.
