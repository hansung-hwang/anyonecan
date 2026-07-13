#!/usr/bin/env node
// Guards the P1 "AGENTS.md is the single rule source" invariant.
//
// Root (framework dev copy) and harness-core (project template) intentionally
// diverge in wording — root has concrete TypeScript/pnpm examples,
// harness-core stays language-agnostic. What must NOT diverge:
//   1. The set of workflow commands available in both copies
//   2. Instructions telling an agent to edit CLAUDE.md and AGENTS.md
//      together — that phrasing is exactly the pre-P1 bug this script
//      exists to catch if it ever creeps back in (e.g. a careless /fix edit).
import { readdirSync, readFileSync, existsSync } from 'node:fs'
import { join } from 'node:path'

const ROOT = process.cwd()
const PAIRS = [[join(ROOT, '.claude/commands'), join(ROOT, 'harness-core/.claude/commands')]]

const STALE_PATTERNS = [
  /keep both in sync/i,
  /CLAUDE\.md\s*\+\s*`?AGENTS\.md/i,
  /AGENTS\.md\s*\+\s*`?CLAUDE\.md/i,
  /sync addition to `?CLAUDE\.md/i,
  /update `?CLAUDE\.md`? \+ `?AGENTS\.md`? together/i,
]

const SCAN_FILES = [
  'AGENTS.md',
  'CLAUDE.md',
  'harness-core/AGENTS.md',
  'harness-core/CLAUDE.md',
  ...readdirSync(join(ROOT, '.claude/commands')).map((f) => `.claude/commands/${f}`),
  ...readdirSync(join(ROOT, 'harness-core/.claude/commands')).map(
    (f) => `harness-core/.claude/commands/${f}`,
  ),
]

let failed = false

// 1. Command file-list parity
for (const [a, b] of PAIRS) {
  const filesA = new Set(readdirSync(a))
  const filesB = new Set(readdirSync(b))
  for (const f of filesA) {
    if (!filesB.has(f)) {
      console.error(`✗ ${b} is missing ${f} (present in ${a})`)
      failed = true
    }
  }
  for (const f of filesB) {
    if (!filesA.has(f)) {
      console.error(`✗ ${a} is missing ${f} (present in ${b})`)
      failed = true
    }
  }
}

// 2. Stale dual-edit instruction check
for (const rel of SCAN_FILES) {
  const fp = join(ROOT, rel)
  if (!existsSync(fp)) continue
  const content = readFileSync(fp, 'utf-8')
  for (const pattern of STALE_PATTERNS) {
    if (pattern.test(content)) {
      console.error(`✗ ${rel} contains a stale dual-edit instruction (matches ${pattern})`)
      console.error(`  AGENTS.md is the single rule source — CLAUDE.md imports it.`)
      failed = true
    }
  }
}

if (failed) {
  console.error('\ncheck-sync failed.')
  process.exit(1)
}

console.log('✓ check-sync passed (command parity + no stale dual-edit instructions)')
