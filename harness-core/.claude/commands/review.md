# /review — Code Review

Review the currently changed code against the following criteria.

## Review Checklist

### 1. Type Safety
- Dynamic types / `any` usage (TypeScript `any`, Python `Any`, Java raw types)
- Missing explicit return types
- Missing null/undefined/None handling

### 2. Architecture Principles
- Layer dependency direction (`domain` ← `application` ← `infrastructure` ← `presentation`)
- External library imports inside `domain` layer
- Single responsibility principle

### 3. Edge Cases
- Missing null/None/Optional handling
- Missing async error handling
- Missing input validation logic

### 4. Test Coverage
- Unit tests for core business logic
- Both happy path and edge cases covered
- Tests verify behavior, not implementation details

## Output Format

```
## Review Results

### 🔴 Must Fix (blockers)
- [ ] `file:line` — description of issue

### 🟡 Recommended Fix
- [ ] `file:line` — improvement suggestion

### 🟢 Tests Needed
- [ ] `file` — missing test case

### ✅ Passed
```

If there are no issues, output `✅ All review items passed`.
