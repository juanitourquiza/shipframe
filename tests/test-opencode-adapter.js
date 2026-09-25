'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const { spawnSync } = require('node:child_process');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const adapter = fs.readFileSync(path.join(root, 'opencode/index.ts'), 'utf8');

assert.match(adapter, /^import\s+type\s+\{\s*Plugin\s*\}\s+from\s+['"]@opencode\/plugin['"]/m,
  'OpenCode SDK must remain a type-only import');
assert.match(adapter, /export\s+default\s+promptRouter/);
assert.match(adapter, /async\s+setup\s*\(/);

// Prove the repository-only doctor rejects the exact regression this test guards.
const installer = spawnSync(path.join(root, 'install.sh'), ['--doctor', '--repo-only'], { cwd: root, encoding: 'utf8' });
assert.equal(installer.status, 0, `Repository-only doctor failed:\n${installer.stdout}\n${installer.stderr}`);
const broken = adapter.replace(/^import\s+type\s+\{\s*Plugin\s*\}/m, 'import { Plugin }');
assert.notEqual(broken, adapter, 'Could not construct the deliberate runtime-import regression');
try {
  fs.writeFileSync(path.join(root, 'opencode/index.ts'), broken);
  const negative = spawnSync(path.join(root, 'install.sh'), ['--doctor', '--repo-only'], { cwd: root, encoding: 'utf8' });
  assert.notEqual(negative.status, 0, 'Repository-only doctor must reject an OpenCode runtime import');
} finally {
  fs.writeFileSync(path.join(root, 'opencode/index.ts'), adapter);
}
console.log('Repository-only doctor rejected the deliberate OpenCode regression');

const bun = spawnSync('bun', ['--version'], { encoding: 'utf8' });
if (bun.error && bun.error.code === 'ENOENT') {
  console.log('SKIP OpenCode runtime smoke: Bun is not installed (static adapter checks passed)');
  process.exit(0);
}
assert.equal(bun.status, 0, `Could not run Bun: ${bun.stderr}`);

const smoke = String.raw`
import plugin from ${JSON.stringify(path.join(root, 'opencode/index.ts'))};
if (!plugin || typeof plugin.setup !== 'function') throw new Error('Plugin setup is not registered');
await plugin.setup({ event: { on: async () => {} } });
`;
const result = spawnSync('bun', ['--eval', smoke], { cwd: root, encoding: 'utf8' });
assert.equal(result.status, 0, `OpenCode adapter failed to load/setup with Bun:\n${result.stderr || result.stdout}`);
console.log(`OpenCode adapter runtime smoke passed with Bun ${bun.stdout.trim()}`);
