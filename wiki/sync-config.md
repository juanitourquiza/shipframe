# Wiki Sync — Repository Configuration

Read automatically by `/wiki-sync` at the start of each sync.
Edit this file to add, remove, or modify source repos.

## Repositories

| Name | Relative path | Stack |
|------|---------------|-------|
| shipframe | . | Markdown, shell, AI agent skills |

## Patterns with wiki impact

- `README.md`
- `install.sh`
- `codex/*.md`
- `agents/*.md`
- `skills/*/SKILL.md`
- `templates/**/*.md`
- `.claude-plugin/*.json`

## Patterns without wiki impact

- `.git/`
- `node_modules/`
- `dist/`
- `build/`
- `.env*`
- binary assets
