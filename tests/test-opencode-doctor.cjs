'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { diagnose, findConfigPaths, stripJsonComments } = require('../scripts/opencode-doctor.cjs');

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'shipframe-opencode-doctor-'));
try {
  const source = path.join(tmp, 'source');
  const plugins = path.join(tmp, 'home', '.config/opencode/plugins');
  const install = path.join(plugins, 'shipframe-prompt-router');
  fs.mkdirSync(source, { recursive: true });
  fs.mkdirSync(plugins, { recursive: true });
  fs.writeFileSync(path.join(source, 'index.ts'), "import type { Plugin } from '@opencode/plugin'\nconst promptRouter = { async setup(ctx) { return await registerPromptRouter(ctx) } }\nexport default promptRouter\n");
  fs.writeFileSync(path.join(source, 'prompt-router.cjs'), 'return async () => { active = false; await registration?.dispose?.() }');
  const expectedSource = path.join(tmp, 'expected-source');
  fs.cpSync(source, expectedSource, { recursive: true });

  assert.equal(diagnose({ installPath: install, sourcePath: source }).state, 'absent');
  fs.symlinkSync(source, install);
  assert.equal(diagnose({ installPath: install, sourcePath: source }).state, 'ready');
  assert.equal(diagnose({ installPath: install, sourcePath: expectedSource }).source, 'external');

  const globalConfig = path.join(tmp, 'home', '.config/opencode/opencode.jsonc');
  fs.writeFileSync(globalConfig, '{\n // User-owned config\n "plugins": ["*", "-shipframe.*",],\n}');
  assert.equal(diagnose({ installPath: install, sourcePath: source, configPaths: [globalConfig] }).state, 'disabled');

  fs.writeFileSync(globalConfig, '{"plugins":["-shipframe.prompt-router", "shipframe.prompt-router"]}');
  assert.equal(diagnose({ installPath: install, sourcePath: source, configPaths: [globalConfig] }).state, 'ready');
  assert.match(stripJsonComments('{"url":"https://example.test",/* note */"ok":true,}'), /https:\/\//);

  const custom = path.join(tmp, 'custom.jsonc');
  fs.writeFileSync(custom, '{"plugins":["-*"]}');
  const configs = findConfigPaths({ home: path.join(tmp, 'home'), cwd: tmp, env: { OPENCODE_CONFIG: custom } });
  assert.ok(configs.includes(custom));

  fs.unlinkSync(path.join(source, 'index.ts'));
  assert.equal(diagnose({ installPath: install, sourcePath: source }).state, 'invalid');
  console.log('OpenCode environment doctor tests passed');
} finally {
  fs.rmSync(tmp, { recursive: true, force: true });
}
