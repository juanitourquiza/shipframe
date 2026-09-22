# Live Docs Project Pack

This optional pack helps agents consult version-compatible library documentation. It works with Claude Code, Codex CLI, and OpenCode.

## Setup

1. Copy `.shipframe/context-packages.txt` into the consuming project.
2. Install Neuledge Context explicitly if desired: `npm install -g @neuledge/context`.
3. Run `./install.sh --sync-docs --project-dir /absolute/path/to/project`.
4. Copy the MCP example for your client; ShipFrame never edits client configuration automatically.

Without Neuledge, the `live-docs` skill still uses official documentation and reports source/version gaps.

Manifest entries use exact versions, for example `npm/react@19.0.0` or `pip/fastapi@0.115.0`.
