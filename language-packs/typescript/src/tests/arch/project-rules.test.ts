// Project-specific architecture rules.
//
// `dependencies.test.ts` in this directory is framework-owned -- `upgrade`
// overwrites it when the shared 5-check parity matrix improves. This file is
// never touched by upgrade (seeded once, then yours), so it's the right
// place for a project-specific invariant an architecture test can enforce --
// e.g. "module X must not be imported at top level" or "layer Y must not
// depend on package Z". Add one `it(...)` per invariant as they come up;
// there being nothing here yet is the expected starting state.
import { describe, expect, it } from 'vitest'

describe('project rules', () => {
  it('keeps vitest from erroring on an empty suite; replace as rules are added', () => {
    expect(true).toBe(true)
  })
})
