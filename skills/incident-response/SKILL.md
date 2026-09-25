---
name: incident-response
description: Coordinate evidence-led incident response, first checking access to logs, metrics, and operational consoles.
---

# Incident Response

**Intent:** `incident` — EN: production incident, outage, degradation, on-call response. ES: incidente de producción, caída, degradación, respuesta de guardia.

## First deliverable: access check

Before diagnosis, confirm authorized access to relevant logs, metrics/traces, deployment history, and provider/operational consoles. Record which sources are accessible, their time range and freshness, and which are unavailable. If access is missing, stop investigation and make the access limitation, owner, and required grant the first deliverable. Never work around access controls.

## Response

1. Establish incident lead, severity rubric, affected service/tenants, start time, impact, and communications channel. Use the project's profile/runbook; do not invent severity or promise an ETA.
2. Preserve evidence and timestamps. Prefer read-only queries. Avoid destructive actions, broad restarts, data edits, or customer communication without authorization.
3. Build a timeline from verified signals; distinguish observations, hypotheses, and unknowns.
4. Propose mitigations with risk, scope, rollback, and approval requirements. Execute only when explicitly authorized.
5. Track owner and status for containment, recovery, and follow-up. Verify recovery against agreed user-facing signals.
6. Produce a blameless postmortem using `templates/postmortem.md`; include impact, timeline, contributing factors, what worked, and owned/actionable follow-ups.

## Host limits

Claude Code, Codex CLI, and OpenCode do not imply production access. Use only credentials/tools explicitly provided and authorized in the current host session. If access is absent, do not claim an incident diagnosis or resolution.

## Resumen (ES)

Primero confirma acceso autorizado a logs, métricas/trazas, despliegues y consolas. Si falta acceso, ese es el primer entregable. Conserva evidencia, separa hechos de hipótesis, no ejecutes mitigaciones destructivas sin autorización y documenta el postmortem.
