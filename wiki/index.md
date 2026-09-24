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
| `../skills/evidence-audit/SKILL.md` | Evidence-honesty workflow for report, handoff, PR, and release-note claims. | How should delivery claims be classified as verified, partially verified, or unverified? |
| `../skills/proof-runner/SKILL.md` | Optional command proof workflow for checklist items with `Verify:` commands. | Which planned steps were actually proven by exit-0 command evidence? |
| `../agents/` | Claude-shaped agents converted for OpenCode. | Which agents exist? How is the orchestrator represented? |

## Flows

| Page | Summary | Answers |
| ---- | ------- | ------- |
| `../codex/dev-workflow.md` | Codex routing table and lifecycle. | Which skill sequence handles each intent? |
| `../scripts/build-openai-plugin.py` | Builds the curated OpenAI/Codex plugin bundle with curated skills and a Codex CLI prompt hook. | How is the OpenAI submission bundle generated? Which hooks are included? |
| `../herdr-plugin/` | Optional local Herdr plugin MVP that opens ShipFrame workflow/checklist panes. | How does Herdr launch ShipFrame process guidance without replacing ShipFrame? |
| `../templates/pull_request_template.md` | PR/MR body skeleton used by `create-pr`. | What should generated PRs include? |

## Integrations

| Page | Summary | Answers |
| ---- | ------- | ------- |
| `../hooks/hooks.json` | Claude plugin-managed hooks, including advisory prompt routing. | Which Claude hook events are installed by the plugin? |
| `../hooks/prompt-router-core.cjs` | Shared bypass/suggest/route classifier and host-neutral guidance. | How does the cross-host fast path classify a prompt? |
| `../opencode/index.ts` | OpenCode v2 ephemeral-context plugin adapter. | How does OpenCode receive routing guidance without mutating prompt history? |
| `../.claude-plugin/plugin.json` | Claude plugin package metadata. | What version/name/keywords does the plugin expose? |
| `../.claude-plugin/marketplace.json` | Marketplace listing metadata. | Which homepage/repository/version are published? |
| `../docs/openai-plugin-submission.md` | Historical submission packet; current bundle also includes advisory Codex CLI hooks. | What claims are valid for the current local plugin bundle vs the historical submission? |

## Configuration

| Page | Summary | Answers |
| ---- | ------- | ------- |
| `live-docs.md` | Optional version-compatible external documentation workflow and Neuledge pack. | How are dependency docs selected and synchronized? |
| `../project-packs/` | Optional starter profile notes for specific stacks/projects. | What project-specific behavior should stay outside core? |
| `sync-config.md` | Wiki sync include/exclude rules. | Which files should wiki sync watch? |
