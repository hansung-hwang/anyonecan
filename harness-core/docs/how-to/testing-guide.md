# Testing Guide

## Core Principles

- Every business logic function must have unit tests
- Tests verify **behavior**, not implementation details
- Cover both happy path and edge cases
- Coverage target: 80%+ for core domain logic

## File Location

```
src/ (or the language's equivalent source root)
  domain/
    user/
      <source file>          e.g. user-service.ts / user_service.py / UserService.java
      <matching test file>   co-located or in the parallel test tree, per language convention
  tests/ (or src/test for Java)
    arch/
      <architecture rule test>   automated layer-dependency validation
```

Each language pack's `scripts/validate.sh` and arch test define the exact
convention (co-located `.test.ts` files for TypeScript, a parallel `tests/`
tree for Python, `src/test/java/...` for Java).

## Test Structure (Arrange–Act–Assert)

Regardless of language or test framework (vitest, pytest, JUnit), structure
each test in three parts:

1. **Arrange** — set up the input and any dependencies
2. **Act** — call the function or method under test
3. **Assert** — check the result matches what's expected

```
test "returns a user when given an existing user ID":
    # Arrange
    userId = "user-1"

    # Act
    result = service.findById(userId)

    # Assert
    assert result is not null
    assert result.id == userId
```

## Naming Rules

- Test group name (`describe` / test class): name of the class or function under test (English)
- Individual test name (`it` / test method): describe the behavior in plain English (e.g., "returns X when Y")

## Notes

- Directives that skip or isolate a single test for debugging (`it.only`,
  `describe.only`, `@Disabled`, `@pytest.mark.skip`) are for local debugging
  only — never commit them silencing a real failure
- Do not test implementation details (internal methods, private variables) directly
- No shared state between tests — reset fixtures/state before each test

## Run Commands

Run `./scripts/validate.sh` for the full typecheck + lint + test loop. For
just the test suite, use your language pack's test command (e.g. `pnpm test`,
`pytest`, `mvn test`) — see the pack's `scripts/validate.sh` for the exact
invocation.

## Architecture Tests

Each language pack ships an architecture test (TypeScript:
`src/tests/arch/dependencies.test.ts`, Python: `tests/arch/test_dependencies.py`,
Java: `src/test/java/arch/DependencyTest.java`) that automatically validates
layer dependencies across all source files. Run the test suite after adding
source files to immediately catch dependency violations.
