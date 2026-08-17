# ShipFrame — AI Coding Workflows for Teams

**ShipFrame** is a practical AI coding workflow toolkit for teams that plan, prove, and ship software changes with discipline.

It provides reusable skills, agent workflows, templates, and project profiles for Claude Code, Codex CLI, and OpenCode. The core workflow is generic enough for any software team, while project-specific behavior lives in opt-in profiles.

> Tagline: **AI coding workflows for teams that plan, prove, and ship.**

---

## What ShipFrame does

ShipFrame turns natural-language development requests into a repeatable delivery lifecycle:

```text
Refresh context → Discover requirements → Plan work → Implement → Verify → Review → Release evidence → PR/MR
```

It is designed for:

- teams working from tickets, Git branches, and PRs/MRs;
- developers who want agent help without “vibe coding”;
- projects that need exact release evidence before declaring work complete;
- multi-project teams that need generic workflows plus project-specific profiles.

---

## What's inside

### Core workflow skills

| Skill | What it does |
|---|---|
| `init-project` | Scans a repo and creates project context for future agents. |
| `project-memory-refresh` | Reads WIKI/AGENTS/git state before non-trivial work. |
| `feature-discovery` | Gathers requirements through structured questioning. |
| `plan-expert` | Breaks work into ordered, actionable subtasks. |
| `implement-task` | Implements a scoped task, verifies it, commits, and prepares a PR/MR. |
| `code-review` | Two-phase review: fast checks plus structural/SOLID audit. |
| `create-task` | Converts raw input into ClickUp-ready task templates. |
| `create-issue` | Triage flow for bugs/issues. |
| `create-pr` | Opens a draft PR/MR with a populated template from git context. |

### Engineering discipline skills

| Skill | What it does |
|---|---|
| `domain-modeling` | Builds glossary/ADRs and sharpens project language. |
| `codebase-design` | Designs deeper modules and cleaner seams. |
| `tdd` | Guides red/green/refactor through public seams. |
| `bug-diagnosis` | Builds a tight repro loop before changing code. |
| `research` | Researches against primary sources and captures findings. |
| `handoff` | Creates a compact handoff for the next agent/session. |

### Release and evidence skills

| Skill | What it does |
|---|---|
| `project-profile` | Loads repo-specific workflow rules without hardcoding them into core. |
| `project-release` | Generic release orchestrator for frontend/backend/full-stack/docs/library releases. |
| `release-checklist` | Produces project-aware release gates. |
| `frontend-release` | Verifies frontend builds, routes, i18n, chunks, and smoke checks. |
| `backend-release` | Verifies API/backend tests, migrations, queues, integrations, and endpoint smoke. |
| `deploy-evidence` | Collects concrete proof before saying a deploy/release is done. |

### Integration and product skills

| Skill | What it does |
|---|---|
| `mcp-debugging` | Diagnoses MCP connector failures with live tool evidence. |
| `client-copy-review` | Reviews client-facing copy, bilingual consistency, and approval constraints. |
| `a11y-auditor` | Audits accessibility against WCAG 2.2. |
| `design-expert` | Documents design tokens and UI conventions. |
| `design-system-docs` | Audits Markdown/Storybook design system documentation. |
| `design-system-setup` | Runs the design documentation pipeline end-to-end. |

### Wiki skills

| Skill | What it does |
|---|---|
| `wiki-init` | Creates the project wiki vault. |
| `wiki-query` | Answers from the wiki index and pages. |
| `wiki-sync` | Updates wiki docs from repo diffs. |
| `wiki-forge` | Ingests source material into a connected Markdown wiki. |

---

## Project profiles

ShipFrame keeps project-specific behavior out of the generic core.

A project can opt in with:

```text
shipframe.profile.md
.shipframe/profile.md
.shipframe/project-profile.md
```

Profiles can define:

- repo topology;
- release/deploy process;
- smoke-test routes;
- version/tag policy;
- i18n rules;
- client copy constraints;
- integration-specific verification.

Starter packs live in `project-packs/`:

- `project-packs/angular/`
- `project-packs/laravel/`
- `project-packs/mcp/`
- `project-packs/pulsai-profile/`

The PULSAI profile is intentionally optional: it is useful for PULSAI-style projects but not hardcoded into the public ShipFrame workflow.

---

## Installation

### One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/juanitourquiza/shipframe/main/install.sh | bash
```

### Local clone

```bash
git clone https://github.com/juanitourquiza/shipframe ~/tools/shipframe
cd ~/tools/shipframe
./install.sh --codex
./install.sh --claude
./install.sh --opencode
```

### Targets

```bash
./install.sh --claude     # Claude Code plugin + hooks
./install.sh --opencode   # OpenCode skills + converted agents
./install.sh --codex      # Codex CLI skills + global workflow block
./install.sh --all        # all supported tools
```

| Tool | Skills | Orchestration |
|---|---|---|
| Claude Code | plugin marketplace/local plugin | agents + hooks |
| OpenCode | symlinked skills | converted agents |
| Codex CLI | symlinked skills | routing table in `~/.codex/AGENTS.md` |

---

## Codex workflow

Codex has no sub-agent delegation, so ShipFrame installs a routing table into `~/.codex/AGENTS.md`.

The Codex agent classifies each request and runs the matching skills in order:

| Intent | Skill sequence |
|---|---|
| `new_feature` | `project-memory-refresh` → `feature-discovery` → `plan-expert` |
| `quick_task` | `project-memory-refresh` → `plan-expert` → `implement-task` → `code-review` → `create-pr` |
| `bug` | `project-memory-refresh` → `bug-diagnosis` → `implement-task` → `code-review` → `create-pr` |
| `release` | `project-profile` → `project-release` → `deploy-evidence` |
| `research` | `project-memory-refresh` → `research` |
| `handoff` | `handoff` |
| `code_review` | `code-review` |
| `wiki_management` | `wiki-query` / `wiki-sync` / `wiki-init` |

---

## Repository structure

```text
shipframe/
├── agents/                 # Claude-shaped agents and orchestrator docs
├── codex/                  # Codex routing workflow
├── skills/                 # Installable flat skill directories
├── templates/              # PR, issue, ClickUp, and wiki templates
├── project-packs/          # Optional project profile starters
├── wiki/                   # Project wiki vault
├── raw/                    # Wiki source staging
├── .claude-plugin/         # Claude plugin metadata
└── install.sh              # Multi-tool installer
```

Skills are intentionally kept flat under `skills/<name>/SKILL.md` because the installer symlinks each skill directory into the target tool.

---

## Recommended team workflow

1. Add a project profile to the repo.
2. Run `project-memory-refresh` before non-trivial work.
3. Use `feature-discovery` for unclear features.
4. Use `plan-expert` for ticket breakdown.
5. Use `implement-task` only after scope is clear.
6. Run `code-review` before commit/PR/MR.
7. For releases, run `project-release` and require `deploy-evidence` before saying the release is complete.

## Español

ShipFrame es un toolkit práctico de flujos de trabajo con IA para equipos que planifican, prueban y publican cambios de software con disciplina. Mantiene un núcleo genérico para cualquier equipo y deja las reglas específicas de cada proyecto en perfiles opcionales.

### Instalación rápida

```bash
curl -fsSL https://raw.githubusercontent.com/juanitourquiza/shipframe/main/install.sh | bash
```

Para instalar desde un clon local:

```bash
git clone https://github.com/juanitourquiza/shipframe ~/tools/shipframe
cd ~/tools/shipframe
./install.sh --codex
./install.sh --claude
./install.sh --opencode
```

### Flujo recomendado

1. Agrega un perfil de proyecto cuando el repo tenga reglas propias.
2. Ejecuta `project-memory-refresh` antes de trabajo no trivial.
3. Usa `feature-discovery` cuando el alcance no esté claro.
4. Usa `plan-expert` para desglosar tickets o tareas.
5. Usa `implement-task` solo cuando el alcance esté definido.
6. Ejecuta `code-review` antes de commit y PR/MR.
7. Para releases, ejecuta `project-release` y exige `deploy-evidence` antes de declarar que el deploy está completo.

### Compatibilidad GitHub/GitLab

ShipFrame trabaja con repos Git y puede cerrar el ciclo con Draft Pull Requests en GitHub o Draft Merge Requests en GitLab:

- GitHub usa la CLI `gh` y crea PRs con `gh pr create --draft`.
- GitLab usa la CLI `glab` y crea MRs con `glab mr create --draft`.
- El skill `create-pr` conserva su nombre por compatibilidad, pero soporta PR/MR mediante `--provider <auto|github|gitlab>`; `auto` detecta el proveedor desde `origin`.
- Si falta autenticación, ShipFrame debe detenerse y mostrar el comando exacto: `gh auth login` para GitHub o `glab auth login` para GitLab.

Para preparar GitLab localmente en macOS con Homebrew:

```bash
brew install glab
glab auth login
glab auth status
```

---

## Attribution

ShipFrame started from `Axis-Human/dev-workflow-plugin` and includes/adapts engineering workflow ideas and selected MIT-licensed skills from `mattpocock/skills`.

- Axis Human Dev Workflow Plugin: https://github.com/Axis-Human/dev-workflow-plugin
- Matt Pocock Skills: https://github.com/mattpocock/skills

See `THIRD_PARTY_NOTICES.md` for upstream attribution and third-party license details.

---

## License

ShipFrame is released under the MIT License. See [`LICENSE`](LICENSE).

Third-party material remains subject to its original notices and terms; see [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
