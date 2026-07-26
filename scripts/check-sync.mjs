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

// 3. Manifest-registration guard: every harness-core command and docs/how-to
// guide must be listed in harness-manifest.json's frameworkOwned, or upgrade
// silently never delivers it to existing generated projects (finding E from
// the 2026-07-22 multi-agent-coordination plan -- nothing else catches this).
const manifestPath = join(ROOT, 'harness-core/harness-manifest.json')
const manifest = JSON.parse(readFileSync(manifestPath, 'utf-8'))
const frameworkOwned = new Set(manifest.frameworkOwned)

const commandsDir = join(ROOT, 'harness-core/.claude/commands')
for (const f of readdirSync(commandsDir)) {
  const rel = `.claude/commands/${f}`
  if (!frameworkOwned.has(rel)) {
    console.error(`✗ harness-core/${rel} is not registered in harness-manifest.json's frameworkOwned`)
    failed = true
  }
}

const howToDir = join(ROOT, 'harness-core/docs/how-to')
if (existsSync(howToDir)) {
  for (const f of readdirSync(howToDir)) {
    const rel = `docs/how-to/${f}`
    if (!frameworkOwned.has(rel)) {
      console.error(`✗ harness-core/${rel} is not registered in harness-manifest.json's frameworkOwned`)
      failed = true
    }
  }
}

// 4. File-ownership guard: harness-core/docs/how-to/file-ownership.md's
// Framework-tier list (between its <!-- framework-tier:start/end --> markers)
// must exactly match harness-manifest.json's frameworkOwned + every
// language's languageSpecific paths, in both directions -- otherwise the
// ownership doc silently drifts from what upgrade actually does, which is
// the exact failure mode this whole guide exists to prevent (see
// .workspace/plans/2026-07-25-file-ownership-rules.md, D4/Gate O0).
const ownershipPath = join(ROOT, 'harness-core/docs/how-to/file-ownership.md')
if (existsSync(ownershipPath)) {
  const ownershipContent = readFileSync(ownershipPath, 'utf-8')
  const tierMatch = ownershipContent.match(
    /<!-- framework-tier:start -->([\s\S]*?)<!-- framework-tier:end -->/,
  )
  if (!tierMatch) {
    console.error(`✗ ${ownershipPath} is missing its <!-- framework-tier:start/end --> markers`)
    failed = true
  } else {
    const docPaths = new Set([...tierMatch[1].matchAll(/`([^`]+)`/g)].map((m) => m[1]))

    const manifestPaths = new Set(manifest.frameworkOwned)
    for (const paths of Object.values(manifest.languageSpecific ?? {})) {
      for (const p of paths) manifestPaths.add(p)
    }

    for (const p of manifestPaths) {
      if (!docPaths.has(p)) {
        console.error(`✗ file-ownership.md's Framework tier is missing manifest path: ${p}`)
        failed = true
      }
    }
    for (const p of docPaths) {
      if (!manifestPaths.has(p)) {
        console.error(`✗ file-ownership.md's Framework tier lists a path absent from the manifest: ${p}`)
        failed = true
      }
    }
  }
}

if (failed) {
  console.error('\ncheck-sync failed.')
  process.exit(1)
}

console.log(
  '✓ check-sync passed (command parity + no stale dual-edit instructions + manifest registration + file-ownership sync)',
)
