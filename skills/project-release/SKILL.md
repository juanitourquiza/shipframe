---
name: project-release
description: Orchestrate a generic release by loading project profile rules, running checks, and collecting deploy evidence.
allowed-tools: Read Glob Grep Bash Skill
argument-hint: '[--target <frontend|backend|full-stack|library|docs>] [--environment <name>]'
effort: high
---

# Project Release

Project Release is the generic ShipFrame release entrypoint. It must work across projects without hardcoding a specific client or product.

## Flow

1. Run `project-profile` to load repo-specific rules.
2. Run `release-checklist` to define release gates.
3. Dispatch by target:
   - frontend/static/UI changes → `frontend-release`
   - backend/API/jobs/integrations → `backend-release`
   - both → run both in dependency order from the project profile
   - docs/library-only → run the relevant checklist and evidence steps
4. Run `deploy-evidence` after deploy/publication.
5. Report final status with completed checks, evidence, gaps, and rollback notes.

## Completion rule

Do not say "done", "deployed", or "released" unless the final report includes concrete evidence for the intended environment.

## Final report

```markdown
## Project Release Report

**Target:** <target>
**Environment:** <environment>
**Version/tag/commit:** <value>

### Completed
- ✅ <item>

### Evidence
- ✅ <item>

### Gaps / follow-up
- <item or "None">

### Verdict
<Released | Not released | Partially verified>
```
