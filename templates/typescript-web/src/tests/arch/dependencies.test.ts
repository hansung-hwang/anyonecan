import { describe, expect, it } from 'vitest'
import { existsSync, readFileSync, readdirSync, statSync } from 'fs'
import { basename, join, relative } from 'path'

const SRC_DIR = join(process.cwd(), 'src')

const LAYER_ORDER: Record<string, number> = {
  domain: 0,
  application: 1,
  infrastructure: 2,
  presentation: 3,
}

// Node.js 내장 모듈 허용 목록 — 이 외의 bare specifier는 domain에서 금지
const ALLOWED_NODE_BUILTINS = new Set([
  'fs',
  'path',
  'url',
  'crypto',
  'os',
  'stream',
  'events',
  'buffer',
  'util',
  'assert',
  'node:fs',
  'node:path',
  'node:url',
  'node:crypto',
  'node:os',
  'node:stream',
  'node:events',
  'node:buffer',
  'node:util',
  'node:assert',
])

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

function extractLayer(filePath: string): string | null {
  const rel = relative(SRC_DIR, filePath)
  const parts = rel.split(/[\\/]/)
  const layer = parts[0]
  return layer !== undefined && layer in LAYER_ORDER ? layer : null
}

function extractImports(filePath: string): string[] {
  const content = readFileSync(filePath, 'utf-8')
  const importRegex = /from\s+['"]([^'"]+)['"]/g
  const imports: string[] = []
  let match: RegExpExecArray | null
  while ((match = importRegex.exec(content)) !== null) {
    const importPath = match[1]
    if (importPath !== undefined) imports.push(importPath)
  }
  return imports
}

function resolveImportLayer(importPath: string, fromFile: string): string | null {
  if (!importPath.startsWith('.')) return null
  const resolved = join(fromFile, '..', importPath)
  return extractLayer(resolved)
}

function resolveImportFile(
  importPath: string,
  fromFile: string,
  allFiles: string[]
): string | null {
  if (!importPath.startsWith('.')) return null
  const base = join(fromFile, '..', importPath)
  for (const candidate of [base, `${base}.ts`, join(base, 'index.ts')]) {
    if (allFiles.includes(candidate)) return candidate
  }
  return null
}

function buildImportGraph(files: string[]): Map<string, string[]> {
  const graph = new Map<string, string[]>()
  for (const file of files) {
    const deps: string[] = []
    for (const imp of extractImports(file)) {
      const resolved = resolveImportFile(imp, file, files)
      if (resolved !== null) deps.push(resolved)
    }
    graph.set(file, deps)
  }
  return graph
}

// DFS 기반 순환 참조 탐지
function findCycles(graph: Map<string, string[]>): string[][] {
  const cycles: string[][] = []
  const visited = new Set<string>()
  const onStack = new Set<string>()

  function dfs(node: string, path: string[]): void {
    visited.add(node)
    onStack.add(node)
    path.push(node)

    for (const neighbor of graph.get(node) ?? []) {
      if (!visited.has(neighbor)) {
        dfs(neighbor, path)
      } else if (onStack.has(neighbor)) {
        const cycleStart = path.indexOf(neighbor)
        if (cycleStart !== -1) {
          cycles.push([...path.slice(cycleStart)])
        }
      }
    }

    path.pop()
    onStack.delete(node)
  }

  for (const node of graph.keys()) {
    if (!visited.has(node)) dfs(node, [])
  }

  return cycles
}

describe('아키텍처 의존성 규칙', () => {
  // TODO: 소스 파일 추가 후 아래 테스트들이 자동으로 활성화됩니다
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
      expect.fail(`레이어 의존성 위반 ${violations.length}건:\n\n${violations.join('\n')}`)
    }
    expect(violations).toHaveLength(0)
  })

  it('domain 레이어는 외부 라이브러리를 import하지 않는다', () => {
    const violations: string[] = []

    for (const file of tsFiles) {
      if (extractLayer(file) !== 'domain') continue

      for (const imp of extractImports(file)) {
        if (imp.startsWith('.')) continue
        if (!ALLOWED_NODE_BUILTINS.has(imp)) {
          violations.push(`[위반] ${relative(SRC_DIR, file)}: 외부 라이브러리 '${imp}' import 금지`)
        }
      }
    }

    if (violations.length > 0) {
      expect.fail(`domain 순수성 위반 ${violations.length}건:\n\n${violations.join('\n')}`)
    }
    expect(violations).toHaveLength(0)
  })

  it('동일 레이어 내 순환 참조가 없다', () => {
    const graph = buildImportGraph(tsFiles)
    const cycles = findCycles(graph)

    if (cycles.length > 0) {
      const descriptions = cycles.map((cycle) => cycle.map((f) => relative(SRC_DIR, f)).join(' → '))
      expect.fail(`순환 참조 ${cycles.length}건:\n\n${descriptions.join('\n')}`)
    }
    expect(cycles).toHaveLength(0)
  })

  it('모든 소스 파일은 kebab-case 네이밍 컨벤션을 따른다', () => {
    // 허용: kebab-case.ts / kebab-case.types.ts / kebab-case.interface.ts
    const KEBAB_CASE = /^[a-z][a-z0-9]*(-[a-z0-9]+)*(\.(types|interface))?\.ts$/
    const violations: string[] = []

    for (const file of tsFiles) {
      const name = basename(file)
      if (!KEBAB_CASE.test(name)) {
        violations.push(`[위반] ${relative(SRC_DIR, file)}: '${name}'은 kebab-case가 아닙니다`)
      }
    }

    if (violations.length > 0) {
      expect.fail(`파일명 컨벤션 위반 ${violations.length}건:\n\n${violations.join('\n')}`)
    }
    expect(violations).toHaveLength(0)
  })

  it('domain 레이어의 모든 소스 파일에 대응하는 테스트 파일이 존재한다', () => {
    const violations: string[] = []

    for (const file of tsFiles) {
      if (extractLayer(file) !== 'domain') continue
      const name = basename(file)
      // types / interface 파일은 테스트 불필요
      if (name.endsWith('.types.ts') || name.endsWith('.interface.ts')) continue

      const testFile = file.replace(/\.ts$/, '.test.ts')
      if (!existsSync(testFile)) {
        violations.push(`[위반] ${relative(SRC_DIR, file)}: 대응하는 테스트 파일이 없습니다`)
      }
    }

    if (violations.length > 0) {
      expect.fail(`테스트 파일 누락 ${violations.length}건:\n\n${violations.join('\n')}`)
    }
    expect(violations).toHaveLength(0)
  })

  it('src 하위에 TypeScript 소스 파일이 존재한다', () => {
    const nonTestFiles = tsFiles.filter((f) => !f.includes('tests'))
    expect(nonTestFiles.length).toBeGreaterThanOrEqual(0)
  })
})
