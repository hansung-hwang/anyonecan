# /coverage — Coverage Report

Run test coverage and report under-covered areas.

## Run (per language)

**TypeScript**: `pnpm test:coverage`
**Python**: `python -m pytest --cov=src --cov-report=term-missing`
**Java**: `mvn verify -P coverage` (JaCoCo)

## Analyze Results

- `domain` layer target: **80% or above**
- 0% functions: risk of untested business logic

## Report Format

```
## Coverage Summary

| Layer  | Statements | Branches | Functions | Status |
|--------|------------|----------|-----------|--------|
| domain | XX%        | XX%      | XX%       | ✅/⚠  |

### Untested Items (0% function coverage)
- `filename`: function name
```

Suggest test cases for domain files below 80% coverage.
