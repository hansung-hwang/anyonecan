import { spawnSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { createRequire } from 'node:module'
import { dirname, join, resolve } from 'node:path'

const root = process.cwd()
const localRequire = createRequire(join(root, 'package.json'))
function run(command, args) {
  const result = spawnSync(command, args, { cwd: root, stdio: 'inherit', shell: false })
  if (result.error) console.error(result.error.message)
  if (result.error || result.status !== 0) process.exit(result.status ?? 1)
}
function cli(packageName, executable, args) {
  const manifestPath = localRequire.resolve(`${packageName}/package.json`)
  const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'))
  const bin = typeof manifest.bin === 'string' ? manifest.bin : manifest.bin[executable]
  run(process.execPath, [resolve(dirname(manifestPath), bin), ...args])
}
cli('typescript', 'tsc', ['--noEmit'])
cli('eslint', 'eslint', ['src', '--ext', '.ts,.tsx'])
cli('vitest', 'vitest', ['run'])
