import type { Plugin } from '@opencode/plugin'
import { registerPromptRouter } from './prompt-router.cjs'

// Keep the OpenCode SDK import type-only: the plugin is symlinked into the user's
// config from paths without node_modules (e.g. a Homebrew Cellar), where a runtime
// bare-specifier import cannot resolve and OpenCode reports "Plugin failed".
const promptRouter: Plugin.Plugin = {
  id: 'shipframe.prompt-router',
  async setup(ctx) {
    try {
      return await registerPromptRouter(ctx)
    } catch {
      // Optional workflow guidance must not prevent OpenCode from starting.
    }
  },
}

export default promptRouter
