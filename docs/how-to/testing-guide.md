# Testing Guide

## Core Principles

- Every business logic function must have unit tests
- Tests verify **behavior**, not implementation details
- Cover both happy path and edge cases
- Coverage target: 80%+ for core domain logic

## File Location

```
src/
  domain/
    user/
      user-service.ts
      user-service.test.ts    ← co-located with source (recommended)
  tests/
    arch/
      dependencies.test.ts    ← automated architecture rule validation
```

## Test Structure (Arrange–Act–Assert)

```typescript
import { describe, it, expect, beforeEach } from 'vitest'
import { UserService } from './user-service'

describe('UserService', () => {
  let service: UserService

  beforeEach(() => {
    service = new UserService()
  })

  describe('findById', () => {
    it('returns a user when given an existing user ID', async () => {
      // Arrange
      const userId = 'user-1'

      // Act
      const result = await service.findById(userId)

      // Assert
      expect(result).not.toBeNull()
      expect(result?.id).toBe(userId)
    })

    it('returns null when given a non-existent ID', async () => {
      const result = await service.findById('nonexistent')
      expect(result).toBeNull()
    })
  })

  describe('create', () => {
    it('throws ValidationError when the email format is invalid', async () => {
      await expect(service.create({ email: 'invalid' })).rejects.toThrow('ValidationError')
    })
  })
})
```

## Naming Rules

- `describe` block: name of the class or function under test (English)
- `it` block: describe the behavior in plain English (e.g., "returns X when Y")

## Notes

- `it.only` / `describe.only` are for local debugging only — never commit
- Do not test implementation details (internal methods, private variables) directly
- No shared state between tests — reset with `beforeEach`

## Run Commands

```bash
pnpm test              # run all tests once
pnpm test:watch        # re-run on file changes
pnpm test:coverage     # generate coverage report (coverage/ directory)
```

## Architecture Tests

`src/tests/arch/dependencies.test.ts` automatically validates layer dependencies across all source files.
Run `pnpm test` after adding source files to immediately catch dependency violations.
