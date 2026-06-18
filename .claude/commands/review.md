# /review — Code Review

Review the currently changed code against the following criteria.

## Review Checklist

### 1. Type Safety
- Use of `any` type
- Use of `@ts-ignore` / `@ts-nocheck`
- Unnecessary type assertions (`as`)
- Missing explicit return types
- Type guards applied when handling `unknown`

### 2. Architecture Principles
- Layer dependency direction (`domain` ← `application` ← `infrastructure` ← `presentation`)
- External library imports inside `src/domain`
- Single responsibility principle
- Interface/implementation separation

### 3. Edge Cases
- Missing `null` / `undefined` handling
- Array index access without bounds check (`noUncheckedIndexedAccess`)
- Async error handling (`try/catch`, `Promise` rejection)
- Input validation logic

### 4. Test Coverage
- Unit tests for core business logic
- Both happy path and edge cases covered
- Tests verify behavior, not implementation details

## Output Format

If issues are found, output a checklist in this format:

```
## Review Results

### 🔴 Must Fix (blockers)
- [ ] `src/domain/user/user-service.ts:42` — `any` type used. Replace with `User` type
- [ ] `src/application/order/order-handler.ts:17` — infrastructure import in domain layer

### 🟡 Recommended Fix
- [ ] `src/application/payment/payment-service.ts:88` — missing null check. Use `payment?.id`
- [ ] `src/domain/product/product.ts:55` — missing function return type

### 🟢 Tests Needed
- [ ] `src/domain/user/user-service.ts` — no test for invalid email format case
- [ ] `src/application/order/order-handler.ts` — out-of-stock exception case not covered

### ✅ Passed
List items with no issues here.
```

If there are no issues, output `✅ All review items passed`.
