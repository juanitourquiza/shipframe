---
name: handoff
description: Compact the current conversation into a handoff document for another agent or future session.
argument-hint: "What will the next session be used for?"
disable-model-invocation: false
allowed-tools: Read Write Bash mcp__engram__mem_session_summary
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to the temporary directory of the user's OS - not the current workspace.

If Engram's `mem_session_summary` tool is available, save the same concise handoff using its required Goal / Instructions / Discoveries / Accomplished / Next Steps / Relevant Files structure. Engram is optional: always preserve the local handoff as the fallback, and never install or configure memory tooling.

Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
