# 컴포넌트(모듈) 작성 가이드

## 파일 네이밍 규칙

| 종류 | 규칙 | 예시 |
|------|------|------|
| 소스 파일 | `kebab-case.ts` | `user-service.ts` |
| 테스트 파일 | `[원본파일명].test.ts` | `user-service.test.ts` |
| 타입 정의 | `kebab-case.types.ts` | `user.types.ts` |
| 인터페이스 | `kebab-case.interface.ts` | `user.interface.ts` |

## 인터페이스 우선 설계

구현 전 인터페이스를 먼저 정의합니다.

```typescript
// user.interface.ts
export interface UserRepository {
  findById(id: string): Promise<User | null>
  save(user: User): Promise<void>
}

// user-repository.ts (구현체)
export class PostgresUserRepository implements UserRepository {
  findById(id: string): Promise<User | null> { ... }
  save(user: User): Promise<void> { ... }
}
```

## 타입 안전성 규칙

- `any` 금지 — 타입을 모를 땐 `unknown` 사용 후 타입 가드 적용
- 모든 함수에 반환 타입 명시 (ESLint `explicit-function-return-type` 강제)
- `as` 단언은 불가피한 경우에만, 한국어 주석으로 이유 작성

```typescript
// 잘못된 예
function processData(input: any) { ... }

// 올바른 예 — unknown + 타입 가드
function processData(input: unknown): ProcessedData {
  if (!isValidInput(input)) throw new Error('유효하지 않은 입력')
  return transform(input)
}
```

## 주석 규칙

- 모든 주석은 한국어로 작성
- WHAT이 아닌 WHY를 설명 (코드 자체가 WHAT을 설명)
- `// TODO:`, `// FIXME:`, `// NOTE:` 태그 사용

```typescript
// TODO: 캐싱 레이어 추가 필요 — 현재 매 호출마다 DB 조회 발생
const user = await userRepository.findById(id)
```

## 아키텍처 레이어별 규칙

### domain
- 순수 TypeScript, 외부 라이브러리 import 금지 (→ ADR 001)
- 비즈니스 로직, 엔티티, 도메인 이벤트만 포함
- 인터페이스를 정의하고 구현체는 infrastructure에 위치

### application
- 유즈케이스 구현 (입력 검증, 도메인 로직 조합, 결과 반환)
- domain 인터페이스에만 의존 (구현체에 직접 의존 금지)

### infrastructure
- 외부 시스템(DB, API, 파일 시스템) 연동 구현
- domain 인터페이스 구현체 위치

### presentation
- UI, API 라우터, 컨트롤러
- 비즈니스 로직 포함 금지 — application 레이어에 위임

## 파일 내 구성 순서

1. import 문 (외부 패키지 → 내부 모듈 순)
2. 타입/인터페이스 정의
3. 구현 코드
4. export 문 (named export 우선, default export 지양)
