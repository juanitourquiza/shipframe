# Python Technology Pack

Framework-agnostic ShipFrame guidance for Python applications and libraries; use FastAPI for additional ASGI-specific checks.

- Resolve Python and dependency versions from the lockfile or environment manager; distinguish declared ranges from locked versions.
- Inspect project packaging, import layout, type-check/lint configuration, async boundaries, and supported Python versions.
- Run repository-defined formatter, linter, type checker, tests, and build/package checks; don't assume pytest or a specific manager.
- Check resource/lifespan cleanup, concurrency, migrations, and background work when affected.
- Use `live-docs` for APIs matching the resolved package version; fall back to official versioned docs when needed.
