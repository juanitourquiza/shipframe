#!/usr/bin/env node
// PreToolUse guard: the orchestrator-agent routes work, it does not write code.
// Asks for explicit human approval when the orchestrator tries to modify files
// directly. Tech-agnostic: no language, path, or build-tool assumptions.

const ORCHESTRATOR = 'orchestrator-agent';
const WRITE_TOOLS = new Set(['Edit', 'Write', 'MultiEdit', 'NotebookEdit']);

// Shell idioms that mutate files, regardless of stack:
//   redirect to a real file (not a descriptor like 2>&1, not /dev/null),
//   tee, and in-place stream editors (sed -i, perl -i).
const BASH_WRITES =
  /(^|[\s;|&])>>?\s*(?![&]|\/dev\/null)[^\s&;|]|\btee\b|\b(sed|perl)\b[^|;&]*\s-i/;

let raw = '';
process.stdin.on('data', c => (raw += c));
process.stdin.on('end', () => {
  let input;
  try { input = JSON.parse(raw || '{}'); } catch { process.exit(0); }

  // Only the orchestrator is gated; sub-agents and the main loop pass through.
  // agent_type is plugin-namespaced (e.g. "shipframe:orchestrator-agent"),
  // so compare the trailing segment, not the whole string.
  const agentType = typeof input.agent_type === 'string' ? input.agent_type : '';
  if (agentType.split(':').pop() !== ORCHESTRATOR) process.exit(0);

  const tool = input.tool_name;
  let blocked = WRITE_TOOLS.has(tool);
  if (tool === 'Bash') {
    blocked = BASH_WRITES.test((input.tool_input && input.tool_input.command) || '');
  }
  if (!blocked) process.exit(0);

  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'ask',
      permissionDecisionReason:
        'Direct file edits from the orchestrator require explicit human approval. ' +
        'Route this to a sub-agent instead (implement-task-agent for features/refactors, ' +
        'bugfixer-agent for bugs).',
    },
  }));
  process.exit(0);
});
