# Axis-Human upstream `main` review for ShipFrame

**Date:** 2026-09-23
**Reviewed Axis `main` HEAD:** [`b8430ac`](https://github.com/Axis-Human/dev-workflow-plugin/commit/b8430ac65542b18d6fe322e8ffc3e4e474edb228) (2026-09-22)
**Scope:** Read-only compatibility assessment of relevant changes present on `Axis-Human/dev-workflow-plugin:main`; no upstream branch/PR changes considered.

## Summary

Axis has useful work on `main`, but only the prompt fast-path is a strong ShipFrame candidate. Adapt its intent, not its classifier verbatim. Telemetry is coupled to Axis' dashboard and captures sensitive metadata, the guard is weaker than ShipFrame's existing guard, and the diagram is optional documentation rather than a workflow capability.

## Findings

### 1. Prompt fast-path — adapt, with conservative routing

Axis' `UserPromptSubmit` router has three outcomes: bypass questions/trivial prompts, suggest the orchestrator for ambiguous tasks, and route substantial engineering work. ShipFrame currently injects an unconditional mandatory-orchestrator instruction from its Claude hook. That conflicts with ShipFrame's direct-answer / lightweight-task behavior and spends an agent hop unnecessarily.

**Recommendation:** Adopt the three-tier policy across the three hosts through native adapters, not one Claude-only hook. Do not copy the upstream regex classifier unchanged: it is a broad bilingual heuristic, domain/verb lists can drift, and no router-specific tests were found in the upstream tree. Keep the decision advisory and allow direct user requests to override it.

### 2. Usage telemetry — do not import

The upstream collector is integrated with Claude transcript/hook events and posts to an Axis dashboard. It excludes raw prompt content, but records prompt length/hash, machine/host identity, GitHub account, project path/name, branch/ticket hints, model/token/cost and timing data. It also spools records locally and performs network delivery.

**Recommendation:** Do not import into generic ShipFrame. This is provider-specific, requires a telemetry endpoint and data-governance decisions, and is not a recommend-and-verify optional integration. Revisit only as a separately specified, opt-in feature with explicit collection/retention/network behavior and tests.

### 3. Orchestrator guard — keep ShipFrame's implementation

Axis' current guard uses a compact shell-write regex. ShipFrame already has a tokenizing guard that handles wrappers such as `env`, `sudo`, and `command`, and is covered by `tests/test-orchestrator-guard.js`.

**Recommendation:** No port. Preserve ShipFrame's more defensive local implementation and regression tests.

### 4. Generated agent network diagram — optional

Axis maintains a generated diagram and interactive HTML as explanatory documentation. ShipFrame has no equivalent diagram, but its public workflow and skill inventory already document the pipeline.

**Recommendation:** No immediate addition; consider only if onboarding feedback shows the written routing docs are insufficient.

### 5. `create-draft-pr` — already covered

Axis' skill creates draft PRs from repository context, overlapping ShipFrame's `create-pr` skill.

**Recommendation:** Do not duplicate; selectively compare future template improvements if needed.

## Decision

Proceed with a narrowly scoped implementation proposal for all three hosts. Keep research and implementation separate: this assessment does not change runtime behavior, installer behavior, or user configuration. Before implementation, define the classifier outcomes, language coverage, override semantics, and table-driven tests against question/work/trivial/ambiguous examples in English and Spanish.

## Cross-host feasibility addendum

Current official host docs confirm a native prompt/context hook surface for each target:

- **Claude Code:** retain ShipFrame's plugin-managed `UserPromptSubmit` command hook; emit `hookSpecificOutput.additionalContext` only for `suggest` and `route` outcomes.
- **Codex CLI:** `UserPromptSubmit` command hooks are supported in Codex plugins and receive the prompt. Bundle the adapter with the Codex plugin artifact. Plugin hooks are not run until users review/trust the hook definition; keep the existing `AGENTS.md` routing policy as fallback when the plugin hook is not enabled.
- **OpenCode:** use its local/global plugin directory. Prefer the session `context` hook to add ephemeral system guidance without rewriting the user's persisted prompt; do not use prompt admission to append routing text because OpenCode persists that edit as canonical prompt input. The context adapter must avoid affecting title/compaction/generate flows and avoid redundant route guidance on tool continuations.

Keep one shared pure classifier and separate host adapters for event parsing/output. Hook failures must fail open (no block, no mutation, no user-config edits). Keep the fast path advisory: bypass ordinary questions/greetings/explicit skill invocations; route clear multi-step ShipFrame work; suggest only when the need for a workflow is ambiguous. Explicit user instruction to use ShipFrame wins. This gives equivalent behavior without assuming identical hook protocols or installer paths.

Hooks only inject guidance; they do not guarantee that a host won't autonomously select an orchestrator. For consistent behavior, the shared orchestrator description/routing docs also need a fast-path rule. Treat it as a probabilistic workflow nudge, not an enforcement boundary.

The main implementation choice is Codex plugin activation: the adapter can ship in the bundled plugin, but ShipFrame's current `install --codex` path installs skills and managed `AGENTS.md`, not the plugin hooks, and the host requires explicit hook trust. Keep the current no-config-change install behavior and provide an explicit activation path; never silently edit Codex config or bypass trust.

## Primary sources

- [Axis router on `main`](https://github.com/Axis-Human/dev-workflow-plugin/blob/main/hooks/orchestrator-router.js)
- [Axis guard on `main`](https://github.com/Axis-Human/dev-workflow-plugin/blob/main/hooks/orchestrator-guard.js)
- [Axis telemetry on `main`](https://github.com/Axis-Human/dev-workflow-plugin/blob/main/hooks/telemetry.js)
- [Axis hook registration on `main`](https://github.com/Axis-Human/dev-workflow-plugin/blob/main/hooks/hooks.json)
- [Axis workflow overview and telemetry notes](https://github.com/Axis-Human/dev-workflow-plugin/blob/main/README.md)
- [Codex lifecycle hooks](https://learn.chatgpt.com/docs/hooks)
- [Codex plugin packaging and hook trust](https://developers.openai.com/plugins/build/plugins)
- [OpenCode session hooks and prompt admission](https://opencode.ai/v2/docs/build/plugins)
- [OpenCode local/global plugin loading](https://dev.opencode.ai/docs/plugins/)
- [Claude Code hook configuration overview](https://claude.com/blog/how-to-configure-hooks)

## ShipFrame comparison points

- `hooks/hooks.json` — current Claude hook always instructs an orchestrator invocation.
- `hooks/orchestrator-guard.js` and `tests/test-orchestrator-guard.js` — existing local write guard and tests.
- `codex/dev-workflow.md` — host-specific Codex classification and skill routing; leave independent from Claude hook behavior.
