import type { CreateUserInput, User, UserId } from './user.types'

// Simplified RFC 5322 — intended to run alongside server-side precision validation
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

export class ValidationError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'ValidationError'
  }
}

export function validateEmail(email: string): void {
  if (!EMAIL_REGEX.test(email)) {
    throw new ValidationError(`Invalid email format: ${email}`)
  }
}

export function validateName(name: string): void {
  const trimmed = name.trim()
  if (trimmed.length === 0) {
    throw new ValidationError('Name cannot be empty')
  }
  if (trimmed.length > 100) {
    throw new ValidationError('Name cannot exceed 100 characters')
  }
}

export function createUser(id: UserId, input: CreateUserInput): User {
  validateEmail(input.email)
  validateName(input.name)

  return {
    id,
    email: input.email.toLowerCase().trim(),
    name: input.name.trim(),
    createdAt: new Date(),
  }
}
