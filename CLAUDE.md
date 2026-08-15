# ShipFrame

ShipFrame is an AI coding workflow toolkit for teams that plan, prove, and ship software changes with disciplined agent workflows.

## Wiki

This project has a documented knowledge wiki. Before investigating the codebase for any architecture, module, pattern, or domain question, **always read `WIKI.md` first** and use `/wiki-query` to find documented information.
Do not grep the codebase for facts that may already be in the wiki.

- Entry point: `WIKI.md`
- Full catalog: `wiki/index.md`

## Project conventions

- Keep the public core generic and team-friendly.
- Put project-specific behavior in project profiles or packs.
- Preserve tool support for Claude Code, Codex CLI, and OpenCode.
- Do not hardcode PULSAI-specific release behavior into the public core.
