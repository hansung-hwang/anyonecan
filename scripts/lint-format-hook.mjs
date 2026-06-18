import { execSync } from 'child_process'

// PostToolUse hook: run ESLint --fix and Prettier --write after Write/Edit
let data = ''
process.stdin.setEncoding('utf8')
process.stdin.on('data', (chunk) => {
  data += chunk
})
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(data)
    const filePath = input?.tool_input?.file_path
    if (!filePath || !/\.tsx?$/.test(filePath)) return

    execSync(`npx eslint --fix "${filePath}"`, { stdio: 'pipe' })
    execSync(`npx prettier --write "${filePath}"`, { stdio: 'pipe' })
  } catch {
    // Formatting errors must not interrupt the agent's workflow
  }
})
