---
name: frontend-release
description: Prepares and verifies frontend releases with project-aware build, route smoke, assets, i18n, and version checks.
allowed-tools: Read Glob Grep Bash
argument-hint: '[--app <name>] [--environment <name>]'
effort: medium
---

# Frontend Release

Use for Angular, React, Vue, Svelte, static, or SPA frontend releases.

## Steps

1. Load `project-profile` for app-specific release rules.
2. Detect framework and package manager from repo files.
3. Identify build output policy: committed artifact, CI artifact, or platform build.
4. Run or list exact checks: install status, lint, typecheck, tests, build.
5. Inspect generated entrypoints and lazy chunks where relevant.
6. Smoke public routes and app routes required by the profile.
7. Run `deploy-evidence` before declaring completion.

## Required checks to consider

- Version or build identifier where the project has one.
- i18n files when visible text changes.
- Critical routes and auth redirects.
- Console/network errors for browser apps when browser tooling is available.
- Static asset paths and cache-sensitive files.

Never mark complete without exact environment smoke evidence.
