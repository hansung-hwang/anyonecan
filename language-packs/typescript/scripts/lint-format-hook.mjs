import { spawnSync } from 'node:child_process'
import { existsSync, readFileSync } from 'node:fs'
import { createRequire } from 'node:module'
import { dirname, join, relative, resolve } from 'node:path'

const root = process.cwd()
const localRequire = createRequire(join(root, 'package.json'))

function isIgnored(filePath) {
  const ignoreFile = join(root, '.harnessignore')
  if (!existsSync(ignoreFile)) return false
  const rel = relative(root, filePath).split(/[\\/]/).join('/')
  return readFileSync(ignoreFile, 'utf8').split('\n').map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#')).some((pattern) =>
      pattern.includes('/') ? rel.includes(pattern) : rel.split('/').includes(pattern))
}

function runLocal(packageName, args) {
  const manifestPath = localRequire.resolve(`${packageName}/package.json`)
  const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'))
  const bin = typeof manifest.bin === 'string' ? manifest.bin : manifest.bin[packageName]
  const result = spawnSync(process.execPath, [resolve(dirname(manifestPath), bin), ...args], {
    cwd: root, encoding: 'utf8', shell: false,
  })
  if (result.error || result.status !== 0) {
    console.error(`[harness hook] ${packageName}: ${result.error?.message ?? result.stderr ?? 'failed'}`)
  }
}

let data = ''
process.stdin.setEncoding('utf8')
process.stdin.on('data', (chunk) => { data += chunk })
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(data)
    const filePath = input?.tool_input?.file_path
    if (typeof filePath !== 'string' || !/\.tsx?$/.test(filePath)) return
    const file = resolve(root, filePath)
    if (isIgnored(file)) return
    // Node runs local CLI files directly so shell metacharacters stay literal on every OS.
    runLocal('eslint', ['--fix', '--', file])
    runLocal('prettier', ['--write', '--', file])
  } catch (error) {
    console.error(`[harness hook] ${error instanceof Error ? error.message : 'invalid input'}`)
  }
})
