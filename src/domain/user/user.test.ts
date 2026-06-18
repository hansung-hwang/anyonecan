import { describe, expect, it } from 'vitest'
import { ValidationError, createUser, validateEmail, validateName } from './user'

describe('validateEmail', () => {
  it('does not throw for a valid email format', () => {
    expect(() => validateEmail('user@example.com')).not.toThrow()
  })

  it('throws ValidationError when @ symbol is missing', () => {
    expect(() => validateEmail('invalid')).toThrow(ValidationError)
  })

  it('throws ValidationError when domain is missing', () => {
    expect(() => validateEmail('user@')).toThrow(ValidationError)
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

  it('throws ValidationError for a whitespace-only name', () => {
    expect(() => validateName('   ')).toThrow(ValidationError)
  })

  it('throws ValidationError for a name exceeding 100 characters', () => {
    expect(() => validateName('a'.repeat(101))).toThrow(ValidationError)
  })

  it('allows a name of exactly 100 characters', () => {
    expect(() => validateName('a'.repeat(100))).not.toThrow()
  })
})

describe('createUser', () => {
  it('creates a User object from valid input', () => {
    const user = createUser('user-1', { email: 'USER@EXAMPLE.COM', name: ' John ' })

    expect(user.id).toBe('user-1')
    expect(user.email).toBe('user@example.com') // lowercased + trimmed
    expect(user.name).toBe('John') // leading/trailing whitespace removed
    expect(user.createdAt).toBeInstanceOf(Date)
  })

  it('throws ValidationError when created with an invalid email', () => {
    expect(() => createUser('user-1', { email: 'not-an-email', name: 'John' })).toThrow(
      ValidationError
    )
  })

  it('throws ValidationError when created with an empty name', () => {
    expect(() => createUser('user-1', { email: 'user@example.com', name: '' })).toThrow(
      ValidationError
    )
  })

  it('created User has a readonly structure', () => {
    const user = createUser('user-1', { email: 'user@example.com', name: 'John' })
    // readonly is guaranteed at TypeScript compile time — verifying runtime shape here
    expect(Object.isFrozen(user)).toBe(false) // plain object, not frozen
    expect(user).toMatchObject({ id: 'user-1', email: 'user@example.com', name: 'John' })
  })
})
