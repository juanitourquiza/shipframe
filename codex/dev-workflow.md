# ShipFrame — Codex Workflow

> ShipFrame adapts a team-oriented AI coding workflow to the Codex CLI.
> Codex has no sub-agent delegation, so **you** (the single Codex agent) classify the request, then invoke the matching **skills** yourself, in sequence.

## Core rule

ShipFrame's optional Codex `UserPromptSubmit` hook classifies prompts as `bypass`,
`suggest`, or `route`. The hook is advisory: it adds context for `suggest` and
`route`, emits nothing for `bypass`, never blocks a prompt, and never overrides
the user's explicit instruction. Codex only runs plugin hooks after the user
reviews and trusts them. When the hook is unavailable or untrusted, use this
workflow as a judgment-based fallback; ordinary questions, greetings, trivial
requests, and explicit skill invocations do not need an orchestrator hop.

For non-trivial workflow work, before acting:

1. Classify the intent (see Routing Table).
2. Refresh project context when prior decisions or repo conventions may matter.
3. Run the skills in the listed sequence, in order, waiting for each to finish.
4. Only write code after the required upstream steps (context, spec, plan, tests/review) are done.

Skills live in the current Agent Skills layout at `~/.agents/skills/<name>/SKILL.md`; ShipFrame also keeps compatibility symlinks in `~/.codex/skills/<name>/SKILL.md` for existing Codex setups. In Codex, run `/skills` to list them or type `$skill-name` to invoke one explicitly. Never re-implement a skill's logic inline — load and follow its `SKILL.md`.

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
| `quick_task` | Well-defined code task; QA only for non-trivial changes | `project-memory-refresh` → `plan-expert` → `quality-assurance-agent` or `tdd` (non-trivial code only) → `implement-task` → `code-review` → `create-pr` |
| `implementation` | Confirmed plan exists; QA only for non-trivial code changes | `project-memory-refresh` → `quality-assurance-agent` or `tdd` (non-trivial code only) → `implement-task` → `code-review` → `create-pr` |

| `refactor` | Improve structure, no behavior change | `project-memory-refresh` → `codebase-design` → `plan-expert` → `implement-task` → `code-review` → `create-pr` |
| `bug` | Broken behavior, regression, failing test, or performance issue | `project-memory-refresh` → `bug-diagnosis` → `quality-assurance-agent` or `tdd` (non-trivial code only) → `implement-task` → `code-review` → `create-pr` |
| `release` | Merge, deploy, publish, version, or smoke request | `project-profile` → `project-release` → `deploy-evidence` |
| `evidence_audit` | Audit a report, handoff, PR body, or release note for unsupported claims | `project-memory-refresh` → `evidence-audit` |
| `research` | Docs/API/version/source investigation | `project-memory-refresh` → `research` |
| `design_system` | Set up or document design system | `project-memory-refresh` → `design-system-setup` |
| `accessibility_audit` | WCAG/a11y review | `project-memory-refresh` → `a11y-auditor` → `implement-task` if fixes are requested |
| `copy_review` | Product/client-facing copy, i18n, email, landing copy | `project-memory-refresh` → `client-copy-review` |
| `mcp_debugging` | MCP connector/tool/session/token failure | `project-memory-refresh` → `mcp-debugging` |
| `security_review` | Security assessment of code, dependencies, or boundaries | `project-memory-refresh` → `security-review` |
| `e2e_test` | Verify an end-to-end user journey | `project-memory-refresh` → `e2e-verify` |
| `deps_upgrade` | Upgrade or migrate dependencies safely | `project-memory-refresh` → `dependency-upgrade` → `code-review` |
| `api_change` | Review a public API/schema contract change | `project-memory-refresh` → `api-contract-review` |
| `incident` | Respond to production outage or degradation | `project-memory-refresh` → `incident-response` |
| `memory_curate` | Curate durable project memory | `project-memory-refresh` → `memory-curator` |
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
- Keep README and related repo documentation current whenever a change affects installer behavior, public commands, workflow routing, skill behavior, release process, or project conventions.
