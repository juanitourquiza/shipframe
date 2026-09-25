---
name: api-contract-review
description: Review API contract changes for compatibility, versioning, validation, and consumer impact.
---

# API Contract Review

**Intent:** `api_change` — EN: API change, contract review, endpoint compatibility. ES: cambio de API, revisar contrato, compatibilidad de endpoints.

1. Identify the public contract (OpenAPI, GraphQL schema, RPC/protobuf, routes/types) and all known producers and consumers.
2. Compare old and proposed behavior: fields, nullability, defaults, errors, auth/scopes, pagination, ordering, idempotency, rate limits, and versioning.
3. Classify each change as backward-compatible, conditionally compatible, or breaking, with evidence and affected consumers.
4. Check validation and authorization at the boundary; ensure examples and generated clients match the contract.
5. Recommend migration/deprecation sequencing, compatibility tests, and rollback strategy. Do not infer compatibility solely from successful compilation.
6. Report unknown external consumers and state what evidence is missing.

## Host limits

Repository analysis is available across Claude Code, Codex CLI, and OpenCode. Live consumer traffic or provider contract checks require explicitly configured, authorized access; do not claim these from local schema checks.

## Resumen (ES)

Compara el contrato público y sus consumidores: campos, errores, auth, paginación y versionado. Clasifica compatibilidad con evidencia; propone migración, deprecación y pruebas, y declara consumidores desconocidos.
