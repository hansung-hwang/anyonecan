# 테스트 작성 가이드

## 기본 원칙

- 모든 비즈니스 로직 함수에는 단위 테스트가 있어야 합니다
- 테스트는 구현 세부 사항이 아닌 **동작(behavior)**을 검증합니다
- 구조: **Happy Path → Edge Case → Error Case** 순서로 작성
- 커버리지 목표: 핵심 도메인 로직 80% 이상

## 파일 위치

```
src/
  domain/
    user/
      user.ts
      user.test.ts       ← 소스 파일과 같은 디렉터리 (권장)
  presentation/
    components/
      UserCard.tsx
      UserCard.test.tsx  ← 컴포넌트 테스트
  tests/
    arch/
      dependencies.test.ts  ← 아키텍처 규칙 자동 검증
```

## 도메인 로직 테스트

```typescript
import { describe, expect, it } from 'vitest'
import { ValidationError, createUser, validateEmail } from './user'

describe('validateEmail', () => {
  // Happy Path
  it('유효한 이메일 형식이면 예외를 던지지 않는다', () => {
    expect(() => validateEmail('user@example.com')).not.toThrow()
  })

  // Edge Case
  it('대소문자가 섞인 이메일도 유효하다', () => {
    expect(() => validateEmail('User@Example.COM')).not.toThrow()
  })

  // Error Case
  it('@ 기호가 없으면 ValidationError를 던진다', () => {
    expect(() => validateEmail('invalid')).toThrow(ValidationError)
  })
})

describe('createUser', () => {
  it('유효한 입력으로 User를 생성한다', () => {
    const user = createUser('id-1', { email: 'USER@EXAMPLE.COM', name: ' 홍길동 ' })

    expect(user.email).toBe('user@example.com') // 소문자 변환
    expect(user.name).toBe('홍길동')             // 공백 제거
    expect(user.createdAt).toBeInstanceOf(Date)
  })
})
```

## 외부 의존성 모킹

외부 의존성(DB, API, 파일시스템)만 모킹합니다. 도메인 로직은 모킹하지 않습니다.

```typescript
import { describe, expect, it, vi, beforeEach } from 'vitest'
import type { UserRepository } from '@/domain/user/user.interface'
import { UserApplicationService } from './user-application-service'

describe('UserApplicationService', () => {
  let mockRepository: UserRepository
  let service: UserApplicationService

  beforeEach(() => {
    // 인터페이스 기반 모킹 — 구현체에 의존하지 않음
    mockRepository = {
      findById: vi.fn(),
      findByEmail: vi.fn(),
      save: vi.fn(),
      delete: vi.fn(),
    }
    service = new UserApplicationService(mockRepository)
  })

  it('존재하는 ID로 조회 시 사용자를 반환한다', async () => {
    const mockUser = { id: 'user-1', email: 'user@example.com', name: '홍길동', createdAt: new Date() }
    vi.mocked(mockRepository.findById).mockResolvedValue(mockUser)

    const result = await service.findById('user-1')

    expect(result).toEqual(mockUser)
    expect(mockRepository.findById).toHaveBeenCalledWith('user-1')
  })

  it('존재하지 않는 ID로 조회 시 null을 반환한다', async () => {
    vi.mocked(mockRepository.findById).mockResolvedValue(null)

    const result = await service.findById('nonexistent')

    expect(result).toBeNull()
  })
})
```

## 명명 규칙

- `describe` 블록: 테스트 대상 클래스/함수명 (영문)
- `it` 블록: 동작 설명 (한국어, "~하면 ~한다" 형식)

## 주의사항

- `it.only` / `describe.only` — 로컬 디버깅 전용, 커밋 금지
- 테스트 간 상태 공유 금지 — `beforeEach`로 초기화
- `async` 테스트는 반드시 `await` 또는 `return`으로 완료 대기

## 실행 명령어

```bash
pnpm test              # 전체 테스트 1회 실행
pnpm test:watch        # 파일 변경 시 자동 재실행
pnpm test:coverage     # 커버리지 리포트 생성
```
