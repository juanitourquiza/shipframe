# ShipFrame — Codex Workflow

> ShipFrame adapts a team-oriented AI coding workflow to the Codex CLI.
> Codex has no sub-agent delegation, so **you** (the single Codex agent) classify the request, then invoke the matching **skills** yourself, in sequence.

## Core rule

For every non-trivial request, before acting:

1. Classify the intent (see Routing Table).
2. Refresh project context when prior decisions or repo conventions may matter.
3. Run the skills in the listed sequence, in order, waiting for each to finish.
4. Only write code after the required upstream steps (context, spec, plan, tests/review) are done.

Skills live in `~/.codex/skills/<name>/SKILL.md` and are invoked like any other Codex skill. Never re-implement a skill's logic inline — load and follow its `SKILL.md`.

## Startup check

Before the first task in a repo, check the wiki:

```bash
test -f WIKI.md && echo exists || echo missing
```

If missing, run `wiki-init` before anything else. If present, read `WIKI.md` before architecture, module, pattern, or domain work.

## Routing Table

| Intent | When | Skill sequence |
|---|---|---|
| `new_feature` | New product feature or unclear scope | `project-memory-refresh` → `feature-discovery` → `plan-expert` |
| `quick_task` | Well-defined task, often a ticket | `project-memory-refresh` → `plan-expert` → `implement-task` → `code-review` → `create-pr` |
| `implementation` | Confirmed plan exists, write code now | `project-memory-refresh` → `implement-task` → `code-review` → `create-pr` |
| `refactor` | Improve structure, no behavior change | `project-memory-refresh` → `codebase-design` → `plan-expert` → `implement-task` → `code-review` → `create-pr` |
| `bug` | Broken behavior, regression, failing test, or performance issue | `project-memory-refresh` → `bug-diagnosis` → `implement-task` → `code-review` → `create-pr` |
| `release` | Merge, deploy, publish, version, or smoke request | `project-profile` → `project-release` → `deploy-evidence` |
| `research` | Docs/API/version/source investigation | `project-memory-refresh` → `research` |
| `design_system` | Set up or document design system | `project-memory-refresh` → `design-system-setup` |
| `accessibility_audit` | WCAG/a11y review | `project-memory-refresh` → `a11y-auditor` → `implement-task` if fixes are requested |
| `copy_review` | Product/client-facing copy, i18n, email, landing copy | `project-memory-refresh` → `client-copy-review` |
| `mcp_debugging` | MCP connector/tool/session/token failure | `project-memory-refresh` → `mcp-debugging` |
| `code_review` | Review changes before PR | `code-review` |
| `handoff` | Prepare next session/agent | `handoff` |
| `wiki_management` | Sync, reinitialize, or query the wiki | `wiki-query` · `wiki-sync` · `wiki-init` |
| `unknown` | Ambiguous and not discoverable from repo context | Ask one concise clarifying question, then re-classify |

## Lifecycle

CONTEXT → DEFINE → PLAN → BUILD → VERIFY → REVIEW → RELEASE EVIDENCE → PR/MR.

## Environment setup

For any code change, create a branch before editing:

```bash
git checkout -b {task-id-or-type}-{slug}
```

## Boundaries

- Do **not** merge code, approve reviews, or delete/archive external tickets unless the user explicitly authorizes that action.
- Do **not** guess feature requirements — run `feature-discovery` first.
- Do **not** declare deploy/release complete without `deploy-evidence`.
- Open PRs/MRs as **Draft** unless the user explicitly asks otherwise.
- Keep project-specific behavior in profiles or packs, not in generic core skills.
