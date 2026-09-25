'use strict';

const router = require('../hooks/prompt-router-core.cjs');

async function registerPromptRouter(ctx) {
  const seenPromptBySession = new Map();
  let active = true;
  const registration = await ctx.session.hook('context', (event) => {
    try {
      if (!active) return;
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
  return async () => {
    if (!active) return;
    active = false;
    seenPromptBySession.clear();
    try { await registration?.dispose?.(); } catch {
      // Hook cleanup is best-effort; never interfere with OpenCode shutdown.
    }
  };
}

module.exports = { registerPromptRouter };
