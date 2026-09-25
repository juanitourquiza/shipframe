# React and Vite Project Pack

Guidance for React applications built with Vite. Use the Next.js pack for Next.js applications.

- Resolve React, Vite, and plugin versions from the lockfile; inspect the Vite config, base path, aliases, and build target.
- Review component state/effects, routing, accessibility, and client/server boundaries when affected.
- Treat `import.meta.env` values as public client data; never put secrets in `VITE_*` variables.
- Run repository-defined typecheck, lint, tests, and production build; smoke affected routes/assets in the intended hosting base path.
- Use `live-docs` for version-matched React/Vite APIs and official docs if Context has no compatible package.
