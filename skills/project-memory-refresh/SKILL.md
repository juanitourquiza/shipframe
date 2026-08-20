---
name: project-memory-refresh
description: Refresh project context from memory, WIKI/AGENTS files, git state, and repo conventions before work.
allowed-tools: Read Glob Grep Bash
effort: low
---

# Project Memory Refresh

Before changing a project, recover the relevant working context.

## Steps

1. Read `WIKI.md`, `wiki/index.md`, and `AGENTS.md` if present.
2. Inspect git status, current branch, remotes, and recent commits.
3. Search local documentation for the task keywords.
4. Summarize prior decisions, conventions, and likely drift-prone facts.
5. Flag what still needs live verification.

## Output

```markdown
## Project Context Refreshed

**Repo state:** <branch/status/remotes>
**Docs read:** <paths>
**Relevant conventions:** <bullets>
**Needs verification:** <bullets or "None">
```
