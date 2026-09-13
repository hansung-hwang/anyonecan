// Inspect the shipped parsers/hooks with inert child-process stubs.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const ts = require('typescript');
const root = path.resolve(__dirname, '../..');
const archPath = path.join(root, 'language-packs/typescript/src/tests/arch/dependencies.test.ts');
const arch = fs.readFileSync(archPath, 'utf8').split("describe('Architecture Dependency Rules'")[0];
const fixture = path.join(root, 'src/domain/a.ts');
let fixtureContent = '';
const context = {
  exports: {}, process: { cwd: () => root },
  require: (name) => name === 'vitest' ? {} : name === 'fs'
    ? { ...fs, readFileSync: (file, ...args) => file === fixture ? fixtureContent : fs.readFileSync(file, ...args) }
    : require(name),
};
vm.createContext(context);
vm.runInContext(ts.transpileModule(arch, { compilerOptions: { module: ts.ModuleKind.CommonJS } }).outputText, context);
for (const input of ["import 'external';", "const x = import('external');", "import { x } from '@/infrastructure/x';"]) {
  fixtureContent = input;
  console.log(JSON.stringify({ input, extracted: context.extractImports(fixture), aliasLayer: context.resolveImportLayer('@/infrastructure/x', fixture) }));
}
console.log('js-suffix cycle resolution:', context.resolveImportFile('./b.js', fixture, [path.join(root, 'src/domain/b.ts')]));
for (const relative of ['scripts/lint-format-hook.mjs', 'language-packs/typescript/scripts/lint-format-hook.mjs']) {
  const handlers = {};
  const commands = [];
  const hook = {
    exports: {},
    process: { cwd: () => root, stdin: { setEncoding: () => {}, on: (event, callback) => { handlers[event] = callback; } } },
    require: (name) => name === 'child_process' ? { execSync: (command) => commands.push(command) } : require(name),
  };
  vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(root, relative), 'utf8'), { compilerOptions: { module: ts.ModuleKind.CommonJS } }).outputText, hook);
  handlers.data(JSON.stringify({ tool_input: { file_path: '/tmp/$(printf audit).ts' } }));
  handlers.end();
  console.log(JSON.stringify({ hook: relative, capturedOnlyNoExecution: commands }));
}
