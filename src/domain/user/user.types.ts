export type UserId = string

export interface User {
  readonly id: UserId
  readonly email: string
  readonly name: string
  readonly createdAt: Date
}

export interface CreateUserInput {
  readonly email: string
  readonly name: string
}
