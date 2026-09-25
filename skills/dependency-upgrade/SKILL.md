---
name: dependency-upgrade
description: Safely plan and verify dependency upgrades with compatibility, security, and rollback evidence.
---

# Dependency Upgrade

**Intent:** `deps_upgrade` — EN: dependency upgrade, update packages, bump library. ES: actualizar dependencias, subir versión de paquetes, actualización de librerías.

1. Identify the package manager, lockfiles, target dependency, current/resolved version, supported runtime, and reason for upgrading.
2. Check primary release notes and migration guidance for the target range. Preserve lockfile/package-manager consistency; do not mass-upgrade unrelated packages.
3. Review direct and transitive impact, breaking changes, security advisories, license changes, and peer/runtime constraints.
4. Upgrade the smallest coherent set. Run install in the repository's immutable/CI mode where available, plus focused tests, full relevant suite, lint/typecheck/build.
5. Report exact before/after versions, commands and outcomes, unresolved advisories, and rollback path. Do not claim production compatibility without deployment/runtime evidence.

## Host limits

Use the package manager and shell available on Claude Code, Codex CLI, or OpenCode. Never run global upgrades, alter user-level configuration, or fetch private registries without explicit authorization.

## Resumen (ES)

Identifica gestor, lockfiles y versiones; consulta notas oficiales, evalúa compatibilidad y actualiza el conjunto mínimo. Ejecuta pruebas/build y registra versión anterior/nueva, advisories y rollback; no hagas upgrades globales.
