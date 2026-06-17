# 컴포넌트(모듈) 작성 가이드

## 파일 네이밍 규칙

| 종류 | 규칙 | 예시 |
|------|------|------|
| 소스 파일 | `kebab-case.ts` | `user-service.ts` |
| React 컴포넌트 | `PascalCase.tsx` | `UserCard.tsx` |
| 테스트 파일 | `[원본파일명].test.ts(x)` | `UserCard.test.tsx` |
| 타입 정의 | `kebab-case.types.ts` | `user.types.ts` |
| 인터페이스 | `kebab-case.interface.ts` | `user.interface.ts` |
| 훅 | `use-kebab-case.ts` | `use-user.ts` |

## Props 타입 정의

props 타입은 항상 명시적으로 정의하고 컴포넌트 파일 상단에 위치시킵니다.

```typescript
// UserCard.tsx

// Props 타입은 interface 또는 type으로 정의 (선택: 확장 가능성 있으면 interface)
interface UserCardProps {
  readonly userId: string
  readonly name: string
  readonly email: string
  readonly onSelect?: (userId: string) => void  // 선택적 핸들러
}

export function UserCard({ userId, name, email, onSelect }: UserCardProps): JSX.Element {
  return (
    <div onClick={() => onSelect?.(userId)}>
      <h2>{name}</h2>
      <p>{email}</p>
    </div>
  )
}
```

## 컴포넌트 작성 원칙

### 1. 함수형 컴포넌트 전용
클래스형 컴포넌트 사용 금지. 함수형 + 훅 패턴을 사용합니다.

### 2. 반환 타입 명시
```typescript
// 잘못된 예 — 반환 타입 미명시
function Button({ label }: ButtonProps) {
  return <button>{label}</button>
}

// 올바른 예
function Button({ label }: ButtonProps): JSX.Element {
  return <button>{label}</button>
}
```

### 3. 커스텀 훅으로 로직 분리
비즈니스 로직은 커스텀 훅으로 분리합니다.

```typescript
// use-user.ts
export function useUser(userId: string): { user: User | null; isLoading: boolean } {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    void fetchUser(userId).then((data) => {
      setUser(data)
      setIsLoading(false)
    })
  }, [userId])

  return { user, isLoading }
}

// UserCard.tsx — 표시만 담당
export function UserCard({ userId }: { userId: string }): JSX.Element {
  const { user, isLoading } = useUser(userId)
  if (isLoading) return <Spinner />
  if (!user) return <EmptyState />
  return <div>{user.name}</div>
}
```

### 4. `any` 금지
```typescript
// 잘못된 예
function handleEvent(e: any): void { ... }

// 올바른 예
function handleEvent(e: React.MouseEvent<HTMLButtonElement>): void { ... }
```

## 아키텍처 레이어별 역할

| 레이어 | 위치 | 역할 |
|--------|------|------|
| `domain` | `src/domain/` | 엔티티, 비즈니스 로직, 인터페이스 (외부 라이브러리 금지) |
| `application` | `src/application/` | 유즈케이스, 훅, 서비스 로직 |
| `infrastructure` | `src/infrastructure/` | API 호출, DB, 외부 연동 구현체 |
| `presentation` | `src/presentation/` | React 컴포넌트, 페이지 |

## 파일 내 구성 순서

```typescript
// 1. 외부 라이브러리 import
import { useState } from 'react'

// 2. 내부 import (레이어 순서: domain → application → infrastructure → presentation)
import type { User } from '@/domain/user/user.types'
import { useUser } from '@/application/hooks/use-user'

// 3. 타입/인터페이스 정의
interface ComponentProps { ... }

// 4. 컴포넌트 구현
export function Component({ ... }: ComponentProps): JSX.Element { ... }
```
