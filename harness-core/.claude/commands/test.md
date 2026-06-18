# /test — Test Generation

Generates unit tests for the specified file.

## Usage

```
/test <file path>
```

## Test Generation Rules

### File Location

- **TypeScript**: `[filename].test.ts` in the same directory as the source file
- **Python**: `test_[filename].py` in `tests/` with the same structure
- **Java**: `[ClassName]Test.java` in `src/test/java/` under the same package

### Coverage Requirements

- At least one test per public function/method
- Both happy path and edge cases included
- Only mock external dependencies (DB, API, file system) — never mock domain logic itself

### Run After Generation

```bash
./scripts/validate.sh
```

If it fails, analyze the error and fix the test code.
