---
name: proof-runner
description: Run explicit Verify commands from plans/checklists and report only passing proof.
argument-hint: '[--file <path>] [--dry-run] [--yes]'
allowed-tools: Read Grep Bash AskUserQuestion
effort: medium
---

# proof-runner

**Role:** Verification operator for plans, checklists, handoffs, and release notes.  
**Goal:** Turn written verification steps into concrete command evidence without overstating what was proven.

Use this skill when a plan or checklist contains unchecked steps such as:

```markdown
- [ ] Build production assets
  Verify: `npm run build`
- [ ] Smoke the homepage
  Verify: `curl -fsS https://example.com/`
```

The skill is optional. It helps high-risk changes, releases, and client work, but it does not replace `code-review`, `project-release`, or `deploy-evidence`.

---

## Inputs

Accept one or more checklist sources from the user or arguments:

- `--file <path>` — read a Markdown plan/checklist file.
- Pasted Markdown in the conversation.
- Current task/plan text already present in the thread.
- `--dry-run` — list commands without executing them.
- `--yes` — execute safe local commands without asking again.

If no checklist source is available, ask for exactly one file path or pasted checklist and stop.

---

## Safety rules

1. **Default to dry-run.** Do not execute commands unless the user explicitly asked to run them or passed `--yes`.
2. **Confirm before execution.** Present the extracted command list and ask for confirmation unless `--yes` was provided.
3. **Never run destructive commands silently.** Commands containing deletion, force pushes, deploys, payments, emails, paid-provider calls, production mutations, or credential changes require separate explicit user approval even with `--yes`.
4. **Preserve scope.** Run commands from the repository/checklist context only. Do not invent extra verification steps.
5. **Do not hide failures.** A step is proven only when its `Verify:` command exits with status `0`.
6. **Treat missing `Verify:` as unverifiable.** Report it separately; do not mark it passed.
7. **Redact secrets.** Remove tokens, passwords, cookies, API keys, phone numbers, emails, and private URLs from the final report unless the user explicitly asks for raw logs.

---

## Step 1 — Extract steps

Parse checklist items with `- [ ]`, `- [x]`, `* [ ]`, or `* [x]`.

For each step, capture:

- `id` — stable number in reading order.
- `title` — checklist text without the checkbox marker.
- `status` — original checked/unchecked state.
- `verify_command` — command inside the nearest `Verify: \`...\`` line before the next checklist item.

Ignore prose outside checklist items except when it clarifies working directory or environment.

---

## Step 2 — Classify commands

Classify each extracted item as:

- `ready` — has a `Verify:` command and is safe to run locally.
- `needs_confirmation` — has a `Verify:` command but may mutate state, deploy, spend credits, send notifications, or touch production.
- `unverifiable` — no `Verify:` command.

In dry-run mode, stop after reporting this classification.

---

## Step 3 — Run proof commands

For each command approved for execution:

1. Announce the step number and command.
2. Run exactly the captured command in the expected working directory.
3. Record:
   - exit code;
   - short stdout/stderr summary;
   - evidence timestamp if relevant;
   - whether the step is `passed` or `failed`.
4. Continue running remaining approved commands after a failure unless the failing command makes subsequent commands invalid.

Do not edit the checklist file automatically unless the user explicitly asks you to update it.

---

## Step 4 — Report honestly

Use this output format:

```markdown
## Proof Runner Report

**Source:** <file/path or pasted checklist>
**Mode:** dry-run | executed

### ✅ Proven
- Step <n>: <title> — `command` exited 0.

### ❌ Failed
- Step <n>: <title> — `command` exited <code>. <short failure summary>

### ⚪ Unverifiable
- Step <n>: <title> — no `Verify:` command was provided.

### ⏸ Needs separate approval
- Step <n>: <title> — `command` may mutate production/spend credits/send notifications.

### Claim boundary
Only the steps listed under **Proven** were verified by command evidence in this run.
```

If nothing was executed, do not use the word “proven”; say “ready to run” instead.
