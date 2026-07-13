# /coverage — Coverage Report

Run test coverage and report under-covered areas.

## Run (per language)

**TypeScript**: `pnpm test:coverage` (vitest coverage is scoped to `src/domain/**` — see `vitest.config.ts`)
**Python**: `python -m pytest --cov=src/domain --cov-report=term-missing --cov-fail-under=80`
**Java**: `mvn verify -P coverage` (JaCoCo — currently project-wide, not domain-scoped; see the `coverage` profile comment in `pom.xml`)

These are also enforced as a CI gate (`.github/workflows/ci.yml`) separate
from the fast `scripts/validate.sh` used by the pre-commit hook, so local
commits stay fast while PRs are still blocked on the threshold.

## Analyze Results

- `domain` layer target: **80% or above** (TS/Python enforce this exactly;
  Java's gate is project-wide for now, see above)
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
