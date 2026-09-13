import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { cpSync, mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')

function runFixture(mutate) {
  const temporaryRoot = resolve(tmpdir())
  const fixture = mkdtempSync(join(temporaryRoot, 'harness-instructions-'))
  try {
    for (const rel of [
      'AGENTS.md', 'CLAUDE.md', '.claude/commands', '.agents/skills',
      'harness-core/AGENTS.md', 'harness-core/CLAUDE.md',
      'harness-core/.claude/commands', 'harness-core/.agents/skills', 'harness-core/harness-manifest.json',
      'harness-core/docs/how-to/file-ownership.md',
    ]) {
      const destination = join(fixture, rel)
      mkdirSync(dirname(destination), { recursive: true })
      cpSync(join(root, rel), destination, { recursive: true })
    }
    mutate(fixture)
    const result = spawnSync(process.execPath, [join(root, 'scripts/check-sync.mjs')], {
      cwd: fixture, encoding: 'utf-8',
    })
    assert.ifError(result.error)
    return result
  } finally {
    // Cleanup is confined to the one disposable fixture, never a repository path.
    assert.equal(dirname(resolve(fixture)), temporaryRoot)
    assert.ok(fixture.startsWith(join(temporaryRoot, 'harness-instructions-')))
    rmSync(fixture, { recursive: true, force: true })
  }
}

function append(fixture, rel, text) {
  const file = join(fixture, rel)
  writeFileSync(file, readFileSync(file, 'utf-8') + '\n' + text)
}

test('valid workflow references and tool-specific CLAUDE pointers pass', () => {
  const result = runFixture(() => {})
  assert.equal(result.status, 0, result.stderr)
})

for (const [name, rel, violation] of [
  ['root ADR rule edit', '.claude/commands/adr.md', 'Add a reference to CLAUDE.md.'],
  ['template ADR dual edit', 'harness-core/.claude/commands/adr.md',
    'If needed, add a `(-> docs/adr/001)` link to the architecture section of `CLAUDE.md` and `AGENTS.md`.'],
  ['skill self-import', '.agents/skills/source-command-done/SKILL.md', '`AGENTS.md` imports it.'],
  ['skill duplicate rules', '.agents/skills/source-command-start/SKILL.md', 'Read `AGENTS.md` and `AGENTS.md`.'],
  ['skill invented config', '.agents/skills/source-command-team/SKILL.md', 'Edit `.Codex/settings.json`.'],
  ['embedded command copy', '.agents/skills/source-command-plan/SKILL.md', '# /plan — copied procedure'],
]) {
  test(`rejects ${name}`, () => {
    const result = runFixture((fixture) => append(fixture, rel, violation))
    assert.equal(result.status, 1, result.stdout)
    assert.ok(result.stderr.includes(rel), result.stderr)
  })
}

test('a skill pointing at the wrong workflow fails', () => {
  const result = runFixture((fixture) => {
    const file = join(fixture, '.agents/skills/source-command-review/SKILL.md')
    writeFileSync(file, readFileSync(file, 'utf-8').replace('/review.md', '/plan.md'))
  })
  assert.equal(result.status, 1, result.stdout)
  assert.match(result.stderr, /must reference existing/)
})

test('broken supporting links fail', () => {
  const result = runFixture((fixture) => append(fixture,
    '.agents/skills/source-command-review/SKILL.md', '[Missing](missing.md)'))
  assert.equal(result.status, 1, result.stdout)
  assert.match(result.stderr, /broken reference/)
})
