# Node.js Runtime Pack

Runtime-focused ShipFrame guidance for Node.js projects; use framework packs such as NestJS or Next.js for framework-specific checks.

- Resolve the runtime target from `engines`, `.nvmrc`/`.node-version`, CI, and deployment config; report conflicts instead of guessing.
- Use the lockfile to identify package-manager and dependency versions; inspect ESM/CommonJS mode, exports, and supported Node releases.
- Check process signals/shutdown, async error handling, child processes, streams, and resource cleanup when affected.
- Run repository-defined lint, typecheck, tests, and build; smoke the actual CLI/server entry point on the supported runtime.
- Use `live-docs` for version-matched Node.js or package APIs when documentation is needed.
