# Live Docs Project Pack

This optional pack helps agents consult version-compatible library documentation. It works with Claude Code, Codex CLI, and OpenCode.

## Recommended setup: Context MCP

ShipFrame recommends Context MCP as the optional local provider for Live Docs. ShipFrame itself still works without Context, and the installer never runs `npm install` or edits third-party MCP/client configuration for you.

```bash
npm install -g @neuledge/context
claude mcp add context -- context serve
codex mcp add context -- context serve
# OpenCode: add command ["context", "serve"] under mcp.context in ~/.config/opencode/opencode.json
```

Run `./install.sh --doctor` to see read-only detection and target-specific guidance.

## Legacy manifest sync

The older `.shipframe/context-packages.txt` + `./install.sh --sync-docs` flow is kept only for projects that already maintain explicit Context package manifests. It is no longer the recommended setup for new ShipFrame installs.

Manifest entries use exact versions, for example `npm/react@19.0.0` or `pip/fastapi@0.115.0`.
