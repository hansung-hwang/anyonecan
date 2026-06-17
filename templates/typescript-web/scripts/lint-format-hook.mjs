import { execSync } from 'child_process'

// PostToolUse Hook: Write/Edit 후 ESLint --fix 및 Prettier --write 자동 실행
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
    // 포맷 오류는 에이전트 작업 흐름을 중단시키지 않음
  }
})
