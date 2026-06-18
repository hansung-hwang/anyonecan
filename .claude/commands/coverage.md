# /coverage — Coverage Report

Run test coverage and report under-covered areas.

## Steps

### 1. Run Coverage

```bash
pnpm test:coverage
```

### 2. Analyze Results

Analyze results in the `coverage/` directory:

- `domain` layer target: **80% or above**
- 0% functions: risk of untested business logic

### 3. Report Format

```
## Coverage Summary

| Layer  | Statements | Branches | Functions | Lines | Status |
|--------|------------|----------|-----------|-------|--------|
| domain | XX%        | XX%      | XX%       | XX%   | ✅/⚠  |

### Untested Items (0% function coverage)
- `src/domain/...`: function name
```

### 4. Recommend Tests

Suggest test cases for domain files below 80% coverage.
