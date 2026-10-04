---
name: memory-curator
description: Curate durable project memory by extracting verified decisions and discoveries while removing stale or sensitive details.
---

# Memory Curator

**Intent:** `memory_curate` — EN: curate project memory, summarize durable learnings. ES: organizar memoria del proyecto, resumir aprendizajes duraderos.

1. Identify the memory store, ownership, retention rules, and whether the user explicitly authorized changes. If no write authorization exists, provide a proposed diff only.
   For Git-backed project memory, proceed only when `.shipframe/memory/index.md` exists and local state from `project-memory-state.sh status <repo-root>` is not `declined`. A committed index signals shared opt-in for local curation on fresh clones. It never authorizes a push, branch, PR, or publication; those require the separate `project-memory-init` publication flow and fresh confirmation.
2. Keep durable decisions, non-obvious discoveries, conventions, and verified outcomes. Separate facts from hypotheses and mark time-sensitive facts with dates.
3. Deduplicate and update the existing topic rather than creating conflicting entries. Preserve provenance and relevant file paths.
4. Remove credentials, tokens, personal data, client secrets, and unnecessary raw transcripts. Never store secrets even when supplied.
5. Validate links/paths and summarize additions, updates, deletions, and unresolved uncertainty.
6. For project memory, keep one concise note per task under `.shipframe/memory/tasks/`, update decisions only when a durable decision changes, preserve provenance/date, and never store transcripts or secrets. Engram is complementary and must never be synchronized with these files.

## Host limits

Memory APIs differ by Claude Code, Codex CLI, and OpenCode installation. Use only an explicitly configured memory backend and its supported operations; never silently create or configure one.

## Resumen (ES)

Guarda decisiones y hallazgos duraderos verificados; deduplica por tema, conserva procedencia y marca datos temporales. No escribas sin autorización ni almacenes credenciales, datos personales o transcripciones innecesarias.
