# /test — 테스트 생성

지정한 파일에 대한 Vitest 기반 단위 테스트를 생성합니다.

## 사용법

```
/test <파일 경로>
```

예시: `/test src/domain/user/user-service.ts`

## 테스트 생성 규칙

### 파일 저장 위치
- 소스 파일과 같은 디렉터리에 `[파일명].test.ts` 로 저장
- 예: `src/domain/user/user-service.ts` → `src/domain/user/user-service.test.ts`

### 테스트 구조
```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest'
// 테스트 대상 import

describe('[모듈명]', () => {
  // 정상 케이스
  describe('[함수명]', () => {
    it('정상 입력 시 올바른 결과를 반환한다', () => { ... })
    it('경계값 입력 시 올바르게 처리한다', () => { ... })
    it('[예외 조건] 시 에러를 던진다', () => { ... })
  })
})
```

### 커버리지 기준
- 모든 `export` 함수/클래스에 최소 1개 이상의 테스트
- 정상 케이스(happy path) + 예외 케이스(edge case) 모두 포함
- `any` 없이 타입 안전하게 작성

### 모킹 원칙
- 외부 의존성(DB, API, 파일시스템)만 모킹
- 도메인 로직 자체는 모킹하지 않음
- `vi.mock()` 사용 시 타입 안전성 유지

## 생성 후 자동 실행

테스트 파일 생성 직후 아래 명령을 실행합니다:

```bash
pnpm test
```

실패 시 오류 원인을 분석하고 테스트 코드를 수정합니다.
