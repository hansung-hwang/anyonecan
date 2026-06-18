import { execSync } from 'child_process'

let data = ''
process.stdin.setEncoding('utf8')
process.stdin.on('data', (chunk) => { data += chunk })
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(data)
    const filePath = input?.tool_input?.file_path
    if (!filePath || !/\.tsx?$/.test(filePath)) return
    execSync(`npx eslint --fix "${filePath}"`, { stdio: 'pipe' })
    execSync(`npx prettier --write "${filePath}"`, { stdio: 'pipe' })
  } catch { /* 포맷 오류는 작업 흐름 중단 안 함 */ }
})
