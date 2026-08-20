---
name: mcp-debugging
description: Diagnose MCP connector failures by separating stored connection state from live upstream tool evidence.
allowed-tools: Read Glob Grep Bash
argument-hint: '[--connector <name>]'
effort: medium
---

# MCP Debugging

Use when an MCP connector, tool, token, or upstream integration appears connected but behavior fails.

## Principles

- Stored connection state is not proof that the upstream service accepts the token/session.
- Prefer a live tool call or minimal endpoint check that exercises the failing capability.
- Capture exact error codes, tool names, timestamps, and sanitized payloads.
- Never expose secrets, tokens, cookies, or auth headers.

## Output

```markdown
## MCP Debug Report

**Connector:** <name>
**Claimed state:** <configured/active/unknown>
**Live check:** <command/tool and result>
**Root cause:** <best-supported cause or unknown>
**User action needed:** <reconnect, grant permission, rotate token, none>
**Evidence:** <sanitized snippets>
```
