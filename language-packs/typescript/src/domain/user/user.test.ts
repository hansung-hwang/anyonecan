import { describe, expect, it } from 'vitest'
import { ValidationError, createUser, validateEmail, validateName } from './user'

describe('validateEmail', () => {
  it('유효한 이메일 형식이면 예외를 던지지 않는다', () => {
    expect(() => validateEmail('user@example.com')).not.toThrow()
  })
  it('@ 기호가 없으면 ValidationError를 던진다', () => {
    expect(() => validateEmail('invalid')).toThrow(ValidationError)
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
  it('100자를 초과하는 이름이면 ValidationError를 던진다', () => {
    expect(() => validateName('가'.repeat(101))).toThrow(ValidationError)
  })
})

describe('createUser', () => {
  it('유효한 입력으로 User 객체를 생성한다', () => {
    const user = createUser('user-1', { email: 'USER@EXAMPLE.COM', name: ' 홍길동 ' })
    expect(user.email).toBe('user@example.com')
    expect(user.name).toBe('홍길동')
    expect(user.createdAt).toBeInstanceOf(Date)
  })
  it('잘못된 이메일로 생성하면 ValidationError를 던진다', () => {
    expect(() => createUser('user-1', { email: 'bad', name: '홍길동' })).toThrow(ValidationError)
  })
})
