---
name: release-checklist
description: Builds a project-aware release checklist before merge, deploy, or publication. Use when preparing any frontend, backend, library, or docs release.
allowed-tools: Read Glob Grep Bash
argument-hint: '[--target <frontend|backend|full-stack|library|docs>]'
effort: medium
---

# Release Checklist

Create a concrete release checklist from the current repo and project profile.

## Steps

1. Load `project-profile` if profile files exist.
2. Detect release target from arguments or changed files.
3. Identify the base branch, release branch, CI requirements, version/tag policy, and deploy mechanism.
4. List exact verification commands and smoke checks.
5. List rollback expectations and post-release evidence.

## Required output

```markdown
## Release Checklist

**Target:** <target>
**Base branch:** <branch>
**Version/tag policy:** <policy or n/a>
**Deploy mechanism:** <command, CI, provider, or unknown>

### Before merge
- [ ] <checks>

### Before deploy
- [ ] <checks>

### After deploy
- [ ] <smoke/evidence>

### Rollback notes
- <rollback path or "Define before deploy">

### Missing decisions
- <items or "None">
```

Do not declare a release complete from successful commands alone; require observable deploy evidence.
