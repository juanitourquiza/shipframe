'use strict';

const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const path = require('node:path');
const { test } = require('node:test');
const { classifyPrompt, latestUserMessage, latestUserText, routingContext } = require('../hooks/prompt-router-core.cjs');
const { registerPromptRouter } = require('../opencode/prompt-router.cjs');

test('classifies English and Spanish fast-path examples conservatively', () => {
  const cases = [
    ['Hi!', 'bypass'],
    ['What is a closure?', 'bypass'],
    ['$shipframe:code-review review this', 'bypass'],
    ['Fix the login bug in this repo', 'route'],
    ['Implement the new billing feature and add tests', 'route'],
    ['Review this code diff', 'route'],
    ['Review security risks in this repo', 'route'],
    ['Verify the E2E browser flow in this project', 'route'],
    ['Upgrade dependencies in the repository', 'route'],
    ['Review the API contract change in this repo', 'route'],
    ['Respond to this production incident', 'route'],
    ['Curate project memory for this repo', 'route'],
    ['Analiza la seguridad de este repositorio', 'route'],
    ['Verifica la prueba end-to-end del navegador en este proyecto', 'route'],
    ['Actualiza dependencias de este repositorio', 'route'],
    ['Revisa el contrato de API de este proyecto', 'route'],
    ['Responde a un incidente de producción', 'route'],
    ['Organiza la memoria de este proyecto', 'route'],
    ['Arregla el error de inicio de sesión en este proyecto', 'route'],
    ['Implementa la funcionalidad de pagos y agrega pruebas', 'route'],
    ['Can you help me with the repository?', 'suggest'],
    ['Ayúdame con este proyecto, no sé por dónde comenzar', 'suggest'],
    ['I need a new feature in the project', 'suggest'],
    ['Implement it', 'suggest'],
    ['Tell me a short joke', 'bypass'],
  ];

  for (const [prompt, decision] of cases) {
    assert.equal(classifyPrompt(prompt).decision, decision, prompt);
  }
});

test('explicit ShipFrame direction routes while keeping guidance advisory', () => {
  const result = classifyPrompt('Use ShipFrame for this task');
  assert.equal(result.decision, 'route');
  assert.match(routingContext(result), /advisory/i);
  assert.equal(routingContext(classifyPrompt('hello')), '');
  assert.equal(classifyPrompt('Realicemos la implementación utilizando ShipFrame').decision, 'route');
});

test('extracts the latest OpenCode user message from V2 message structures', () => {
  const messages = [
    { info: { role: 'user' }, parts: [{ type: 'text', text: 'first' }] },
    { info: { role: 'assistant' }, parts: [{ type: 'text', text: 'answer' }] },
    { info: { id: 'message-2', role: 'user' }, parts: [{ type: 'text', text: 'Fix this bug' }, { type: 'file', text: '' }] },
  ];
  assert.equal(latestUserText(messages), 'Fix this bug');
  assert.equal(latestUserMessage(messages).id, 'message-2');
  assert.equal(latestUserText([]), '');
});

test('Claude and Codex adapters emit only advisory context for routed prompts and fail open', () => {
  for (const adapter of ['claude-prompt-router.cjs', 'codex-prompt-router.cjs']) {
    const script = path.join(__dirname, '..', 'hooks', adapter);
    const route = spawnSync(process.execPath, [script], { input: JSON.stringify({ prompt: 'Fix the login bug in this repo' }), encoding: 'utf8' });
    assert.equal(route.status, 0, adapter);
    const result = JSON.parse(route.stdout);
    assert.equal(result.hookSpecificOutput.hookEventName, 'UserPromptSubmit');
    assert.match(result.hookSpecificOutput.additionalContext, /advisory/i);

    const bypass = spawnSync(process.execPath, [script], { input: JSON.stringify({ prompt: 'Hello' }), encoding: 'utf8' });
    assert.equal(bypass.stdout, '', adapter);

    const malformed = spawnSync(process.execPath, [script], { input: '{', encoding: 'utf8' });
    assert.equal(malformed.status, 0, adapter);
    assert.equal(malformed.stdout, '', adapter);
  }
});

test('OpenCode context adapter injects guidance once per user message and fails open', async () => {
  let hookName;
  let callback;
  let disposeCount = 0;
  const cleanup = await registerPromptRouter({ session: { hook: async (name, fn) => {
    hookName = name;
    callback = fn;
    return { dispose: async () => { disposeCount += 1; } };
  } } });
  assert.equal(hookName, 'context');

  const makeEvent = (id, prompt) => ({
    sessionID: 'session-1',
    messages: [{ info: { id, role: 'user' }, parts: [{ type: 'text', text: prompt }] }],
    system: [],
  });
  const routed = makeEvent('msg-1', 'Fix the login bug in this repo');
  callback(routed);
  assert.equal(routed.system.length, 1);
  assert.match(routed.system[0].text, /advisory/i);
  callback(routed);
  assert.equal(routed.system.length, 1);

  const bypass = makeEvent('msg-2', 'What is a closure?');
  callback(bypass);
  assert.equal(bypass.system.length, 0);

  const malformed = { sessionID: 'session-2', messages: [], system: null };
  assert.doesNotThrow(() => callback(malformed));
  assert.equal(typeof cleanup, 'function');
  await cleanup();
  await cleanup();
  assert.equal(disposeCount, 1, 'cleanup should be idempotent');
  const afterCleanup = makeEvent('msg-3', 'Fix this repo');
  callback(afterCleanup);
  assert.equal(afterCleanup.system.length, 0, 'disposed hooks must not mutate later contexts');
});
