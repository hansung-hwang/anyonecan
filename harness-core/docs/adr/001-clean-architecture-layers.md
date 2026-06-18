# ADR 001 — Clean Architecture Layer Dependencies

- **Date**: {{DATE}}
- **Status**: Accepted

## Decision

Enforce unidirectional dependency: `domain` ← `application` ← `infrastructure` ← `presentation`.
Automatically monitor this with architecture tests (`src/tests/arch/` or `tests/arch/`).

## Rationale

- Isolates the `domain` layer from external libraries, making business logic resilient to change
- Architecture tests automatically catch regressions at the layer boundary
- Clear dependency direction minimizes structural discussion during code reviews

## Consequences

**Allowed**
- Standard library usage in `domain` (e.g., `java.util`, `os`, Node.js `path`)

**Prohibited**
- Direct external library imports in `domain`
- Importing from a higher layer (`application` or above) in a lower layer (`domain`)
