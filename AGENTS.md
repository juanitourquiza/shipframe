# ShipFrame Repository Instructions

ShipFrame is an AI coding workflow toolkit for teams that plan, prove, and ship software changes.

## Stack

- Markdown-first skills and agents.
- Bash installer (`install.sh`).
- Node.js snippets embedded inside `install.sh` for JSON editing and agent conversion.
- Claude Code plugin metadata in `.claude-plugin/`.
- Codex workflow block in `codex/dev-workflow.md`.

## Repo structure

- `skills/<name>/SKILL.md` — installable skills. Keep this flat; the installer symlinks each direct child of `skills/`.
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

## Verification

Run before committing installer/workflow changes:

```bash
bash -n install.sh
python3 - <<'PY'
from pathlib import Path
bad=[]
for p in sorted(Path('skills').glob('*/SKILL.md')):
    txt=p.read_text()
    if not txt.startswith('---\n') or txt.find('\n---', 4) == -1:
        bad.append(str(p))
if bad:
    raise SystemExit('Bad skill frontmatter: ' + ', '.join(bad))
print('skill_frontmatter_ok')
PY
```

Before publishing, confirm upstream licensing for the Axis-Human base and keep `THIRD_PARTY_NOTICES.md` current.
