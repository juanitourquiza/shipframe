# Changelog

## v1.1.0 — 2026-10-23

### Added
- Extend the opt-in AI PR reviewer to GitLab Merge Requests with origin-based
  GitHub/GitLab detection, idempotent `.gitlab-ci.yml` wiring, and a GitLab Notes
  API integration. The installer asks whether to enable it and lets users
  override the suggested model.
- Add GitLab CI/CD secret guidance and trusted-contributor/fork-MR safeguards;
  only project MRs are reviewed, comments are updated in place, and the job
  never pushes code.

## v1.0.0 — 2026-10-23

### Added
- Opt-in AI PR reviewer: `install.sh --pr-review <provider>` installs a GitHub
  Actions gatekeeper (`.github/workflows/shipframe-review.yml` +
  `scripts/sf_pr_review.py`) that reviews each pull request with the user's
  provider (nan-builders, claude, openai, or any custom OpenAI-compatible
  endpoint), enforces `.shipframe/profile.md` conventions when present, and
  keeps one updating comment per PR. Fork PRs are skipped; the workflow only
  comments and cannot push code.

### Fixed
- Installer test suite is now shellcheck-clean (SC2034 in the interactive
  `--pr-review` prompt) and exercises the reviewer: provider validation,
  custom-provider env requirements, templated workflow contents, template/copy
  sync, and artifact removal on uninstall. Uninstall tests pass an explicit
  `--project-dir` so they no longer touch the repository checkout.
- Flag values (`--project-dir`, `--opencode-model`, `--pr-review`) error
  cleanly when given as the last argument instead of failing on an unbound
  variable under `set -u`.
- Reviewer script: comment lookup paginates past 100 comments, non-JSON
  provider responses raise a descriptive error, the prompt fence tolerates
  triple-backtick diffs, and provider read timeouts retry once more with the
  job timeout raised to 45 minutes. Transient provider connection resets
  (`RemoteDisconnected`) now retry with backoff, and any failure is surfaced
  as a check-run annotation with its real cause. If the existing review
  comment cannot be updated (404/410), the reviewer posts a fresh one instead
  of failing.
- Security: the workflow pins `scripts/sf_pr_review.py` to the base branch
  before running it, so a same-repo PR cannot tamper with the reviewer to
  exfiltrate `SF_REVIEW_API_KEY` (the fork guard alone did not cover this).
- Correctness: a missing or empty diff now fails the review (fail closed)
  instead of letting the model post a false approval; the diff step no
  longer swallows git errors with `|| true`.
- Hardening: interactive provider choice is validated, double quotes are
  rejected in custom base URL/model (they broke the generated workflow),
  the `::error` annotation collapses newlines, stale review comments are
  deleted so only one remains, uninstall removes now-empty directories, and
  the help documents that `--pr-review` requires an install target.

## v0.8.4 — 2026-10-12

### Changed
- Raised the code-review quality bar with concrete materiality criteria, scoped findings, and consistent severity across review phases, without mandating line-count or design-pattern rules.
- Updated the Axis-Human upstream notice to reflect its currently published MIT license while retaining source attribution.

## v0.8.3 — 2026-10-07

### Fixed
- Enforced read-only permissions for the reviewer agent, preventing shell access and restricting review tools to read-only operations.

## v0.8.2 — 2026-10-06

### Fixed
- Enforced normalized routing parity across Codex, README, and Claude/OpenCode orchestrator paths, including QA conditions and host-agent expansions.
- Corrected the refactor workflow to include the QA/TDD gate for non-trivial code changes.

### Changed
- Versioned routing metadata as schema v2 and documented aliases and host variants.

## v0.8.1 — 2026-10-05

### Added
- Added opt-in native Codex subagent roles for read-only code exploration and independent diff review; the installer preserves user configuration and unmanaged profiles.
- Updated Codex workflow guidance to use native child agents when available and report honestly when delegation cannot be performed.


## v0.8.0 — 2026-10-03

### Added
- Added opt-in Git-backed project memory at `.shipframe/memory/` with repository-local consent, provenance-aware refresh/curation, and explicit GitHub Draft PR safeguards; Engram remains recommended, optional, and independent.
- Added installer guidance and consistent project-memory setup routing across Claude Code, Codex CLI, OpenCode, OpenWork, and the curated OpenAI/Codex plugin.
- Added regression coverage for consent-state isolation, memory workflow privacy boundaries, installer suggestions, and safe handling of Git-config sandbox restrictions.


## v0.7.4 — 2026-10-01

### Fixed
- Install OpenWork skills as managed physical folders so its Library indexes them; preserve modified/unmanaged folders and restore prior Claude skill links only when appropriate.

## v0.7.3 — 2026-10-01

### Fixed
- Installed the shared ShipFrame skill catalog under `~/.claude/skills` for Claude Code and OpenWork discovery; included it in doctor, repair, and uninstall flows.

## v0.7.2 — 2026-10-01

### Added
- Added a CI checker for required skill and agent metadata, naming consistency, and actionable diagnostics.
- Formalized the QA `small` fast path as reduced test depth only, with risk exclusions and mandatory independent final review.

## v0.7.1 — 2026-09-30

### Fixed
- Kept `--repair` read-only unless `--yes` is explicitly supplied, including Codex and OpenCode targets.
- Safely read plugin version metadata from checkout paths containing spaces or apostrophes.
- Corrected broken resource references in the bug-diagnosis and wiki-init skills.

## v0.7.0 — 2026-09-29

### Added
- Added a preventive security-hardening workflow with conditional implementation guidance, distinct from evidence-based security review.
- Routed natural English and Spanish hardening requests through the advisory prompt fast path.

### Changed
- Expanded the curated ChatGPT/Codex plugin bundle to 31 selected skills.

## v0.6.1 — 2026-09-25

### Added
- Added JavaScript, TypeScript, PHP, Node.js, React/Vite, Python, and Rust technology packs; expanded the existing Angular and Laravel packs and added stack-based pack suggestions in `init-project`.
- Added opt-in, project-aware Context MCP guidance to `init-project` and version-matched documentation steps to `live-docs`.

### Changed
- Reclassified starter guidance as technology packs (language/runtime vs framework/build) and clarified that Context supplies version-aware reference docs rather than pack workflows.

## v0.6.0 — 2026-09-25

This consolidated release closes the four-wave roadmap; the intermediate wave labels were planning targets, not separately published artifacts.

### Added
- Added scoped security review, end-to-end verification, dependency upgrade, API contract review, incident response, and memory curation skills, with bilingual intent guidance and host limits.
- Added starter project packs for Next.js, NestJS, FastAPI, and Go, plus incident runbook and postmortem templates.
- Centralized workflow intent sequences in `routing.json` and added parity coverage for Codex, README, and orchestrator routing.

### Changed
- Added optional, change-triggered performance checks and migration guidance to release workflows; expanded the curated plugin bundle to 30 selected skills.
- Updated OpenCode v2 activation guidance and added environment-doctor checks for missing, invalid, or disabled local router plugins.

### Fixed
- Made the OpenCode prompt-router plugin load from symlinked install paths (such as the Homebrew Cellar) by importing `@opencode/plugin` as a type only, so OpenCode no longer reports `Plugin failed: .../shipframe-prompt-router`.
- Return the OpenCode context-hook cleanup callback so unloading the plugin disposes its registration and clears per-session deduplication state.

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
