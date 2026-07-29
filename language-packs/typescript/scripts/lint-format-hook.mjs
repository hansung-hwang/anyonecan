import { execSync } from 'child_process'
import { existsSync, readFileSync } from 'fs'
import { join, relative } from 'path'

function loadHarnessignore() {
  const ignoreFile = join(process.cwd(), '.harnessignore')
  if (!existsSync(ignoreFile)) return []
  return readFileSync(ignoreFile, 'utf-8')
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line.length > 0 && !line.startsWith('#'))
}

function isIgnored(filePath, patterns) {
  const rel = relative(process.cwd(), filePath).split(/[\\/]/).join('/')
  return patterns.some((pattern) =>
    pattern.includes('/') ? rel.includes(pattern) : rel.split('/').includes(pattern),
  )
}

let data = ''
process.stdin.setEncoding('utf8')
process.stdin.on('data', (chunk) => { data += chunk })
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(data)
    const filePath = input?.tool_input?.file_path
    if (!filePath || !/\.tsx?$/.test(filePath)) return
    if (isIgnored(filePath, loadHarnessignore())) return
    execSync(`npx eslint --fix "${filePath}"`, { stdio: 'pipe' })
    execSync(`npx prettier --write "${filePath}"`, { stdio: 'pipe' })
  } catch { /* Formatting errors must not interrupt the workflow */ }
})
