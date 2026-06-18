# Component (Module) Writing Guide

## File Naming Rules

| Kind | Rule | Example |
|------|------|---------|
| Source file | `kebab-case.ts` | `user-service.ts` |
| Test file | `[original-filename].test.ts` | `user-service.test.ts` |
| Type definitions | `kebab-case.types.ts` | `user.types.ts` |
| Interfaces | `kebab-case.interface.ts` | `user.interface.ts` |

## Interface-First Design

Define the interface before writing the implementation.

```typescript
// user.interface.ts
export interface UserRepository {
  findById(id: string): Promise<User | null>
  save(user: User): Promise<void>
}

// user-repository.ts (implementation)
export class PostgresUserRepository implements UserRepository {
  findById(id: string): Promise<User | null> { ... }
  save(user: User): Promise<void> { ... }
}
```

## Type Safety Rules

- No `any` — use `unknown` when the type is uncertain, then apply a type guard
- Explicit return type on every function (enforced by ESLint `explicit-function-return-type`)
- `as` assertions only when unavoidable; include a comment explaining why

```typescript
// bad
function processData(input: any) { ... }

// good — unknown + type guard
function processData(input: unknown): ProcessedData {
  if (!isValidInput(input)) throw new Error('Invalid input')
  return transform(input)
}
```

## Comment Rules

- All comments in English
- Explain WHY, not WHAT (the code explains what it does)
- Use `// TODO:`, `// FIXME:`, `// NOTE:` tags

```typescript
// TODO: add caching layer — currently hits DB on every call
const user = await userRepository.findById(id)
```

## Architecture Layer Rules

### domain
- Pure TypeScript, no external library imports (→ ADR 001)
- Contains only business logic, entities, and domain events
- Defines interfaces; implementations live in infrastructure

### application
- Implements use cases (input validation, domain logic composition, result return)
- Depends only on domain interfaces (never directly on implementations)

### infrastructure
- Implements connections to external systems (DB, API, file system)
- Houses domain interface implementations

### presentation
- UI, API routers, controllers
- No business logic — delegate to the application layer

## File Structure Order

1. import statements (external packages → internal modules)
2. Type/interface definitions
3. Implementation code
4. export statements (prefer named exports over default exports)
