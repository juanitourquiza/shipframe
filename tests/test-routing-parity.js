'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const routing = JSON.parse(fs.readFileSync(path.join(root, 'routing.json'), 'utf8'));
assert.equal(routing.schemaVersion, 2);
const codex = fs.readFileSync(path.join(root, 'codex/dev-workflow.md'), 'utf8');
const readme = fs.readFileSync(path.join(root, 'README.md'), 'utf8');
const orchestrator = fs.readFileSync(path.join(root, 'agents/orchestrator-agent.md'), 'utf8');
const claudeAgents = fs.readdirSync(path.join(root, 'agents')).filter((file) => file.endsWith('.md'));
const routeCell = (document, intent, sectionHeading) => {
  const scoped = document.slice(document.indexOf(sectionHeading));
  const line = scoped.split('\n').find((entry) => entry.includes(`| \`${intent}\` |`));
  return line?.split('|').at(-2).replace(/`/g, '').trim();
};

const aliasEntries = Object.entries(routing.aliases || {});
const canonicalize = (sequence) => {
  return sequence.split(/\s*(?:→|·)\s*/).map((rawStep) => {
    const conditions = [...rawStep.matchAll(/\(([^)]*)\)/g)].map((match) => match[1].replace(/\s+/g, ' ').trim().toLowerCase());
    const normalizedConditions = conditions.map((condition) => condition.replace(/; otherwise tdd skill/i, ''));
    let step = rawStep.replace(/\([^)]*\)/g, ' ').replace(/\s+/g, ' ').trim();
    const requestedFixes = /\bif fixes are requested\b/i.test(step);
    step = step.replace(/\s+if fixes are requested\b/i, '').trim();
    if (routing.qa_gate.tokens.some((token) => new RegExp(`\\b${token}\\b`, 'i').test(step))) return `qa-gate${normalizedConditions.length ? `[${normalizedConditions.join(';')}]` : ''}`;
    for (const [canonical, aliases] of aliasEntries) {
      for (const alias of aliases) step = step.split(alias).join(canonical);
    }
    if (requestedFixes) normalizedConditions.push('if fixes are requested');
    return `${step}${normalizedConditions.length ? `[${normalizedConditions.join(';')}]` : ''}`;
  });
};

const sourceSequence = (document, intent, sectionHeading) => routeCell(document, intent, sectionHeading);

for (const [intent, sequence] of Object.entries(routing.intents)) {
  assert.ok(codex.includes(`| \`${intent}\` |`), `Codex routing missing ${intent}`);
  assert.ok(readme.includes(`| \`${intent}\` |`), `README routing missing ${intent}`);
  assert.ok(orchestrator.includes(`${intent}:`), `Orchestrator routing missing ${intent}`);
  const canonicalSequence = canonicalize(sequence);
  assert.deepEqual(canonicalize(sourceSequence(codex, intent, '## Routing Table')), canonicalSequence, `Codex sequence differs from routing.json for ${intent}`);
  assert.deepEqual(canonicalize(sourceSequence(readme, intent, '## Codex workflow')), canonicalSequence, `README sequence differs from routing.json for ${intent}`);
  const variant = routing.host_variants?.[intent];
  const expectedAgent = variant?.agents || sequence;
  const scopedOrchestrator = orchestrator.split('## Routing Table')[1];
  const match = scopedOrchestrator.match(new RegExp(`^${intent}:\\n(?:(?!^[a-z][a-z0-9_]*:)[\\s\\S])*?^  sequence: (.+)$`, 'm'));
  assert.ok(match, `Orchestrator sequence missing for ${intent}`);
  assert.deepEqual(canonicalize(match[1]), canonicalize(expectedAgent), `Orchestrator sequence differs from routing.json/host variant for ${intent}`);
  if (variant) assert.deepEqual(canonicalize(variant.expands_to), canonicalSequence, `Host variant expansion differs from canonical route for ${intent}`);
}

for (const intent of ['security_review', 'security_hardening', 'e2e_test', 'deps_upgrade', 'api_change', 'incident', 'memory_curate', 'memory_setup']) {
  const sequence = routing.intents[intent];
  assert.deepEqual(canonicalize(routeCell(codex, intent, '## Routing Table')), canonicalize(sequence));
  assert.deepEqual(canonicalize(routeCell(readme, intent, '## Codex workflow')), canonicalize(sequence));
}

for (const skill of ['security-review', 'security-hardening', 'e2e-verify', 'dependency-upgrade', 'api-contract-review', 'incident-response', 'memory-curator', 'project-memory-init']) {
  const file = path.join(root, 'skills', skill, 'SKILL.md');
  const contents = fs.readFileSync(file, 'utf8');
  assert.match(contents, /^---\nname: /);
  assert.match(contents, /Intent:/);
  assert.match(contents, /Resumen \(ES\)/);
  assert.match(contents, /Host (?:paths and )?limits/);
}

// Native delegation is a host capability, not an assumed or simulated outcome.
assert.ok(claudeAgents.includes('reviewer-agent.md'), 'Claude/OpenCode independent reviewer remains available');
assert.doesNotMatch(codex, /Codex has no sub-?agent delegation/i, 'Codex docs must not claim native delegation is absent');
assert.match(codex, /native subagent mechanism/i, 'Codex workflow should use native delegation when available');
assert.match(codex, /explicitly report that delegation\/review was not independently performed/i);
assert.match(codex, /does not enable experimental features or edit user-owned `config\.toml` settings/i);
assert.match(readme, /Codex supports native subagents/i, 'README must describe current Codex capability');
assert.match(readme, /does not modify user-owned `config\.toml`/i);

const implementTask = fs.readFileSync(path.join(root, 'skills/implement-task/SKILL.md'), 'utf8');
assert.match(implementTask, /Conditional security hardening/);
assert.match(implementTask, /without invoking `implement-task` recursively/);
assert.match(implementTask, /security-review.*evidence-based security assessment/);

console.log(`Routing parity passed for ${Object.keys(routing.intents).length} intents and seven checked skills`);
