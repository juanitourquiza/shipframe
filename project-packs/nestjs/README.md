# NestJS Project Pack

Generic release and review notes for NestJS services.

- Detect transport (HTTP, GraphQL, microservice), modules, guards/interceptors/pipes, and validation strategy.
- Check provider injection scope, DTO validation/transformation, auth guards, OpenAPI output, and exception mapping when affected.
- Inspect ORM migrations, queues, scheduled jobs, and event consumers before release.
- Run repository-defined lint, typecheck, tests, build, and migration checks; smoke the intended transport and health/readiness endpoints.
- Do not assume a database/provider is reachable from local tests; report live integration proof separately.
