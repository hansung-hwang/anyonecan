import type { CreateUserInput, User, UserId } from './user.types'

// RFC 5322 간소화 버전 — 서버 측 정밀 검증과 병행 사용 전제
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

export class ValidationError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'ValidationError'
  }
}

export function validateEmail(email: string): void {
  if (!EMAIL_REGEX.test(email)) {
    throw new ValidationError(`유효하지 않은 이메일 형식: ${email}`)
  }
}

export function validateName(name: string): void {
  const trimmed = name.trim()
  if (trimmed.length === 0) throw new ValidationError('이름은 빈 값일 수 없습니다')
  if (trimmed.length > 100) throw new ValidationError('이름은 100자를 초과할 수 없습니다')
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
