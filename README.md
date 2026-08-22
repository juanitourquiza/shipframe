# ShipFrame — AI Coding Workflows for Teams

**ShipFrame** is a practical AI coding workflow toolkit for teams that plan, prove, and ship software changes with discipline.

It provides reusable skills, agent workflows, templates, and project profiles for Claude Code, Codex CLI, and OpenCode. The core workflow is generic enough for any software team, while project-specific behavior lives in opt-in profiles.

> Tagline: **AI coding workflows for teams that plan, prove, and ship.**

**Website:** https://shipframe.hackeruna.com/  
**Repository:** https://github.com/juanitourquiza/shipframe

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

Visit the ShipFrame landing page for the public overview, product positioning,
installation entry points, FAQ, and links to the GitHub repository:
https://shipframe.hackeruna.com/

---

## What's inside

### Core workflow skills

| Skill | What it does |
|---|---|
| `init-project` | Scans a repo and creates project context for future agents. |
| `project-memory-refresh` | Reads WIKI/AGENTS/git state before non-trivial work. |
| `feature-discovery` | Gathers requirements through structured questioning. |
| `plan-expert` | Breaks work into ordered, actionable subtasks. |
| `planning-features` | Runs feature discovery and planning as one feature-planning pipeline. |
| `implement-task` | Implements a scoped task, verifies it, commits, and prepares a PR/MR. |
| `code-review` | Two-phase review: fast checks plus structural/SOLID audit. |
| `create-task` | Converts raw input into ClickUp-ready task templates. |
| `create-issue` | Triage flow for bugs/issues. |
| `create-pr` | Opens a draft PR/MR with a populated template from git context. |
| `generate-readme` | Generates a team-ready README by scanning the current codebase. |

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

### macOS with Homebrew

```bash
brew tap juanitourquiza/shipframe
brew install shipframe
shipframe install --codex
```

If your Homebrew version requires tap trust, run the exact trust command it
prints (for example, `brew trust --formula juanitourquiza/shipframe/shipframe`)
and then re-run `brew install shipframe`.

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
./install.sh --claude     # Claude Code plugin + plugin-managed hooks
./install.sh --opencode   # OpenCode skills + converted agents
./install.sh --codex      # Codex CLI skills + global workflow block
./install.sh --all        # all supported tools
```

### Diagnostics, repair, and uninstall

```bash
./install.sh --doctor --repo-only        # CI-safe repo checks only
./install.sh --doctor --all              # read-only local environment diagnostics
./install.sh --repair --codex --yes      # repair ShipFrame-owned Codex artifacts
./install.sh --uninstall --all --yes     # remove ShipFrame-owned installed artifacts
./install.sh --uninstall --all --yes --purge  # also remove ShipFrame cache/state
```

`--doctor` is always read-only. `--repair` and `--uninstall` are dry-run by
default and only apply changes with `--yes`. ShipFrame records install ownership
in `${XDG_STATE_HOME:-~/.local/state}/shipframe/install-state.json` so repair and
uninstall can distinguish ShipFrame-managed artifacts from user files.

When installed with Homebrew, use the `shipframe` wrapper:

```bash
shipframe install --claude
shipframe install --opencode
shipframe install --codex
shipframe install --all
```

| Tool | Skills | Orchestration |
|---|---|---|
| Claude Code | plugin marketplace / plugin namespace | agents + hooks |
| Codex CLI | Agent Skills via `/skills` | routing table in `~/.codex/AGENTS.md` |
| OpenCode | native skill discovery | converted agents |

### Use ShipFrame from skills picker

ShipFrame supports each tool's native discovery model: Claude Code plugin
marketplaces, Codex Agent Skills via `/skills`, and OpenCode native skill
discovery. Install locally, use directly, and keep model/config choices
user-owned.

#### Claude Code

```text
/plugin marketplace add juanitourquiza/shipframe
/plugin install shipframe
/reload-plugins
/shipframe:code-review
```

Claude plugin skills are namespaced as `/shipframe:<skill>` to avoid collisions
with personal or project skills. Use `/help` or the custom commands view to
confirm a skill is listed after reload.

#### Codex CLI

```bash
shipframe install --codex
# or: ./install.sh --codex
```

Then open Codex and run:

```text
/skills
$code-review
$plan-expert
```

Codex uses the open Agent Skills layout at `~/.agents/skills/<name>/SKILL.md`.
ShipFrame also writes compatibility symlinks to `~/.codex/skills` for existing
setups, and keeps the workflow block in `~/.codex/AGENTS.md`.

#### ChatGPT/Codex curated plugin

ShipFrame is also available as a curated ChatGPT/Codex skills-only plugin with
22 public workflows selected from the full toolkit. The source of truth remains
`skills/`; the build script copies the curated plugin subset into a temporary
bundle and does not include MCP servers, apps, Claude hooks, or OpenCode/Claude
agents.

Open the public plugin here: https://chatgpt.com/plugins/plugins_6a88e6256bb48191a343d39dace5e05c

The GitHub repo and Homebrew installer remain the complete distribution for all
ShipFrame skills, project packs, templates, Claude Code hooks, and OpenCode
agents.

```bash
python3 scripts/build-openai-plugin.py
python3 ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py dist/openai-plugin/shipframe
```

The generated upload artifact is `dist/openai-plugin/shipframe-openai-plugin.zip`.
Use `docs/openai-plugin-submission.md` for paste-ready listing copy, starter
prompts, positive/negative reviewer test cases, re-upload notes, and the manual
submission checklist.

#### OpenCode

```bash
shipframe install --opencode
# or: ./install.sh --opencode
```

OpenCode discovers ShipFrame from `~/.config/opencode/skills/<name>/SKILL.md`
and loads skills on demand through its native `skill` tool. OpenCode can also
see compatible skills in `~/.agents/skills` and `~/.claude/skills`; install the
Codex target too when you want ShipFrame available through the shared
`~/.agents/skills` location.

Quick smoke checks:

```bash
./install.sh --doctor --all
ls ~/.agents/skills/code-review/SKILL.md
ls ~/.config/opencode/skills/code-review/SKILL.md
```

### Stable versions

Stable ShipFrame releases are tracked with git tags named `vX.Y.Z` (for example,
`v0.2.0`). The Homebrew formula uses these tags as immutable release sources.

### Installation scope

ShipFrame installs globally for the current macOS/Linux user, not inside the
project where you run the command:

- Claude Code: installs the `shipframe` plugin. Hooks are plugin-managed via
  `hooks/hooks.json`; legacy user-level ShipFrame hooks can be removed with
  `./install.sh --repair --claude --yes`.
- Codex CLI: links skills into `~/.agents/skills` for the current Agent
  Skills layout, also links compatibility copies into `~/.codex/skills`, and
  injects the managed workflow block into `~/.codex/AGENTS.md`.
- OpenCode: links skills into `~/.config/opencode/skills` and writes converted
  agents into `~/.config/opencode/agents`. OpenCode also discovers compatible
  skills from `~/.agents/skills` and `~/.claude/skills` if those locations are
  populated. Converted agents inherit the user's OpenCode model by default;
  pass `--opencode-model provider/model` only when an explicit override is
  needed.

Run `shipframe install ...` once per user/machine. Then add project-specific
rules inside each repository with `shipframe.profile.md`,
`.shipframe/profile.md`, or `.shipframe/project-profile.md` when a project needs
custom release, smoke-test, or team conventions.

### Optional persistent memory with Engram

ShipFrame works without a memory system, but Engram is recommended when you want
AI agents to remember prior decisions, bug fixes, conventions, and session
summaries across Claude Code, Codex CLI, and OpenCode.

ShipFrame only checks whether `engram` is available and prints setup guidance; it
does not install or configure Engram automatically.

```bash
brew install gentleman-programming/tap/engram
engram setup codex
engram setup opencode
claude plugin marketplace add Gentleman-Programming/engram && claude plugin install engram
```

Like ShipFrame, Engram is configured globally for the current user/agent. Project
specific behavior should still live in each repo's ShipFrame profile.

---

## Codex workflow

Codex has no sub-agent delegation, so ShipFrame installs a routing table into `~/.codex/AGENTS.md`.

The Codex agent classifies each request and runs the matching skills in order:

| Intent | Skill sequence |
|---|---|
| `new_feature` | `project-memory-refresh` → `feature-discovery` → `plan-expert` |
| `quick_task` | `project-memory-refresh` → `plan-expert` → `implement-task` → `code-review` → `create-pr` |
| `implementation` | `project-memory-refresh` → `implement-task` → `code-review` → `create-pr` |
| `refactor` | `project-memory-refresh` → `codebase-design` → `plan-expert` → `implement-task` → `code-review` → `create-pr` |
| `bug` | `project-memory-refresh` → `bug-diagnosis` → `implement-task` → `code-review` → `create-pr` |
| `release` | `project-profile` → `project-release` → `deploy-evidence` |
| `research` | `project-memory-refresh` → `research` |
| `design_system` | `project-memory-refresh` → `design-system-setup` |
| `accessibility_audit` | `project-memory-refresh` → `a11y-auditor` → `implement-task` if fixes are requested |
| `copy_review` | `project-memory-refresh` → `client-copy-review` |
| `mcp_debugging` | `project-memory-refresh` → `mcp-debugging` |
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
├── scripts/                # Build helpers, including OpenAI plugin packaging
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

## Documentation maintenance

ShipFrame treats documentation as part of the shipped change. When a change
affects installer behavior, user-facing commands, workflow routing, public skill
behavior, release process, or project conventions, update the README and any
related repo documentation in the same commit/release.

## Español

ShipFrame es un toolkit práctico de flujos de trabajo con IA para equipos que planifican, prueban y publican cambios de software con disciplina. Mantiene un núcleo genérico para cualquier equipo y deja las reglas específicas de cada proyecto en perfiles opcionales.

**Landing:** https://shipframe.hackeruna.com/  
**Repositorio:** https://github.com/juanitourquiza/shipframe

La landing pública de ShipFrame contiene el resumen del producto, posicionamiento,
opciones de instalación, FAQ y enlaces al repositorio de GitHub.

### Instalación rápida

```bash
curl -fsSL https://raw.githubusercontent.com/juanitourquiza/shipframe/main/install.sh | bash
```

En macOS también puedes instalar ShipFrame con Homebrew:

```bash
brew tap juanitourquiza/shipframe
brew install shipframe
shipframe install --codex
```

Si tu versión de Homebrew exige confianza para taps externos, ejecuta el comando
exacto que Homebrew imprime (por ejemplo,
`brew trust --formula juanitourquiza/shipframe/shipframe`) y vuelve a correr
`brew install shipframe`.

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

### Mantenimiento de documentación

ShipFrame trata la documentación como parte del cambio publicado. Cuando un
cambio afecta el instalador, comandos visibles, routing del workflow,
comportamiento público de skills, proceso de release o convenciones del
proyecto, actualiza el README y la documentación relacionada del repo en el
mismo commit/release.

### Alcance de instalación

### Diagnóstico, reparación y desinstalación

```bash
./install.sh --doctor --repo-only
./install.sh --doctor --all
./install.sh --repair --codex --yes
./install.sh --uninstall --all --yes
```

`--doctor` es solo lectura. `--repair` y `--uninstall` son dry-run por defecto y
solo aplican cambios con `--yes`. En OpenCode los agentes convertidos heredan el
modelo global del usuario salvo que pases `--opencode-model provider/model`.
ShipFrame no modifica `~/.codex/config.toml` ni el modelo global de Codex.

ShipFrame se instala globalmente para el usuario actual, no dentro del proyecto
desde donde corres el comando:

- Claude Code: instala el plugin `shipframe`; los hooks se gestionan desde
  `hooks/hooks.json` del plugin.
- Codex CLI: enlaza skills en `~/.agents/skills` como layout actual de Agent
  Skills, conserva symlinks compatibles en `~/.codex/skills` e inyecta el
  bloque administrado en `~/.codex/AGENTS.md`.
- OpenCode: enlaza skills en `~/.config/opencode/skills` y escribe agentes
  convertidos en `~/.config/opencode/agents`; también puede descubrir skills
  compatibles desde `~/.agents/skills` y `~/.claude/skills`.

Ejecuta `shipframe install ...` una vez por usuario/máquina. Las reglas por
proyecto van dentro de cada repo usando `shipframe.profile.md`,
`.shipframe/profile.md` o `.shipframe/project-profile.md`.

### Usar ShipFrame desde el skills picker

ShipFrame usa el modelo nativo de discovery de cada herramienta: marketplaces
de plugins en Claude Code, Agent Skills en Codex vía `/skills`, y discovery
nativo de skills en OpenCode. Instálalo localmente, úsalo directo y mantén
modelos/configuración bajo control del usuario.

- Claude Code: agrega el marketplace con `/plugin marketplace add juanitourquiza/shipframe`, instala con `/plugin install shipframe`, recarga con `/reload-plugins` y usa `/shipframe:code-review`.
- Codex CLI: instala con `shipframe install --codex`, abre Codex, ejecuta `/skills` y llama skills con `$code-review`, `$plan-expert`, etc.
- ChatGPT/Codex plugin: abre el plugin público en https://chatgpt.com/plugins/plugins_6a88e6256bb48191a343d39dace5e05c o genera el bundle curado de 22 skills con `python3 scripts/build-openai-plugin.py`; el ZIP queda en `dist/openai-plugin/shipframe-openai-plugin.zip` y el packet de submission está en `docs/openai-plugin-submission.md`.
- OpenCode: instala con `shipframe install --opencode`; OpenCode carga las skills con su herramienta nativa `skill` desde `~/.config/opencode/skills` y también puede ver `~/.agents/skills`/`~/.claude/skills`.

### Memoria persistente opcional con Engram

ShipFrame funciona sin un sistema de memoria, pero Engram es recomendado cuando
quieres que los agentes recuerden decisiones, bugs corregidos, convenciones y
resúmenes entre sesiones de Claude Code, Codex CLI y OpenCode.

ShipFrame solo revisa si `engram` está disponible y muestra instrucciones; no lo
instala ni lo configura automáticamente.

```bash
brew install gentleman-programming/tap/engram
engram setup codex
engram setup opencode
claude plugin marketplace add Gentleman-Programming/engram && claude plugin install engram
```

Igual que ShipFrame, Engram se configura globalmente para el usuario/agente
actual. Las reglas específicas de cada proyecto siguen viviendo en el perfil de
ShipFrame dentro de cada repo.

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
