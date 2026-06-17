# 테스트 작성 가이드

## 기본 원칙

- 모든 비즈니스 로직 함수에는 단위 테스트가 있어야 합니다
- 테스트는 구현 세부 사항이 아닌 **동작(behavior)**을 검증합니다
- 정상 케이스와 예외 케이스를 모두 커버합니다
- 커버리지 목표: 핵심 도메인 로직 80% 이상

## 파일 위치

```
src/
  domain/
    user/
      user-service.ts
      user-service.test.ts    ← 소스 파일과 같은 디렉터리 (권장)
  tests/
    arch/
      dependencies.test.ts    ← 아키텍처 규칙 자동 검증
```

## 테스트 구조 (Arrange–Act–Assert)

```typescript
import { describe, it, expect, beforeEach } from 'vitest'
import { UserService } from './user-service'

describe('UserService', () => {
  let service: UserService

  beforeEach(() => {
    service = new UserService()
  })

  describe('findById', () => {
    it('존재하는 사용자 ID로 조회 시 사용자를 반환한다', async () => {
      // Arrange
      const userId = 'user-1'

      // Act
      const result = await service.findById(userId)

      // Assert
      expect(result).not.toBeNull()
      expect(result?.id).toBe(userId)
    })

    it('존재하지 않는 ID로 조회 시 null을 반환한다', async () => {
      const result = await service.findById('nonexistent')
      expect(result).toBeNull()
    })
  })

  describe('create', () => {
    it('이메일 형식이 올바르지 않으면 ValidationError를 던진다', async () => {
      await expect(service.create({ email: 'invalid' })).rejects.toThrow('ValidationError')
    })
  })
})
```

## 명명 규칙

- `describe` 블록: 테스트 대상 클래스 또는 함수명 (영문)
- `it` 블록: 동작 설명 (한국어, "~하면 ~한다" 형식)

## 주의사항

- `it.only` / `describe.only`는 로컬 디버깅 전용 — 커밋 금지
- 구현 세부 사항(내부 메서드, 프라이빗 변수)을 직접 테스트하지 않음
- 테스트 간 상태 공유 금지 — `beforeEach`로 초기화

## 실행 명령어

```bash
pnpm test              # 전체 테스트 1회 실행
pnpm test:watch        # 파일 변경 시 자동 재실행
pnpm test:coverage     # 커버리지 리포트 생성 (coverage/ 디렉터리)
```

## 아키텍처 테스트

`src/tests/arch/dependencies.test.ts`는 모든 소스 파일의 레이어 의존성을 자동 검증합니다.
소스 파일 추가 후 `pnpm test`를 실행하면 의존성 위반을 즉시 탐지합니다.
