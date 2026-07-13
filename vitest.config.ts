import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    include: ['src/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      // Scoped to domain (AGENTS.md: "domain layer target: 80% or above") --
      // not the whole src tree, so app/infra/presentation aren't force-gated.
      include: ['src/domain/**/*.ts'],
      exclude: ['src/**/*.test.ts', 'src/**/*.types.ts', 'src/**/*.interface.ts', 'src/tests/**'],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
      reporter: ['text', 'html', 'lcov'],
    },
  },
})
