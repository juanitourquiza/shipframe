#!/usr/bin/env node
// PreToolUse guard: asks for explicit human approval before direct mutations.
const ORCHESTRATOR = 'orchestrator-agent';
const WRITE_TOOLS = new Set(['Edit', 'Write', 'MultiEdit', 'NotebookEdit']);
const MUTATING_COMMANDS = new Set(['cp', 'mv', 'rm', 'touch']);
const SEPARATORS = new Set([';', '|', '&', '\n']);

function tokenizeShell(command) {
  const tokens = [];
  let value = '', quote = '', escaped = false;
  const flush = () => { if (value) tokens.push({ type: 'word', value }); value = ''; };
  for (let i = 0; i < command.length; i++) {
    const c = command[i];
    if (escaped) { value += c; escaped = false; continue; }
    if (c === '\\' && quote !== "'") { escaped = true; continue; }
    if (quote) { if (c === quote) quote = ''; else value += c; continue; }
    if (c === "'" || c === '"') { quote = c; continue; }
    if (c === '\n') { flush(); tokens.push({ type: 'separator', value: c }); continue; }
    if (/\s/.test(c)) { flush(); continue; }
    if (c === '>') {
      flush();
      if (command[i + 1] === '>') i++;
      tokens.push({ type: 'redirect', value: '>' });
      continue;
    }
    if (SEPARATORS.has(c)) { flush(); tokens.push({ type: 'separator', value: c }); continue; }
    value += c;
  }
  flush();
  return tokens;
}

function skipWrapper(tokens, index) {
  for (;;) {
    const name = (tokens[index]?.value || '').split('/').pop();
    if (name === 'sudo') {
      index++;
      while (tokens[index]?.type === 'word' && tokens[index].value.startsWith('-')) {
        const option = tokens[index++].value;
        if (option === '--') break;
        if (['-u', '--user', '-g', '--group', '-h', '--host', '-p', '--prompt', '-C', '--close-from', '-r', '--role', '-t', '--type'].includes(option)) index++;
      }
      continue;
    }
    if (name === 'env') {
      index++;
      while (tokens[index]?.type === 'word') {
        const arg = tokens[index].value;
        if (arg === '--') { index++; break; }
        if (/^[A-Za-z_][A-Za-z0-9_]*=/.test(arg)) { index++; continue; }
        if (['-i', '--ignore-environment', '-0', '--null'].includes(arg) || arg.startsWith('--unset=') || arg.startsWith('--chdir=')) { index++; continue; }
        if (['-u', '--unset', '-C', '--chdir'].includes(arg)) { index += 2; continue; }
        if (arg.startsWith('-')) { index++; continue; }
        break;
      }
      continue;
    }
    if (name === 'command') {
      index++;
      if (['-v', '-V'].includes(tokens[index]?.value)) return { index, lookupOnly: true };
      if (tokens[index]?.value === '-p') index++;
      if (tokens[index]?.value === '--') index++;
      continue;
    }
    return { index, lookupOnly: false };
  }
}

function hasShellMutation(command) {
  const tokens = tokenizeShell(command);
  let expectCommand = true;
  for (let i = 0; i < tokens.length; i++) {
    const token = tokens[i];
    if (token.type === 'separator') { expectCommand = true; continue; }
    if (token.type === 'redirect') {
      const target = tokens[i + 1];
      if (target?.type === 'separator' && target.value === '&') { i++; continue; }
      if (target?.type === 'word' && target.value !== '/dev/null' && !target.value.startsWith('&')) return true;
      continue;
    }
    if (!expectCommand || token.type !== 'word') continue;
    const { index, lookupOnly } = skipWrapper(tokens, i);
    if (lookupOnly) { expectCommand = false; i = index; continue; }
    const commandToken = tokens[index];
    if (!commandToken || commandToken.type !== 'word') { expectCommand = false; continue; }
    const name = commandToken.value.split('/').pop();
    if (MUTATING_COMMANDS.has(name) || name === 'tee') return true;
    if (name === 'sed' || name === 'perl') {
      for (let j = index + 1; j < tokens.length && !SEPARATORS.has(tokens[j].value); j++) {
        if (tokens[j].type === 'word' && /(^|\s)-[^\s]*i/.test(tokens[j].value)) return true;
      }
    }
    expectCommand = false;
    i = index;
  }
  return false;
}

function runGuard() {
  let raw = '';
  process.stdin.on('data', c => (raw += c));
  process.stdin.on('end', () => {
    let input;
    try { input = JSON.parse(raw || '{}'); } catch { process.exit(0); }
    const agentType = typeof input.agent_type === 'string' ? input.agent_type : '';
    if (agentType.split(':').pop() !== ORCHESTRATOR) process.exit(0);
    const tool = input.tool_name;
    let blocked = WRITE_TOOLS.has(tool);
    if (tool === 'Bash') blocked = hasShellMutation((input.tool_input && input.tool_input.command) || '');
    if (!blocked) process.exit(0);
    process.stdout.write(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'PreToolUse',
        permissionDecision: 'ask',
        permissionDecisionReason: 'Direct file mutations require explicit human approval.',
      },
    }));
    process.exit(0);
  });
}

if (require.main === module) runGuard();
module.exports = { hasShellMutation };
