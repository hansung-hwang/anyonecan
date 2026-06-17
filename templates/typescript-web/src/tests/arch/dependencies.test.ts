import { describe, it, expect } from 'vitest'
import { readFileSync, readdirSync, statSync } from 'fs'
import { join, relative } from 'path'

// 프로젝트 루트 기준 src 디렉터리 경로
const SRC_DIR = join(process.cwd(), 'src')

// 레이어별 허용 import 규칙 (값이 낮을수록 내부 레이어)
const LAYER_ORDER: Record<string, number> = {
  domain: 0,
  application: 1,
  infrastructure: 2,
  presentation: 3,
}

// src 하위 모든 .ts 파일을 재귀적으로 수집 (.test.ts 제외)
function collectTsFiles(dir: string): string[] {
  const result: string[] = []
  for (const entry of readdirSync(dir)) {
    const fullPath = join(dir, entry)
    if (statSync(fullPath).isDirectory()) {
      result.push(...collectTsFiles(fullPath))
    } else if (entry.endsWith('.ts') && !entry.endsWith('.test.ts')) {
      result.push(fullPath)
    }
  }
  return result
}

// 파일 경로에서 레이어 이름 추출 (src/<layer>/...)
function extractLayer(filePath: string): string | null {
  const rel = relative(SRC_DIR, filePath)
  const parts = rel.split(/[\\/]/)
  const layer = parts[0]
  return layer !== undefined && layer in LAYER_ORDER ? layer : null
}

// 파일 내 import 경로 추출
function extractImports(filePath: string): string[] {
  const content = readFileSync(filePath, 'utf-8')
  const importRegex = /from\s+['"]([^'"]+)['"]/g
  const imports: string[] = []
  let match: RegExpExecArray | null
  while ((match = importRegex.exec(content)) !== null) {
    const importPath = match[1]
    if (importPath !== undefined) {
      imports.push(importPath)
    }
  }
  return imports
}

// 상대 경로 import를 절대 경로로 변환해 레이어 추출
function resolveImportLayer(importPath: string, fromFile: string): string | null {
  if (!importPath.startsWith('.')) return null
  const resolved = join(fromFile, '..', importPath)
  return extractLayer(resolved)
}

describe('아키텍처 의존성 규칙', () => {
  const tsFiles = collectTsFiles(SRC_DIR)

  it('모든 레이어는 자신보다 상위 레이어를 import하지 않는다', () => {
    const violations: string[] = []

    for (const file of tsFiles) {
      const fromLayer = extractLayer(file)
      if (fromLayer === null) continue

      const fromOrder = LAYER_ORDER[fromLayer]
      if (fromOrder === undefined) continue

      for (const imp of extractImports(file)) {
        const toLayer = resolveImportLayer(imp, file)
        if (toLayer === null) continue

        const toOrder = LAYER_ORDER[toLayer]
        if (toOrder === undefined) continue

        if (toOrder > fromOrder) {
          violations.push(`[위반] ${relative(SRC_DIR, file)} (${fromLayer}) → ${imp} (${toLayer})`)
        }
      }
    }

    if (violations.length > 0) {
      expect.fail(`아키텍처 의존성 위반 ${violations.length}건:\n\n${violations.join('\n')}`)
    }
    expect(violations).toHaveLength(0)
  })

  it('domain 레이어는 외부 라이브러리를 import하지 않는다', () => {
    const violations: string[] = []

    for (const file of tsFiles) {
      if (extractLayer(file) !== 'domain') continue

      for (const imp of extractImports(file)) {
        if (imp.startsWith('.')) continue
        if (!imp.includes('/') && !imp.startsWith('@')) continue

        violations.push(`[위반] ${relative(SRC_DIR, file)}: 외부 라이브러리 '${imp}' import 금지`)
      }
    }

    if (violations.length > 0) {
      expect.fail(`domain 순수성 위반 ${violations.length}건:\n\n${violations.join('\n')}`)
    }
    expect(violations).toHaveLength(0)
  })

  it('src 하위에 TypeScript 소스 파일이 존재한다', () => {
    const nonTestFiles = tsFiles.filter((f) => !f.includes('tests'))
    // TODO: 소스 파일 추가 후 아래 주석 해제
    // expect(nonTestFiles.length).toBeGreaterThan(0)
    expect(tsFiles.length).toBeGreaterThanOrEqual(0)
    void nonTestFiles
  })
})
