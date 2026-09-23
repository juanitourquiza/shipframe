const test = require('node:test');
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const path = require('node:path');
const { hasShellMutation } = require('../hooks/orchestrator-guard');
const guard = path.resolve(__dirname, '../hooks/orchestrator-guard.js');

test('detects direct mutating commands at command positions', () => {
  for (const command of ['cp a b', 'mv a b', 'rm -rf x', 'touch x', 'echo ok && sudo rm x', 'sudo -u root rm x', 'env HOME=x rm x', 'cat x | cp - y', 'echo ok\nrm x']) {
    assert.equal(hasShellMutation(command), true, command);
  }
});

test('allows read-only commands and mutation words in quoted text', () => {
  for (const command of ['ls -la', 'git status', 'grep rm README.md', 'echo "rm -rf /"', "printf '%s' 'touch file'", "echo 'sed -i replacement file'", "echo ' > output.txt'", 'echo ok > /dev/null', 'command -v rm']) {
    assert.equal(hasShellMutation(command), false, command);
  }
});

test('guard blocks mutations only for orchestrator agent', () => {
  const input = { agent_type: 'shipframe:orchestrator-agent', tool_name: 'Bash', tool_input: { command: 'rm file' } };
  const run = (agent_type) => spawnSync(process.execPath, [guard], { input: JSON.stringify({ ...input, agent_type }), encoding: 'utf8' });
  assert.match(run('shipframe:orchestrator-agent').stdout, /"permissionDecision":"ask"/);
  assert.equal(run('shipframe:quality-assurance-agent').stdout, '');
});
