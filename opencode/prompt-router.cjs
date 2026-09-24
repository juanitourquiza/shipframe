'use strict';

const router = require('../hooks/prompt-router-core.cjs');

function registerPromptRouter(ctx) {
  const seenPromptBySession = new Map();
  return ctx.session.hook('context', (event) => {
    try {
      const sessionID = event.sessionID;
      const userMessage = router.latestUserMessage(event.messages);
      const prompt = userMessage?.text ?? '';
      const messageKey = userMessage?.id ?? prompt;
      if (!sessionID || !prompt || !messageKey || seenPromptBySession.get(sessionID) === messageKey) return;

      seenPromptBySession.set(sessionID, messageKey);
      if (seenPromptBySession.size > 256) {
        const oldestSession = seenPromptBySession.keys().next().value;
        if (oldestSession) seenPromptBySession.delete(oldestSession);
      }

      const context = router.routingContext(router.classifyPrompt(prompt));
      if (context) event.system.push({ type: 'text', text: context });
    } catch {
      // Advisory hook: fail open and let OpenCode build its original context.
    }
  });
}

module.exports = { registerPromptRouter };
