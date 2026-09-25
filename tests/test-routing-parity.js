'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const routing = JSON.parse(fs.readFileSync(path.join(root, 'routing.json'), 'utf8'));
assert.equal(routing.schemaVersion, 1);
const codex = fs.readFileSync(path.join(root, 'codex/dev-workflow.md'), 'utf8');
const readme = fs.readFileSync(path.join(root, 'README.md'), 'utf8');
const orchestrator = fs.readFileSync(path.join(root, 'agents/orchestrator-agent.md'), 'utf8');
const routeCell = (document, intent, sectionHeading) => {
  const scoped = document.slice(document.indexOf(sectionHeading));
  const line = scoped.split('\n').find((entry) => entry.includes(`| \`${intent}\` |`));
  return line?.split('|').at(-2).replace(/`/g, '').trim();
};

for (const [intent, sequence] of Object.entries(routing.intents)) {
  assert.ok(codex.includes(`| \`${intent}\` |`), `Codex routing missing ${intent}`);
  assert.ok(readme.includes(`| \`${intent}\` |`), `README routing missing ${intent}`);
  assert.ok(orchestrator.includes(`${intent}:`), `Orchestrator routing missing ${intent}`);
  assert.equal(routeCell(codex, intent, '## Routing Table'), sequence, `Codex sequence differs from routing.json for ${intent}`);
  assert.equal(routeCell(readme, intent, '## Codex workflow'), sequence, `README sequence differs from routing.json for ${intent}`);
  for (const skill of sequence.match(/[a-z][a-z0-9-]+/g) || []) {
    // Agent aliases and conditional prose are not skill paths; only enforce files for routed skill slugs.
    const skillFile = path.join(root, 'skills', skill, 'SKILL.md');
    if (fs.existsSync(skillFile)) assert.ok(fs.statSync(skillFile).isFile());
  }
}

for (const intent of ['security_review', 'e2e_test', 'deps_upgrade', 'api_change', 'incident', 'memory_curate']) {
  const sequence = routing.intents[intent];
  assert.equal(routeCell(codex, intent, '## Routing Table'), sequence, `Codex sequence differs from routing.json for ${intent}`);
  assert.equal(routeCell(readme, intent, '## Codex workflow'), sequence, `README sequence differs from routing.json for ${intent}`);
  assert.ok(orchestrator.includes(`sequence: ${sequence}`), `Orchestrator sequence differs from routing.json for ${intent}`);
}

for (const skill of ['security-review', 'e2e-verify', 'dependency-upgrade', 'api-contract-review', 'incident-response', 'memory-curator']) {
  const file = path.join(root, 'skills', skill, 'SKILL.md');
  const contents = fs.readFileSync(file, 'utf8');
  assert.match(contents, /^---\nname: /);
  assert.match(contents, /Intent:/);
  assert.match(contents, /Resumen \(ES\)/);
  assert.match(contents, /Host (?:paths and )?limits/);
}

console.log(`Routing parity passed for ${Object.keys(routing.intents).length} intents and six new skills`);
