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
  allFiles: string[],
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
        if (cycleStart !== -1) cycles.push([...path.slice(cycleStart)])
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

describe('Architecture Dependency Rules', () => {
  const tsFiles = collectTsFiles(SRC_DIR)

  it('no layer imports from a higher layer', () => {
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
          violations.push(
            `[violation] ${relative(SRC_DIR, file)} (${fromLayer}) → ${imp} (${toLayer})`,
          )
        }
      }
    }
    if (violations.length > 0)
      expect.fail(`Layer dependency violations (${violations.length}):\n\n${violations.join('\n')}`)
    expect(violations).toHaveLength(0)
  })

  it('domain layer does not import external libraries', () => {
    const violations: string[] = []
    for (const file of tsFiles) {
      if (extractLayer(file) !== 'domain') continue
      for (const imp of extractImports(file)) {
        if (imp.startsWith('.')) continue
        if (!ALLOWED_NODE_BUILTINS.has(imp)) {
          violations.push(
            `[violation] ${relative(SRC_DIR, file)}: external library '${imp}' import forbidden`,
          )
        }
      }
    }
    if (violations.length > 0)
      expect.fail(`Domain purity violations (${violations.length}):\n\n${violations.join('\n')}`)
    expect(violations).toHaveLength(0)
  })

  it('no circular references within the same layer', () => {
    const graph = buildImportGraph(tsFiles)
    const cycles = findCycles(graph)
    if (cycles.length > 0) {
      const descriptions = cycles.map((cycle) => cycle.map((f) => relative(SRC_DIR, f)).join(' → '))
      expect.fail(`Circular references (${cycles.length}):\n\n${descriptions.join('\n')}`)
    }
    expect(cycles).toHaveLength(0)
  })

  it('all source files follow kebab-case naming convention', () => {
    const KEBAB_CASE = /^[a-z][a-z0-9]*(-[a-z0-9]+)*(\.(types|interface))?\.ts$/
    const violations: string[] = []
    for (const file of tsFiles) {
      const name = basename(file)
      if (!KEBAB_CASE.test(name)) {
        violations.push(`[violation] ${relative(SRC_DIR, file)}: '${name}' is not kebab-case`)
      }
    }
    if (violations.length > 0)
      expect.fail(
        `File naming convention violations (${violations.length}):\n\n${violations.join('\n')}`,
      )
    expect(violations).toHaveLength(0)
  })

  it('every domain layer source file has a corresponding test file', () => {
    const violations: string[] = []
    for (const file of tsFiles) {
      if (extractLayer(file) !== 'domain') continue
      const name = basename(file)
      if (name.endsWith('.types.ts') || name.endsWith('.interface.ts')) continue
      const testFile = file.replace(/\.ts$/, '.test.ts')
      if (!existsSync(testFile)) {
        violations.push(`[violation] ${relative(SRC_DIR, file)}: no corresponding test file found`)
      }
    }
    if (violations.length > 0)
      expect.fail(`Missing test files (${violations.length}):\n\n${violations.join('\n')}`)
    expect(violations).toHaveLength(0)
  })

  it('TypeScript source files exist under src', () => {
    const nonTestFiles = tsFiles.filter((f) => !f.includes('tests'))
    expect(nonTestFiles.length).toBeGreaterThan(0)
  })
})
