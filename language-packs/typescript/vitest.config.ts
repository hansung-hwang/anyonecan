import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: false,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov'],
      // Scoped to domain (AGENTS.md: "domain layer target: 80% or above") --
      // not the whole src tree, so app/infra/presentation aren't force-gated.
      include: ['src/domain/**/*.ts'],
      exclude: ['src/**/*.test.ts', 'src/**/*.types.ts', 'src/**/*.interface.ts'],
      thresholds: { lines: 80, functions: 80 },
    },
  },
})
