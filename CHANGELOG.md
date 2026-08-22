# Changelog

## Unreleased

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
