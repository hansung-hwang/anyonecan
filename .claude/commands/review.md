# /review — 코드 리뷰

현재 변경된 코드를 아래 기준으로 검토합니다.

## 검토 항목

### 1. 타입 안전성
- `any` 타입 사용 여부
- `@ts-ignore` / `@ts-nocheck` 사용 여부
- 불필요한 타입 단언(`as`) 사용 여부
- 반환 타입 명시 여부
- `unknown` 처리 시 타입 가드 적용 여부

### 2. 아키텍처 원칙
- 레이어 의존성 방향 준수 여부 (`domain` ← `application` ← `infrastructure` ← `presentation`)
- `src/domain` 내부에서 외부 라이브러리 import 여부
- 단일 책임 원칙 준수 여부
- 인터페이스와 구현의 분리 여부

### 3. 엣지 케이스
- `null` / `undefined` 처리 누락 여부
- 배열 인덱스 접근 시 범위 검사 여부 (`noUncheckedIndexedAccess` 대응)
- 비동기 오류 처리 (`try/catch`, `Promise` rejection) 여부
- 입력값 검증 로직 존재 여부

### 4. 테스트 충분성
- 핵심 비즈니스 로직에 단위 테스트 존재 여부
- 정상 케이스와 예외 케이스 모두 커버 여부
- 테스트가 구현 세부사항 대신 동작을 검증하는지 여부

## 출력 형식

문제가 발견되면 아래 형식의 체크리스트로 출력합니다:

```
## 리뷰 결과

### 🔴 필수 수정 (블로커)
- [ ] `src/domain/user/user-service.ts:42` — `any` 타입 사용. `User` 타입으로 교체 필요
- [ ] `src/application/order/order-handler.ts:17` — domain 레이어에서 infrastructure import

### 🟡 권장 수정
- [ ] `src/application/payment/payment-service.ts:88` — null 체크 누락. `payment?.id` 사용 권장
- [ ] `src/domain/product/product.ts:55` — 함수 반환 타입 미명시

### 🟢 테스트 보완 필요
- [ ] `src/domain/user/user-service.ts` — 이메일 형식 오류 케이스 테스트 없음
- [ ] `src/application/order/order-handler.ts` — 재고 부족 예외 케이스 미커버

### ✅ 통과
이상 없는 항목은 여기에 나열합니다.
```

문제가 없으면 `✅ 모든 검토 항목 통과` 를 출력합니다.
