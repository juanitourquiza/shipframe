# Live Docs

`live-docs` is an optional ShipFrame skill for changes that depend on external libraries, frameworks, SDKs, APIs, or providers.

## Policy

- Resolve the affected dependency from its lockfile when possible.
- Prefer compatible local documentation or official versioned sources.
- Use `llms.txt` only to discover official pages.
- Record source, dependency version, documentation revision, and gaps.
- Documentation never replaces tests or review.

## Neuledge pack

`project-packs/live-docs/` provides an optional local Neuledge Context setup for Claude Code, Codex CLI, and OpenCode. Install Neuledge explicitly, copy the manifest into the consuming project, and run:

```bash
./install.sh --sync-docs --project-dir /absolute/path/to/project --dry-run
```

The command does not install Neuledge or modify client MCP configuration. Cached packages stay outside Git. Without Neuledge, use official documentation directly.

## Troubleshooting

- Missing manifest: no-op by design.
- Missing `context`: install `@neuledge/context` explicitly, then rerun without `--dry-run`.
- Version unavailable: choose an available compatible package and document the gap.
- Network unavailable: use an already installed local package or report that documentation could not be verified.
