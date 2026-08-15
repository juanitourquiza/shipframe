# PULSAI Project Profile

Optional ShipFrame profile for PULSAI-like projects. Keep these rules out of the public core and load them through `project-profile` when the target repo opts in.

## Recommended location in a project

Copy the relevant rules into one of:

- `.shipframe/profile.md`
- `shipframe.profile.md`
- `AGENTS.md` project-specific sections

## Release defaults

- Treat backend/root and frontend `/web` as separate repos unless the current project proves otherwise.
- Do not declare production success without CI/deploy evidence and exact-path smoke evidence.
- For public frontend releases, verify app version, tag, release notes, lazy chunks, and critical routes.
- Keep visible frontend strings synchronized across EN/ES locales.
- Distinguish shipped production behavior from demos, drafts, experiments, and plans.

## MCP/Garmin defaults

- Stored connector status only proves token storage, not live upstream validity.
- Use live MCP/tool evidence before answering health, Garmin, Apple Health, or workout questions.
- Never present last recorded device location as live tracking.
