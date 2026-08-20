# Index — ShipFrame

Master catalog of all wiki pages. Mandatory entry point for any query with `/wiki-query`.

## Architecture

| Page | Summary | Answers |
| ---- | ------- | ------- |
| `../AGENTS.md` | Repository structure, conventions, verification gates, and public-core boundaries. | Where do skills/agents live? What must change with docs? What checks run before commit? |

## Modules

| Page | Summary | Answers |
| ---- | ------- | ------- |
| `../install.sh` | Multi-tool installer for Claude Code, OpenCode, and Codex with doctor/repair/uninstall flows. | How are artifacts installed? How are managed files repaired or removed? |
| `../skills/` | Flat installable skill catalog. | Which skills are linked into Codex/OpenCode? |
| `../agents/` | Claude-shaped agents converted for OpenCode. | Which agents exist? How is the orchestrator represented? |

## Flows

| Page | Summary | Answers |
| ---- | ------- | ------- |
| `../codex/dev-workflow.md` | Codex routing table and lifecycle. | Which skill sequence handles each intent? |
| `../templates/pull_request_template.md` | PR/MR body skeleton used by `create-pr`. | What should generated PRs include? |

## Integrations

| Page | Summary | Answers |
| ---- | ------- | ------- |
| `../hooks/hooks.json` | Claude plugin-managed hooks. | Which Claude hook events are installed by the plugin? |
| `../.claude-plugin/plugin.json` | Claude plugin package metadata. | What version/name/keywords does the plugin expose? |
| `../.claude-plugin/marketplace.json` | Marketplace listing metadata. | Which homepage/repository/version are published? |

## Configuration

| Page | Summary | Answers |
| ---- | ------- | ------- |
| `../project-packs/` | Optional starter profile notes for specific stacks/projects. | What project-specific behavior should stay outside core? |
| `sync-config.md` | Wiki sync include/exclude rules. | Which files should wiki sync watch? |
