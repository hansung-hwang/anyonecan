import { describe, expect, it } from 'vitest'
import { ValidationError, createUser, validateEmail, validateName } from './user'

describe('validateEmail', () => {
  it('does not throw for a valid email format', () => {
    expect(() => validateEmail('user@example.com')).not.toThrow()
  })
  it('throws ValidationError when @ symbol is missing', () => {
    expect(() => validateEmail('invalid')).toThrow(ValidationError)
  })
  it('throws ValidationError when email contains whitespace', () => {
    expect(() => validateEmail('user @example.com')).toThrow(ValidationError)
  })
})

describe('validateName', () => {
  it('does not throw for a valid name', () => {
    expect(() => validateName('John')).not.toThrow()
  })
  it('throws ValidationError for an empty string', () => {
    expect(() => validateName('')).toThrow(ValidationError)
  })
  it('throws ValidationError for a name exceeding 100 characters', () => {
    expect(() => validateName('a'.repeat(101))).toThrow(ValidationError)
  })
})

describe('createUser', () => {
  it('creates a User object from valid input', () => {
    const user = createUser('user-1', { email: 'USER@EXAMPLE.COM', name: ' John ' })
    expect(user.email).toBe('user@example.com')
    expect(user.name).toBe('John')
    expect(user.createdAt).toBeInstanceOf(Date)
  })
  it('throws ValidationError when created with an invalid email', () => {
    expect(() => createUser('user-1', { email: 'bad', name: 'John' })).toThrow(ValidationError)
  })
})
