# Live Docs

`live-docs` is an optional ShipFrame skill for changes that depend on external libraries, frameworks, SDKs, APIs, or providers.

## Policy

- Resolve the affected dependency from its lockfile when possible.
- Prefer compatible local documentation or official versioned sources.
- Use `llms.txt` only to discover official pages.
- Record source, dependency version, documentation revision, and gaps.
- Documentation never replaces tests or review.

## Context MCP

ShipFrame recommends optional Context MCP for local, versioned documentation. ShipFrame works without Context, and installer/doctor commands never install it or edit Claude Code, Codex CLI, or OpenCode configuration automatically.

Recommended manual setup:

```bash
npm install -g @neuledge/context
claude mcp add context -- context serve
codex mcp add context -- context serve
# OpenCode: add command ["context", "serve"] under mcp.context in ~/.config/opencode/opencode.json
```

`./install.sh --doctor` reports whether the `context` binary is available and prints target-specific guidance.

## Legacy manifest sync

`project-packs/live-docs/` still documents the older `.shipframe/context-packages.txt` / `--sync-docs` flow for private projects that already use explicit manifests. It is advanced legacy support, not the recommended path for new installs.

## Troubleshooting

- Missing Context: optional warning only; install with `npm install -g @neuledge/context` if you want it.
- Version unavailable: choose an available compatible package and document the gap.
- Network unavailable: use an already installed local package or report that documentation could not be verified.
