#!/usr/bin/env node
// PreToolUse guard: asks for explicit human approval before direct mutations.
const ORCHESTRATOR = 'orchestrator-agent';
const WRITE_TOOLS = new Set(['Edit', 'Write', 'MultiEdit', 'NotebookEdit']);
const MUTATING_COMMANDS = new Set(['cp', 'mv', 'rm', 'touch']);

// Minimal shell tokenizer: command names inside single/double quotes are data,
// not executable commands. Handles separators and common sudo/env prefixes.
function hasShellMutation(command) {
  const tokens = [];
  let value = '', quote = '', escaped = false;
  const flush = () => { if (value) tokens.push(value); value = ''; };
  for (let i = 0; i < command.length; i++) {
    const c = command[i];
    if (escaped) { value += c; escaped = false; continue; }
    if (c === '\\' && quote !== "'") { escaped = true; continue; }
    if (quote) { if (c === quote) quote = ''; else value += c; continue; }
    if (c === "'" || c === '"') { quote = c; continue; }
    if (/\s/.test(c)) { flush(); continue; }
    if (c === ';' || c === '|' || c === '&' || c === '\n') { flush(); tokens.push(c); continue; }
    value += c;
  }
  flush();
  let expectCommand = true;
  for (const token of tokens) {
    if ([';', '|', '&', '\n'].includes(token)) { expectCommand = true; continue; }
    if (!expectCommand) continue;
    if (['sudo', 'env', 'command'].includes(token)) continue;
    if (MUTATING_COMMANDS.has(token.split('/').pop())) return true;
    expectCommand = false;
  }
  // Other common shell write idioms: file redirects, tee, and in-place editors.
  return /(^|\s)>>?\s*(?![&]|\/dev\/null)[^\s;&|]+|(^|[;&|\s])tee(?:\s|$)|\b(?:sed|perl)\b[^|;&]*\s-i/.test(command);
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
