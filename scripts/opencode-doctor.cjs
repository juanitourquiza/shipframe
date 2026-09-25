'use strict';

const fs = require('node:fs');
const path = require('node:path');

const PLUGIN_ID = 'shipframe.prompt-router';

function stripJsonComments(input) {
  let output = '';
  let quote = false;
  let escaped = false;
  for (let i = 0; i < input.length; i += 1) {
    const char = input[i];
    const next = input[i + 1];
    if (quote) {
      output += char;
      if (escaped) escaped = false;
      else if (char === '\\') escaped = true;
      else if (char === '"') quote = false;
      continue;
    }
    if (char === '"') { quote = true; output += char; continue; }
    if (char === '/' && next === '/') {
      while (i < input.length && input[i] !== '\n') i += 1;
      output += '\n';
      continue;
    }
    if (char === '/' && next === '*') {
      i += 2;
      while (i < input.length && !(input[i] === '*' && input[i + 1] === '/')) i += 1;
      i += 1;
      output += ' ';
      continue;
    }
    output += char;
  }
  return output.replace(/,\s*([}\]])/g, '$1');
}

function matchesPlugin(pattern) {
  if (pattern === '*') return true;
  if (pattern.endsWith('.*')) return PLUGIN_ID.startsWith(pattern.slice(0, -1));
  return pattern === PLUGIN_ID;
}

function disabledByConfigs(configPaths, inlineConfig) {
  let disabled = false;
  const errors = [];
  const configs = configPaths.filter((file) => fs.existsSync(file)).map((file) => {
    try { return { file, config: JSON.parse(stripJsonComments(fs.readFileSync(file, 'utf8'))) }; }
    catch { errors.push(path.basename(file)); return null; }
  }).filter(Boolean);
  if (inlineConfig) {
    try { configs.push({ file: 'OPENCODE_CONFIG_CONTENT', config: JSON.parse(stripJsonComments(inlineConfig)) }); }
    catch { errors.push('OPENCODE_CONFIG_CONTENT'); }
  }

  for (const { config } of configs) {
    const directives = config?.plugins;
    if (!Array.isArray(directives)) continue;
    for (const directive of directives) {
      if (typeof directive !== 'string') continue;
      const isDisabled = directive.startsWith('-');
      const pattern = isDisabled ? directive.slice(1) : directive;
      if (matchesPlugin(pattern)) disabled = isDisabled;
    }
  }
  return { disabled, errors };
}

function findConfigPaths({ home, cwd, env }) {
  const paths = [
    path.join(home, '.config/opencode/opencode.json'),
    path.join(home, '.config/opencode/opencode.jsonc'),
  ];
  if (env.OPENCODE_CONFIG) paths.push(path.resolve(cwd, env.OPENCODE_CONFIG));
  const projectConfigs = [];
  let current = path.resolve(cwd);
  for (;;) {
    projectConfigs.unshift(path.join(current, 'opencode.json'));
    projectConfigs.unshift(path.join(current, 'opencode.jsonc'));
    if (fs.existsSync(path.join(current, '.git')) || path.dirname(current) === current) break;
    current = path.dirname(current);
  }
  return [...new Set([...paths, ...projectConfigs])];
}

function diagnose({ installPath, sourcePath, configPaths = [], inlineConfig }) {
  let stat;
  try { stat = fs.lstatSync(installPath); }
  catch (error) {
    if (error.code === 'ENOENT') return { state: 'absent' };
    return { state: 'invalid', detail: error.message };
  }
  if (!stat.isSymbolicLink()) return { state: 'invalid', detail: 'plugin path is not a managed symlink' };

  let installedRealPath;
  let expectedRealPath;
  try {
    installedRealPath = fs.realpathSync(installPath);
    expectedRealPath = fs.realpathSync(sourcePath);
  } catch {
    return { state: 'invalid', detail: 'plugin symlink or source directory is broken' };
  }
  for (const entry of ['index.ts', 'prompt-router.cjs']) {
    if (!fs.existsSync(path.join(installedRealPath, entry))) return { state: 'invalid', detail: `missing ${entry}` };
  }
  let adapter;
  let router;
  try {
    adapter = fs.readFileSync(path.join(installedRealPath, 'index.ts'), 'utf8');
    router = fs.readFileSync(path.join(installedRealPath, 'prompt-router.cjs'), 'utf8');
  } catch {
    return { state: 'invalid', detail: 'adapter files are unreadable' };
  }
  if (!/^import\s+type\s+\{\s*Plugin\s*\}\s+from\s+['"]@opencode\/plugin['"]/m.test(adapter)
    || !/export\s+default\s+promptRouter/.test(adapter)
    || !/return\s+await\s+registerPromptRouter\(ctx\)/.test(adapter)
    || !/registration\?\.dispose\?\./.test(router)) {
    return { state: 'invalid', detail: 'adapter has a runtime import, missing registration, or lacks hook cleanup' };
  }

  const config = disabledByConfigs(configPaths, inlineConfig);
  const source = installedRealPath === expectedRealPath ? 'repo' : 'external';
  if (config.errors.length) return { state: 'config-unknown', configErrors: config.errors, source };
  if (config.disabled) return { state: 'disabled', configErrors: config.errors, source };
  return { state: 'ready', source };
}

function main() {
  const [installPath, sourcePath] = process.argv.slice(2);
  const result = diagnose({
    installPath,
    sourcePath,
    configPaths: findConfigPaths({ home: process.env.HOME || '', cwd: process.cwd(), env: process.env }),
    inlineConfig: process.env.OPENCODE_CONFIG_CONTENT,
  });
  const messages = {
    absent: 'OpenCode prompt-router plugin is not installed.',
    invalid: `OpenCode prompt-router plugin is invalid: ${result.detail}.`,
    disabled: 'OpenCode prompt-router plugin is disabled by an inspected OpenCode v2 plugins directive.',
    'config-unknown': `OpenCode prompt-router is installed, but some config sources could not be inspected (${(result.configErrors || []).join(', ')}).`,
    ready: `OpenCode prompt-router plugin is installed and passes adapter checks (${result.source} source); no disabling directive was found in inspected config sources.`,
  };
  process.stdout.write(`${JSON.stringify({ ...result, message: messages[result.state] })}\n`);
  if (result.state === 'invalid') process.exitCode = 2;
}

if (require.main === module) main();
module.exports = { diagnose, findConfigPaths, stripJsonComments };
