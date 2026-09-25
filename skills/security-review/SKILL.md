---
name: security-review
description: Review a scoped code change for security risks using available scanners and evidence-based manual triage.
---

# Security Review

**Intent:** `security_review` — EN: security review, threat review, vulnerability scan. ES: revisión de seguridad, análisis de vulnerabilidades, revisar amenazas.

Review the requested change and its trust boundaries; this is not a certification or substitute for specialist penetration testing.

1. Establish scope, data sensitivity, entry points, authz boundaries, dependencies, and deployment context. If scope is unclear, state assumptions and ask before widening it.
2. Inventory scanners available in the repository (for example, dependency, secret, SAST, container, or IaC tools). Do not install tools or upload source/data without authorization.
3. Run only relevant, non-destructive checks. Record exact command, version when available, exit status, and whether results are complete or partial.
4. Triage each finding with affected path/line, exploit preconditions, impact, confidence, evidence, and a concrete remediation. Separate confirmed vulnerabilities from scanner noise and unverified hypotheses.
5. Do not reproduce destructive exploits against live systems. Redact secrets and personal data from output.
6. Report coverage gaps, scanner limitations, and residual risk. Never claim “secure” or “no vulnerabilities” from a clean scan alone.

## Host limits

Claude Code, Codex CLI, and OpenCode can inspect source and run local checks when permitted. Tool availability, shell behavior, and credentials vary by host; report unavailable capabilities instead of assuming them. No host adapter is configured automatically.

## Resumen (ES)

Define alcance y límites de confianza, ejecuta solo scanners disponibles y autorizados, y registra comando/versión/resultado. Clasifica hallazgos confirmados, falsos positivos e hipótesis con evidencia, impacto y remediación; no afirmes que el sistema es seguro por un scan limpio.
