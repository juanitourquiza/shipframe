# Live Docs Project Pack

This optional pack helps agents consult version-compatible library documentation. It works with Claude Code, Codex CLI, and OpenCode. It is the shared documentation workflow for every technology pack; it is not another framework pack.

## Recommended setup: Context MCP

ShipFrame recommends Context MCP as the optional local provider for Live Docs. ShipFrame itself still works without Context, and the installer never runs `npm install` or edits third-party MCP/client configuration for you.

```bash
npm install -g @neuledge/context
claude mcp add context -- context serve
codex mcp add context -- context serve
# OpenCode v2: add command ["context", "serve"] under mcp.servers.context in ~/.config/opencode/opencode.json
```

Run `./install.sh --doctor` to see read-only detection and target-specific guidance.

## Use it from a project

`init-project` can detect the stack and suggest this workflow when the repository has external dependencies. For each API-dependent change, resolve the package and version from the lockfile before asking Context or opening official docs. Never assume that the newest docs match the repository.

Context is configured by the user in the desired host scope. It may fetch a registry documentation package the first time a query needs it; do not trigger that download or change client configuration without opt-in. If the registry lacks the exact package/version, prefer official versioned docs. Context can also build documentation from a URL/repository when explicitly requested; verify the docs source/tag before using it.

If you want Context enabled only for a repository, use your MCP host's documented project-level configuration where available. For example, Codex supports `.codex/config.toml` in a workspace:

```toml
[mcp_servers.context]
command = "context"
args = ["serve"]
```

This is guidance only: ShipFrame does not create or edit that file. You may instead configure Context once at user scope. Either way, use the project lockfile to request matching dependency docs.

## Legacy manifest sync

The older `.shipframe/context-packages.txt` + `./install.sh --sync-docs` flow is kept only for projects that already maintain explicit Context package manifests. It is no longer the recommended setup for new ShipFrame installs.

Manifest entries use exact versions, for example `npm/react@19.0.0` or `pip/fastapi@0.115.0`.
