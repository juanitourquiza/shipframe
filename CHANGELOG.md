# Changelog

## Unreleased

## v0.4.8 — 2026-09-23

### Added
- Added an advisory cross-host prompt fast path for Claude Code, Codex CLI, and OpenCode, with bypass, suggest, and route outcomes.
- Added explicit opt-in host adapters; Codex requires trusted hooks and OpenCode plugin registration remains user-controlled.


## v0.4.7 — 2026-09-23

### Fixed
- Aligned Claude plugin and marketplace metadata for the next release without rewriting the existing v0.4.6 tag.
- Updated OpenCode MCP setup guidance for the v2 `mcp.servers` configuration shape.
- Hardened installer preflight, target handling, legacy settings backup, and converted-agent tool parsing.
- Added missing installer regression coverage to CI and corrected the wiki index table.

## v0.4.6 — 2026-09-22

### Added
- Recommended optional Context MCP for Live Docs and added target-specific setup guidance for Claude Code, Codex CLI, and OpenCode.

### Changed
- Kept installation and doctor non-blocking when Context MCP is absent; no package installation or client configuration changes occur automatically.
- Preserved `--sync-docs` as labeled legacy/advanced compatibility.

## v0.4.5 — 2026-09-16

### Added
- Published the Herdr local workflow plugin as an official ShipFrame surface with GitHub subdirectory install docs.
- Added the `herdr-plugin` marketplace/repository topic for Herdr discovery.

### Changed
- Clarified that Homebrew installs the base ShipFrame toolkit, while Herdr integration is installed separately with `herdr plugin install`.

## v0.4.4 — 2026-09-08

### Added
- Added optional `proof-runner` skill for running explicit `Verify:` commands from plans/checklists and reporting only exit-0 proof.

### Changed
- Expanded the curated ChatGPT/Codex plugin bundle from 23 to 24 public ShipFrame skills.
- Documented proof-running as an optional high-risk change/release/client-work guardrail alongside evidence audits and deploy evidence.


## v0.4.3 — 2026-09-03

### Added
- Added `evidence-audit` to classify delivery claims as verified, partially verified, or unverified.
- Added the OpenAI/Codex plugin build test to CI so curated bundle drift is caught automatically.

### Changed
- Expanded the curated ChatGPT/Codex plugin bundle from 22 to 23 public ShipFrame skills.
- Updated release documentation to emphasize evidence-honest claims.


## v0.4.2 — 2026-08-21

### Added
- Expanded the curated OpenAI/Codex plugin bundle from 12 to 22 public ShipFrame skills.
- Added TDD, research, accessibility, frontend/backend release, MCP debugging, README generation, and codebase design workflows to the plugin distribution.

### Changed
- Updated OpenAI/Codex plugin metadata and docs to describe the curated ChatGPT/Codex plugin separately from the full GitHub/Homebrew toolkit.


## v0.4.1 — 2026-08-20

### Added
- Added skills-picker discovery docs for Claude Code, Codex CLI, and OpenCode.
- Added Codex Agent Skills symlinks in `~/.agents/skills` while preserving `~/.codex/skills` compatibility.

### Changed
- Shortened skill frontmatter descriptions so host skill pickers can match ShipFrame skills more reliably.
- Updated README skill/routing documentation to cover skills-picker invocation.

## v0.4.0 — 2026-08-20

### Added
- Added read-only installer diagnostics with `--doctor` and CI-safe `--doctor --repo-only`.
- Added dry-run-first `--repair` and `--uninstall` flows with `--yes` to apply changes.
- Added ShipFrame install ownership state at `${XDG_STATE_HOME:-~/.local/state}/shipframe/install-state.json`.
- Added installer regression tests under `tests/test-install.sh` and GitHub Actions CI for Linux/macOS.
- Added Codex managed block version marker: `shipframe-block-version: 1`.

### Changed
- Claude Code hooks are now treated as plugin-managed through `hooks/hooks.json`; legacy exact hooks in `~/.claude/settings.json` are removed only via repair/uninstall.
- OpenCode converted agents inherit the user's global OpenCode model by default. Explicit model overrides require `--opencode-model provider/model`.
- Claude agent model fields now use stable aliases (`opus`, `sonnet`) instead of date/version-specific IDs.
- Codex installer leaves `~/.codex/config.toml` and model selection untouched.

### Fixed
- Removed unsupported top-level `license` from `.claude-plugin/marketplace.json`.
- Updated README skill/routing documentation to cover the current skill catalog and Codex workflow.

### Deferred
- `profile-lint` and `security-audit` skills move to v0.4.1 after the profile schema contract is finalized.
- Provider abstraction for ClickUp/GitHub Issues/Linear, new routing intents, and full Next/Nest project packs move to v0.5.
