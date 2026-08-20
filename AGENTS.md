# ShipFrame Repository Instructions

ShipFrame is an AI coding workflow toolkit for teams that plan, prove, and ship software changes.

## Stack

- Markdown-first skills and agents.
- Bash installer (`install.sh`).
- Node.js snippets embedded inside `install.sh` for JSON editing and agent conversion.
- Claude Code plugin metadata in `.claude-plugin/`.
- Codex workflow block in `codex/dev-workflow.md`.

## Repo structure

- `skills/<name>/SKILL.md` — installable skills. Keep this flat; the installer symlinks each direct child into host skill directories (`~/.agents/skills`, `~/.codex/skills`, `~/.config/opencode/skills`).
- `agents/*.md` — Claude/OpenCode-oriented agents.
- `codex/dev-workflow.md` — Codex routing workflow inlined into `~/.codex/AGENTS.md` by the installer.
- `templates/` — PR, issue, ClickUp, and wiki templates.
- `project-packs/` — optional project profile starters; do not hardcode these rules into generic core skills.
- `wiki/` and `WIKI.md` — local knowledge wiki.

## Conventions

- Keep ShipFrame core generic and team-friendly.
- Put project-specific behavior in `.shipframe/profile.md`, `shipframe.profile.md`, or `project-packs/`.
- Do not hardcode PULSAI or any client-specific release behavior into public core skills.
- Preserve support for Claude Code, Codex CLI, and OpenCode when changing installer or workflow files.
- For release-related behavior, require concrete deploy evidence before declaring work complete.
- Keep documentation current in the same change: whenever installer behavior, user-facing commands, workflow routing, public skill behavior, release process, or project conventions change, update README and any affected repo docs before committing/releasing.

## Verification

Run before committing installer/workflow changes:

```bash
bash -n install.sh
shellcheck install.sh
./install.sh --doctor --repo-only
./tests/test-install.sh
claude plugin validate .
```

`--doctor --repo-only` is the CI-safe gate. It must not depend on user auth,
installed Claude/OpenCode/Codex binaries, or global HOME state.

Before publishing, confirm upstream licensing for the Axis-Human base and keep `THIRD_PARTY_NOTICES.md` current.
