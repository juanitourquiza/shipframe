# Index — ShipFrame

Master catalog of all wiki pages. Mandatory entry point for any query with `/wiki-query`.

## Architecture

| Page | Summary | Answers |
| ---- | ------- | ------- |
| `../AGENTS.md` | Repository structure, conventions, verification gates, and public-core boundaries. | Where do skills/agents live? What must change with docs? What checks run before commit? |

## Modules

| Page | Summary | Answers |
| ---- | ------- | ------- |
| `../install.sh` | Multi-tool installer for Claude Code, OpenWork physical skill copies, OpenCode, and Codex with doctor/repair/uninstall flows. | How are artifacts installed? How are managed files repaired or removed? |
| `../skills/` | Flat installable skill catalog. | Which skills are linked into Codex/OpenCode? |
| `../skills/evidence-audit/SKILL.md` | Evidence-honesty workflow for report, handoff, PR, and release-note claims. | How should delivery claims be classified as verified, partially verified, or unverified? |
| `../skills/proof-runner/SKILL.md` | Optional command proof workflow for checklist items with `Verify:` commands. | Which planned steps were actually proven by exit-0 command evidence? |
| `../skills/security-review/SKILL.md` | Evidence-based security triage using available, scoped scanners. | How should scan coverage, findings, and residual risk be reported? |
| `../skills/security-hardening/SKILL.md` | Preventive security controls for designs and implementation changes. | Which security controls should be applied at trust boundaries, and when should work hand off to security review? |
| `../skills/e2e-verify/SKILL.md` | End-to-end verification with explicit test data and criteria. | How are host/browser limits and live-system proof distinguished? |
| `../skills/dependency-upgrade/SKILL.md` | Safe, narrow dependency upgrade workflow. | How are version compatibility and rollback proven? |
| `../skills/api-contract-review/SKILL.md` | API compatibility and consumer-impact review. | How are contract changes classified and migrated? |
| `../skills/incident-response/SKILL.md` | Evidence-led incident workflow with access check first. | What is the first deliverable when operational access is missing? |
| `../skills/memory-curator/SKILL.md` | Durable memory curation with explicit authorization. | What belongs in memory and what must be excluded? |
| `../skills/project-memory-init/SKILL.md` | Opt-in Git-backed project memory with explicit GitHub publication safeguards. | How is project memory enabled and safely shared? |
| `../agents/` | Claude-shaped agents converted for OpenCode. | Which agents exist? How is the orchestrator represented? |
| `../docs/qa-fast-path.md` | Bilingual QA-small eligibility, review guarantee, and metadata checker commands. | When may test depth be reduced, and what remains mandatory? |

## Flows

| Page | Summary | Answers |
| ---- | ------- | ------- |
| `../codex/dev-workflow.md` | Codex routing table and lifecycle. | Which skill sequence handles each intent? |
| `../routing.json` | Canonical intent-to-workflow map. | Which workflow sequence is the source of truth for each intent? |
| `../scripts/build-openai-plugin.py` | Builds the curated OpenAI/Codex plugin bundle with curated skills and a Codex CLI prompt hook. | How is the OpenAI submission bundle generated? Which hooks are included? |
| `../scripts/opencode-doctor.cjs` | Inspects the installed OpenCode router adapter and explicit disable directives without printing user configuration. | How does environment doctor distinguish absent, invalid, and disabled plugins? |
| `../herdr-plugin/` | Optional local Herdr plugin MVP that opens ShipFrame workflow/checklist panes. | How does Herdr launch ShipFrame process guidance without replacing ShipFrame? |
| `../templates/pull_request_template.md` | PR/MR body skeleton used by `create-pr`. | What should generated PRs include? |
| `../templates/postmortem.md` | Blameless incident postmortem template with evidence gaps. | How should incident impact, timeline, and follow-ups be recorded? |

## Integrations

| Page | Summary | Answers |
| ---- | ------- | ------- |
| `../hooks/hooks.json` | Claude plugin-managed hooks, including advisory prompt routing. | Which Claude hook events are installed by the plugin? |
| `../hooks/prompt-router-core.cjs` | Shared bypass/suggest/route classifier and host-neutral guidance. | How does the cross-host fast path classify a prompt? |
| `../opencode/index.ts` | OpenCode v2 ephemeral-context adapter that returns hook cleanup on unload. | How does OpenCode receive routing guidance and dispose the hook lifecycle safely? |
| `../.claude-plugin/plugin.json` | Claude plugin package metadata. | What version/name/keywords does the plugin expose? |
| `../.claude-plugin/marketplace.json` | Marketplace listing metadata. | Which homepage/repository/version are published? |
| `../docs/openai-plugin-submission.md` | Historical submission packet; current bundle also includes advisory Codex CLI hooks. | What claims are valid for the current local plugin bundle vs the historical submission? |

## Configuration

| Page | Summary | Answers |
| ---- | ------- | ------- |
| `live-docs.md` | Optional version-compatible external documentation workflow and Context MCP guidance. | How are dependency docs selected, version-matched, and sourced? |
| `../project-packs/` | Optional language/runtime, framework/build, and project profile guides. | What stack-specific workflow guidance is available? |
| `sync-config.md` | Wiki sync include/exclude rules. | Which files should wiki sync watch? |
| `../project-packs/incident-runbook.md` | Starter incident runbook, observability, and alert checklist. | What operational access and response details should a project profile document? |
| `../docs/roadmap-v0.6.0.md` | Four-wave roadmap and independent release-surface policy. | What closes the v0.6.0 initiative, and what is explicitly out of scope? |
