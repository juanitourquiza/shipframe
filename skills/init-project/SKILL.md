---
name: init-project
description: Scan a new or unfamiliar repo and generate AGENTS.md with stack, commands, structure, and agent context.
allowed-tools: Glob Read Grep Write
effort: medium
---

# init-project

Scan the current project and detect its full tech stack, then generate an `AGENTS.md` file with structured context so future Claude agents have everything they need to work effectively in this codebase.

## Steps

### 1. Scan for stack indicators

Search the project root and subdirectories for the following files and patterns. Use Glob and Read tools — do not guess.

**Languages & runtimes**
- `package.json` → Node.js / JavaScript / TypeScript
- `tsconfig.json` → TypeScript
- `requirements.txt`, `pyproject.toml`, `setup.py`, `Pipfile` → Python
- `Cargo.toml` → Rust
- `go.mod` → Go
- `pom.xml`, `build.gradle`, `build.gradle.kts` → Java / Kotlin
- `*.csproj`, `*.sln` → C# / .NET
- `Gemfile` → Ruby
- `composer.json` → PHP
- `pubspec.yaml` → Dart / Flutter

**Frameworks**
- In `package.json` dependencies/devDependencies: look for `next`, `react`, `vue`, `svelte`, `angular`, `express`, `fastify`, `hono`, `remix`, `astro`, `nuxt`, `gatsby`
- In Python files: look for `django`, `flask`, `fastapi`, `sqlalchemy`
- In `Cargo.toml`: look for `axum`, `actix-web`, `rocket`
- In `go.mod`: look for `gin`, `echo`, `fiber`

**Databases & ORMs**
- In dependency files: look for `prisma`, `drizzle-orm`, `typeorm`, `sequelize`, `mongoose`, `pg`, `mysql2`, `sqlite3`, `redis`, `supabase`, `@planetscale`, `@neon`
- Config files: `prisma/schema.prisma`, `drizzle.config.*`

**Styling**
- `tailwind.config.*` → Tailwind CSS
- In `package.json`: `styled-components`, `@emotion`, `sass`, `less`, `@mui`, `@chakra-ui`, `@radix-ui`, `shadcn`

**Build tools & bundlers**
- `vite.config.*` → Vite
- `webpack.config.*` → Webpack
- `turbo.json` → Turborepo
- `nx.json` → Nx
- `rollup.config.*` → Rollup
- `.swcrc` → SWC

**Testing**
- In `package.json`: `jest`, `vitest`, `@testing-library`, `playwright`, `cypress`, `mocha`
- `pytest.ini`, `conftest.py` → pytest
- `jest.config.*`, `vitest.config.*`

**Infrastructure & deployment**
- `Dockerfile`, `docker-compose.*` → Docker
- `.github/workflows/` → GitHub Actions
- `vercel.json`, `.vercel/` → Vercel
- `netlify.toml` → Netlify
- `fly.toml` → Fly.io
- `terraform/`, `*.tf` → Terraform
- `kubernetes/`, `k8s/`, `*.yaml` with `kind: Deployment` → Kubernetes

**Monorepo**
- `pnpm-workspace.yaml` → pnpm workspaces
- `turbo.json` → Turborepo
- `nx.json` → Nx
- `lerna.json` → Lerna
- `packages/`, `apps/` directories → likely monorepo

**Package manager**
- `pnpm-lock.yaml` → pnpm
- `yarn.lock` → Yarn
- `bun.lockb` → Bun
- `package-lock.json` → npm

**Environment & config**
- `.env`, `.env.example`, `.env.local` → environment variables (list keys only, never values)
- `*.config.ts`, `*.config.js` at root

### 2. Read key files in full

After identifying which files exist, read:
- `package.json` (full)
- `tsconfig.json` (full)
- `prisma/schema.prisma` or `drizzle.config.*` if present
- `README.md` if present (first 80 lines)
- `.env.example` if present (keys only)

### 3. Infer project type

Based on findings, classify the project as one or more of:
- `web-app` (frontend UI)
- `api` (backend/REST/GraphQL)
- `fullstack` (frontend + backend in same repo)
- `cli` (command-line tool)
- `library` (npm/pip/cargo package)
- `mobile` (React Native, Flutter, Expo)
- `monorepo` (multiple apps/packages)
- `infrastructure` (IaC, DevOps-only)

### 4. Generate AGENTS.md

Write `AGENTS.md` at the project root with the following structure. Be specific — list actual package versions from dependency files, not guesses. If something is uncertain, omit it rather than guess.

```markdown
# Project Context

## Project Type
<!-- e.g., fullstack web-app, monorepo -->

## Stack

### Language & Runtime
<!-- e.g., TypeScript 5.4, Node.js 20 -->

### Framework
<!-- e.g., Next.js 14 (App Router) -->

### Styling
<!-- e.g., Tailwind CSS 3.4, shadcn/ui -->

### Database & ORM
<!-- e.g., PostgreSQL via Prisma 5.x -->

### Testing
<!-- e.g., Vitest, Playwright for E2E -->

### Build & Tooling
<!-- e.g., Vite, Turborepo, pnpm workspaces -->

### Deployment
<!-- e.g., Vercel (frontend), Docker (API) -->

## Project Structure
<!-- Brief description of top-level directories and their purpose -->

## Environment Variables
<!-- List .env keys (no values) and what they're for if inferable -->

## Development Commands
<!-- Extract from package.json scripts or README -->
```

### 5. Confirm to the user

After writing `AGENTS.md`, report:
- What stack was detected
- Where the file was written
- Any ambiguities or gaps that could not be determined automatically
