import { describe, expect, it } from 'vitest'
import { ValidationError, createUser, validateEmail, validateName } from './user'

describe('validateEmail', () => {
  it('유효한 이메일 형식이면 예외를 던지지 않는다', () => {
    expect(() => validateEmail('user@example.com')).not.toThrow()
  })

  it('@ 기호가 없으면 ValidationError를 던진다', () => {
    expect(() => validateEmail('invalid')).toThrow(ValidationError)
  })

  it('도메인이 없는 이메일이면 ValidationError를 던진다', () => {
    expect(() => validateEmail('user@')).toThrow(ValidationError)
  })

  it('공백이 포함된 이메일이면 ValidationError를 던진다', () => {
    expect(() => validateEmail('user @example.com')).toThrow(ValidationError)
  })
})

describe('validateName', () => {
  it('유효한 이름이면 예외를 던지지 않는다', () => {
    expect(() => validateName('홍길동')).not.toThrow()
  })

  it('빈 문자열이면 ValidationError를 던진다', () => {
    expect(() => validateName('')).toThrow(ValidationError)
  })

  it('공백만 있는 이름이면 ValidationError를 던진다', () => {
    expect(() => validateName('   ')).toThrow(ValidationError)
  })

  it('100자를 초과하는 이름이면 ValidationError를 던진다', () => {
    expect(() => validateName('가'.repeat(101))).toThrow(ValidationError)
  })

  it('정확히 100자인 이름은 허용한다', () => {
    expect(() => validateName('가'.repeat(100))).not.toThrow()
  })
})

describe('createUser', () => {
  it('유효한 입력으로 User 객체를 생성한다', () => {
    const user = createUser('user-1', { email: 'USER@EXAMPLE.COM', name: ' 홍길동 ' })

    expect(user.id).toBe('user-1')
    expect(user.email).toBe('user@example.com') // 소문자 변환 + 공백 제거
    expect(user.name).toBe('홍길동') // 앞뒤 공백 제거
    expect(user.createdAt).toBeInstanceOf(Date)
  })

  it('잘못된 이메일로 생성하면 ValidationError를 던진다', () => {
    expect(() => createUser('user-1', { email: 'not-an-email', name: '홍길동' })).toThrow(
      ValidationError
    )
  })

  it('빈 이름으로 생성하면 ValidationError를 던진다', () => {
    expect(() => createUser('user-1', { email: 'user@example.com', name: '' })).toThrow(
      ValidationError
    )
  })

  it('생성된 User는 readonly 구조를 가진다', () => {
    const user = createUser('user-1', { email: 'user@example.com', name: '홍길동' })
    // TypeScript 컴파일 타임에 readonly 보장 — 런타임 구조 확인
    expect(Object.isFrozen(user)).toBe(false) // plain object이므로 freeze는 아님
    expect(user).toMatchObject({ id: 'user-1', email: 'user@example.com', name: '홍길동' })
  })
})
