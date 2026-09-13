import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join, resolve } from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import vm from 'node:vm'
import test from 'node:test'
import ts from 'typescript'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const localRequire = createRequire(join(root, 'package.json'))

function fixture(run) {
  const parent = resolve(tmpdir())
  const directory = mkdtempSync(join(parent, 'harness-contract-'))
  try { return run(directory) } finally {
    assert.equal(dirname(resolve(directory)), parent)
    assert.ok(directory.startsWith(join(parent, 'harness-contract-')))
    rmSync(directory, { recursive: true, force: true })
  }
}

function write(directory, file, content) {
  const target = join(directory, file)
  mkdirSync(dirname(target), { recursive: true })
  writeFileSync(target, content)
}

function architecture(directory, files, sourcePath) {
  write(directory, 'tsconfig.json', JSON.stringify({
    compilerOptions: { moduleResolution: 'bundler', module: 'ESNext', baseUrl: '.', paths: { '@/*': ['src/*'] } },
    include: ['src'],
  }))
  for (const [file, content] of Object.entries(files)) {
    write(directory, `src/${file}`, content)
    write(directory, `src/${file.replace(/(\.tsx?)$/, '.test$1')}`, '')
  }
  const failures = []
  const expect = (actual) => ({
    toHaveLength: (length) => assert.equal(actual.length, length),
    toBeGreaterThan: (number) => assert.ok(actual > number),
  })
  expect.fail = (message) => { throw new Error(message) }
  const vitest = {
    expect,
    describe: (_name, body) => body(),
    it: (name, body) => { try { body() } catch (error) { failures.push({ name, message: error.message }) } },
  }
  const code = ts.transpileModule(readFileSync(join(root, sourcePath), 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022, esModuleInterop: true },
  }).outputText
  vm.runInNewContext(code, {
    exports: {}, process: { cwd: () => directory },
    require: (name) => name === 'vitest' ? vitest : localRequire(name),
  })
  return failures
}

for (const sourcePath of ['src/tests/arch/dependencies.test.ts',
  'language-packs/typescript/src/tests/arch/dependencies.test.ts']) {
  test(`${sourcePath}: allowed domain alias and node builtins pass`, () => fixture((directory) => {
    assert.deepEqual(architecture(directory, {
      'domain/a.ts': "import { value } from '@/domain/b'; import 'node:fs/promises';",
      'domain/b.ts': 'export const value = 1',
    }, sourcePath), [])
  }))
  for (const statement of ["import '@/infrastructure/b'", "import('@/infrastructure/b')",
    "export * from '@/infrastructure/b'", "const b = require('@/infrastructure/b')"]) {
    test(`${sourcePath}: rejects upper layer via ${statement}`, () => fixture((directory) => {
      const failures = architecture(directory, {
        'application/a.tsx': statement, 'infrastructure/b.ts': 'export const value = 1',
      }, sourcePath)
      assert.ok(failures.some((failure) => failure.name === 'no layer imports from a higher layer'))
    }))
  }
  for (const statement of ["import 'external'", "import('external')"]) {
    test(`${sourcePath}: rejects external ${statement}`, () => fixture((directory) => {
      assert.ok(architecture(directory, { 'domain/a.ts': statement }, sourcePath)
        .some((failure) => failure.name === 'domain layer does not import external libraries'))
    }))
  }
  test(`${sourcePath}: resolves js suffix cycles`, () => fixture((directory) => {
    assert.ok(architecture(directory, {
      'domain/a.ts': "export * from './b.js'", 'domain/b.ts': "export * from './a.js'",
    }, sourcePath).some((failure) => failure.name === 'no circular references within the same layer'))
  }))
}

for (const hook of ['scripts/lint-format-hook.mjs', 'language-packs/typescript/scripts/lint-format-hook.mjs']) {
  test(`${hook}: shell characters are literal arguments`, () => fixture((directory) => {
    write(directory, 'package.json', '{}')
    for (const name of ['eslint', 'prettier']) {
      write(directory, `node_modules/${name}/package.json`, JSON.stringify({ name, bin: 'cli.cjs' }))
      write(directory, `node_modules/${name}/cli.cjs`,
        "require('node:fs').appendFileSync('calls.jsonl', JSON.stringify(process.argv.slice(2)) + '\\n')")
    }
    for (const name of ['a space.ts', '한글.ts', '$(echo injected).ts', 'a"quote.ts']) {
      const file = join(directory, name)
      const result = spawnSync(process.execPath, [join(root, hook)], {
        cwd: directory, encoding: 'utf8', input: JSON.stringify({ tool_input: { file_path: file } }),
      })
      assert.equal(result.status, 0, result.stderr)
      assert.equal(result.stderr, '')
      const calls = readFileSync(join(directory, 'calls.jsonl'), 'utf8').trim().split('\n').map(JSON.parse)
      assert.deepEqual(calls.slice(-2), [['--fix', '--', file], ['--write', '--', file]])
    }
    const before = readFileSync(join(directory, 'calls.jsonl'), 'utf8')
    write(directory, '.harnessignore', 'vendor\n')
    spawnSync(process.execPath, [join(root, hook)], {
      cwd: directory, input: JSON.stringify({ tool_input: { file_path: join(directory, 'vendor/a.ts') } }),
    })
    assert.equal(readFileSync(join(directory, 'calls.jsonl'), 'utf8'), before)
  }))
}
