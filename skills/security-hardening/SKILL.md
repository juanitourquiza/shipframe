---
name: security-hardening
description: Apply practical security controls while designing or implementing software changes.
---

# Security Hardening

**Intent:** `security_hardening` — EN: secure implementation, security hardening, secure coding. ES: endurecimiento de seguridad, programación segura, proteger una implementación.

Apply focused preventive controls to the requested design or implementation. Keep recommendations proportional to the change and its trust boundaries; do not turn this workflow into a full security audit.

## Hardening checklist

- Validate and normalize untrusted input at trust boundaries; use parameterized queries and context-appropriate output encoding.
- Enforce authorization as well as authentication, including per-user or per-tenant isolation where applicable.
- Protect sessions and cookies with appropriate scope, expiry, rotation, and secure attributes; avoid exposing secrets or sensitive data in logs, errors, URLs, or client storage.
- Check dependency and external-integration boundaries for least privilege, safe defaults, timeouts, and failure handling.
- Add or update focused tests for relevant security controls and negative cases.
- Make changes only within the approved task scope. If only guidance is requested, return a concise checklist; do not edit files or start an implementation workflow yourself.

For a requested code change, provide a short, change-specific checklist to `implement-task`; continue its existing workflow without invoking it recursively. If the user requests a scoped security audit, scanner run, or evidence-based finding triage, hand off to `security-review` instead.

## Host limits

Claude Code, Codex CLI, and OpenCode can inspect source and suggest local controls when permitted. Tool availability, shell behavior, and credentials vary by host; report unavailable capabilities instead of assuming them. Do not install tools, upload source/data, or test live systems without authorization.

## Resumen (ES)

Aplica controles preventivos proporcionales al cambio: valida entradas en fronteras, parametriza consultas, codifica salidas según contexto, protege autenticación/autorización, sesiones, cookies, secretos y datos sensibles; revisa dependencias e integraciones y añade pruebas negativas. Respeta el alcance aprobado. Para implementar, entrega una lista breve a `implement-task` sin invocarlo recursivamente; deriva a `security-review` cuando se solicite una auditoría con evidencia.
