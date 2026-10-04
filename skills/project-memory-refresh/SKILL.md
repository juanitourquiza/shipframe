---
name: project-memory-refresh
description: Refresh project context from memory, WIKI/AGENTS files, git state, and repo conventions before work.
allowed-tools: Read Glob Grep Bash mcp__engram__mem_context mcp__engram__mem_search
effort: low
---

# Project Memory Refresh

Before changing a project, recover the relevant working context.

## Steps

1. Read `WIKI.md`, `wiki/index.md`, and `AGENTS.md` if present.
2. Inspect git status, current branch, remotes, and recent commits.
3. Search local documentation for the task keywords.
4. If `.shipframe/memory/index.md` exists, check `shipframe.memory.setup` in local Git config (or invoke `project-memory-state.sh status <repo-root>` from the installed skill bundle). A local `declined` state means skip project memory for this checkout; `enabled` activates it. Otherwise read the index and only relevant linked notes. A committed index is the team opt-in signal for a fresh clone; it is not permission to publish changes.
5. If Engram memory tools are available, call `mem_context` for the project; if recent context does not cover the task, use `mem_search` with focused keywords. If unavailable, continue from local memory/docs without installing or configuring anything. Engram and Git-backed memory are independent and must never be synchronized.
6. Treat current code, canonical docs, and live runtime as authoritative. Include source/date for memory-derived claims and flag stale, unmerged, or contradictory entries. Never write or update memory in this refresh step.
7. Summarize prior decisions, conventions, and likely drift-prone facts; flag what still needs live verification.

## Output

```markdown
## Project Context Refreshed

**Repo state:** <branch/status/remotes>
**Docs read:** <paths>
**Relevant conventions:** <bullets>
**Needs verification:** <bullets or "None">
```
