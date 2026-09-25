---
name: e2e-verify
description: Plan and execute end-to-end verification with explicit scope, test data, environments, and acceptance criteria.
---

# End-to-End Verify

**Intent:** `e2e_test` — EN: end-to-end test, browser flow, user journey verification. ES: prueba end-to-end, flujo de navegador, verificar recorrido de usuario.

1. Define the user journey, entry URL, environment, supported browsers/hosts, preconditions, test data, cleanup, and pass/fail criteria before running tests.
2. Inspect existing test tools and scripts first. Prefer existing Playwright/Cypress/framework conventions; do not add dependencies without approval.
3. Use synthetic or explicitly approved accounts/data. Never expose credentials in logs, screenshots, traces, or reports. Avoid destructive production actions.
4. Run the narrowest representative flow, then relevant regression coverage. Capture command, environment, result, and artifact locations.
5. Distinguish a browser automation pass from backend/provider/live-tenant proof. Report blocked, skipped, flaky, and manually verified cases separately.
6. Clean up created data when safe and authorized; state anything left behind.

## Host paths and limits

- Claude Code: use the project's configured browser/test tooling; browser-control availability is environment-specific.
- Codex CLI: use available terminal/browser tools and repository scripts; a static check is not browser proof.
- OpenCode: use configured tools/plugins only; do not assume browser control is installed.

All paths require explicit test scope and data. No host receives implicit credentials or third-party configuration.

## Resumen (ES)

Define recorrido, entorno, datos sintéticos/autorizados, criterios y limpieza antes de probar. Separa automatización local de evidencia en producción/proveedor, protege credenciales y reporta casos omitidos, inestables o bloqueados.
