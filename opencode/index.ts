import { Plugin } from '@opencode/plugin'
import { registerPromptRouter } from './prompt-router.cjs'

export default Plugin.define({
  id: 'shipframe.prompt-router',
  async setup(ctx) {
    try {
      await registerPromptRouter(ctx)
    } catch {
      // Optional workflow guidance must not prevent OpenCode from starting.
    }
  },
})
