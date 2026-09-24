'use strict';

const { classifyPrompt, routingContext } = require('./prompt-router-core.cjs');

async function main() {
  let input = '';
  for await (const chunk of process.stdin) input += chunk;
  try {
    const { prompt } = JSON.parse(input);
    const result = classifyPrompt(prompt);
    const additionalContext = routingContext(result);
    if (additionalContext) {
      process.stdout.write(`${JSON.stringify({ hookSpecificOutput: { hookEventName: 'UserPromptSubmit', additionalContext } })}\n`);
    }
  } catch {
    // Advisory hook: malformed input must never interrupt the user's prompt.
  }
}

main();
