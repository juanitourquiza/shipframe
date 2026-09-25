---
name: backend-release
description: Verify backend/API releases with tests, migrations, queues, integrations, and endpoint smoke checks.
allowed-tools: Read Glob Grep Bash
argument-hint: '[--app <name>] [--environment <name>]'
effort: medium
---

# Backend Release

Use for Laravel, Node, Python, Rails, Go, or other backend/API releases.

## Steps

1. Load `project-profile` for app-specific release rules.
2. Detect framework, package manager, and runtime.
3. Identify migrations, queues, scheduled jobs, webhooks, and external integrations affected by the diff.
4. Check framework-specific migration/deprecation steps and compatibility windows; use the project's framework pack when present.
5. Run or list exact checks: dependency validation, lint/static analysis, tests, build/compile. Optionally run a performance check when the diff changes hot paths, query volume, concurrency, or resource use; record a baseline and avoid unsupported thresholds.
6. Check required env/config changes are documented and not committed as secrets.
7. Smoke health endpoints and affected API routes in the intended environment.
8. Run `deploy-evidence` before declaring completion.

Never mark complete from a green CI job alone; smoke the intended runtime environment.
