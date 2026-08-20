---
name: project-profile
description: Read project-specific workflow rules before releases, deploys, onboarding, or custom repository conventions.
allowed-tools: Read Glob Grep Bash
effort: low
---

# Project Profile

Load project-specific rules that customize the generic ShipFrame workflow.

## Lookup order

1. `shipframe.profile.md`
2. `.shipframe/profile.md`
3. `.shipframe/project-profile.md`
4. `AGENTS.md` sections mentioning ShipFrame, release, deploy, PR, tickets, or project rules
5. `WIKI.md` and `wiki/sync-config.md` for documented repo boundaries

## What to extract

- Repo topology: root app, nested apps, multi-repo dependencies, generated artifacts.
- Branching and release rules: base branch, protected branches, tags, release notes.
- Verification rules: build, lint, tests, smoke URLs, screenshots, API checks.
- Product rules: i18n, approved copy, client constraints, analytics, access control.
- Deployment evidence: what must be shown before saying work is done.

## Output

Return a concise profile summary:

```markdown
## Project Profile Loaded

**Source files:** <paths read>
**Repo topology:** <summary>
**Release rules:** <summary>
**Verification rules:** <summary>
**Project-specific constraints:** <summary>
**Missing/unclear:** <items or "None">
```

If no profile exists, state that ShipFrame will use the generic workflow and recommend creating `.shipframe/profile.md` for repeatable project rules.
