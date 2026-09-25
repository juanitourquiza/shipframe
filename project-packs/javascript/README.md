# JavaScript Technology Pack

Generic ShipFrame guidance for JavaScript projects across browser and server runtimes.

- Identify browser, Node.js, edge, or mixed runtime targets before selecting APIs; don't assume browser and server globals are interchangeable.
- Resolve package versions from the lockfile and use `live-docs` for version-sensitive APIs; Context is an optional docs provider, not a JavaScript pack dependency.
- Review ESM/CommonJS boundaries, package exports, async/error handling, and untrusted input where affected.
- Run repository-defined lint, tests, type checks (if configured), and build; smoke the real entry point/runtime.
- Verify source maps, environment values, and browser bundles do not expose server-only secrets.
