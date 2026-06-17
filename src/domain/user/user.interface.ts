import type { CreateUserInput, User, UserId } from './user.types'

export interface UserRepository {
  findById(id: UserId): Promise<User | null>
  findByEmail(email: string): Promise<User | null>
  save(user: User): Promise<void>
  delete(id: UserId): Promise<void>
}

export interface UserFactory {
  create(id: UserId, input: CreateUserInput): User
}
