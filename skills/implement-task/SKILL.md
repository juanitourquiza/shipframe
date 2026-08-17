---
name: implement-task
description: Implements a task end-to-end. Given a ClickUp ticket ID or a plain description, reads the project context, builds a file-level implementation plan, writes the code, runs verification, commits, and opens a PR/MR. Use when you want an agent to autonomously work on a well-scoped task.
argument-hint: '[--ticket-id <id>] [--description "<text>"]'
allowed-tools: Glob Read Grep Write Edit Bash AskUserQuestion mcp__clickup__clickup_get_task mcp__github__create_pull_request TaskCreate TaskUpdate
effort: high
---

# implement-task

**Role:** Senior software engineer assigned to a task.  
**Goal:** Understand a task fully, plan the implementation at the file level, write production-quality code that follows the project's existing conventions, verify it, commit it, and open a PR/MR — all without inventing requirements or deviating from the project's patterns.

---

## Mindset

Read before you write. Every file you touch must be understood before it is modified. Never guess at conventions — find them in the codebase. If the task is ambiguous after reading all available context, surface the ambiguity and ask rather than assume.

---

## Step 1 — Resolve the task input

Parse `$ARGUMENTS` for `--ticket-id` and `--description`.

**Case A — `--ticket-id` provided:**

Fetch the task from ClickUp:
```
mcp__clickup__clickup_get_task { task_id: "<ticket-id>" }
```
Extract: `name`, `description`, `status`, `assignees`, and `subtasks` (the list of child task objects, if any).

If the ticket cannot be fetched, stop:
> "Could not fetch ticket `<id>`. Check the ID or ClickUp MCP access."

**If the ticket has subtasks (the `subtasks` list is non-empty):**

This is a parent task. Switch to the multi-subtask flow in Step 1b. Do not treat the parent ticket itself as work to implement — it is only the container.

Fetch each subtask in full:
```
mcp__clickup__clickup_get_task { task_id: "<subtask-id>" }
```
Build an ordered list `SUBTASK_LIST` preserving the ClickUp order. For each subtask, parse its description using the 8-section plan-expert template if present (Context, What to implement, Where, Acceptance criteria, Out of scope, Technical notes, Depends on, Definition of done).

Store `PARENT_TICKET_ID`, `PARENT_TICKET_NAME`, and `SUBTASK_LIST`. Set `MULTI_SUBTASK_MODE = true`. Proceed to Step 1b.

**If the ticket has no subtasks:**

This is a leaf task. Parse the description using the 8-section plan-expert template if present. Set `MULTI_SUBTASK_MODE = false` and `CURRENT_TASK = this ticket`. Proceed directly to Step 2.

---

**Case B — `--description` provided (no ticket):**

Run the full `plan-expert` skill as defined in its SKILL.md, passing:
- `--description "<description>"` — the full description text

`plan-expert` will decompose the work into structured subtasks using its 8-section template and present them for confirmation. Once the user confirms, the resulting subtask plan is stored as `TASK_PLAN` and used as the implementation input for all subsequent steps.

Do not proceed to Step 2 until `plan-expert` has completed and the plan is confirmed.

---

**Case C — Neither provided:**

Use `AskUserQuestion`:
- Header: "Implement task"
- Question: "What do you want to implement? Paste a ClickUp ticket ID or describe the task."
- Options: `I have a ClickUp ticket ID`, `I'll describe the task`

If the user provides a ticket ID, treat as Case A.  
If the user provides a description, treat as Case B.

---

## Step 1b — Multi-subtask orchestration

> **Only enter this step when `MULTI_SUBTASK_MODE = true`.** Skip entirely for single tasks.

### Branch structure

Before implementing anything, infer the base branch (same logic as `create-pr` Step 3: check remote branches for `main` → `master` → `develop` → `staging`). Store as `BASE_BRANCH`.

Create a parent feature branch from `BASE_BRANCH`:

```bash
git checkout <BASE_BRANCH>
git checkout -b feat/CU-<PARENT_TICKET_ID>-<slug-of-parent-name>
```

Store this as `PREVIOUS_BRANCH`. This is the branch that subtask 1 will branch from.

### Execution loop

Present the full subtask list to the user before starting:

```
## Multi-subtask implementation plan

Parent: <PARENT_TICKET_NAME> (CU-<PARENT_TICKET_ID>)
Base branch: <BASE_BRANCH>
Parent branch: feat/CU-<PARENT_TICKET_ID>-<slug>

Subtasks to implement in order:
1. <subtask 1 name> (CU-<id>)  →  branch from: <PARENT_BRANCH>
2. <subtask 2 name> (CU-<id>)  →  branch from: subtask 1 branch
3. <subtask 3 name> (CU-<id>)  →  branch from: subtask 2 branch
...

Each subtask gets its own branch and PR/MR targeting the previous branch.
```

Ask:
> "Does this order look correct? Confirm to start implementing, or describe what to change."

Wait for confirmation. Once confirmed, iterate through `SUBTASK_LIST` in order. For each subtask:

1. Set `CURRENT_TASK = this subtask`
2. Set `CURRENT_BASE = PREVIOUS_BRANCH` (the branch this subtask will branch from)
3. Execute Steps 2 through 9 for `CURRENT_TASK`, using `CURRENT_BASE` wherever "base branch" is referenced in those steps (branch creation in Step 5 and PR target in Step 9)
4. After the PR is created, update `PREVIOUS_BRANCH = the branch just created for this subtask`
5. Move to the next subtask

Do not start subtask N+1 until subtask N has a committed branch and an open PR/MR.

### Multi-subtask report (replaces Step 10)

After all subtasks are complete, output this summary instead of the single-task report:

```
## Parent Task Implementation Complete

**Parent:** <PARENT_TICKET_NAME> (CU-<PARENT_TICKET_ID>)
**Base branch:** <BASE_BRANCH>
**Parent branch:** feat/CU-<PARENT_TICKET_ID>-<slug>

### Subtasks

| # | Subtask | Branch | PR/MR |
|---|---------|--------|----|
| 1 | <name> | <branch> | <PR/MR URL> |
| 2 | <name> | <branch> | <PR/MR URL> |
| … | … | … | … |

### Merge order
Merge PRs/MRs in the order listed above. Each PR/MR targets the previous branch —
merging out of order will produce incorrect diffs.

### Known gaps or follow-up
<any subtask whose Definition of done could not be fully completed, or "None">
```

Stop after outputting this report. Do not proceed to Step 10.

---

## Step 2 — Load project context

Read the following files if they exist at the project root:

- `AGENTS.md` — stack, framework, conventions, dev commands
- `DESIGN.md` — design tokens, component patterns, variant system

These files are the authority on how to write code for this project. If they do not exist, infer conventions from the codebase in Step 3.

---

## Step 3 — Understand the affected area

Before writing a single line of code, read the existing code in the area the task touches.

Use the **Where** section from the ticket or plan to locate the relevant files. Then:

1. **Glob** for files matching the area (e.g. all files in the target directory or matching the feature name)
2. **Read** each relevant file in full — components, services, routes, tests, types
3. **Grep** for patterns, function names, or imports referenced in the task to trace dependencies
4. Identify:
   - Naming conventions (file names, function names, variable names)
   - How similar features are structured in the existing codebase
   - Shared utilities, hooks, or services that should be reused
   - Test patterns (where tests live, what testing library is used, how test files are named)

Do not skip this step. Implementing without reading leads to convention violations that fail code review.

---

## Step 4 — Build the implementation plan

Produce a file-level plan before writing any code. The plan must list every concrete action needed:

```
## Implementation Plan: <task name>

### New files to create
- `<path/to/file>` — <one-line purpose>

### Files to modify
- `<path/to/file>` — <what changes and why>

### Files to delete
- `<path/to/file>` — <why it is being removed>

### Commands to run
- <e.g. run a migration, generate a type, update a lock file>

### Verification steps
- <lint command from AGENTS.md>
- <type check command>
- <test command targeting affected files>

### Out of scope (will not touch)
- <files or areas explicitly excluded — from the ticket's Out of scope section or plan-expert output>
```

Cross-reference the **Out of scope** section from the ticket or plan — do not implement anything listed there.

Present the plan to the user and ask:
> "Does this implementation plan look correct? Confirm to start, or describe what to change."

Wait for confirmation before proceeding. Do not start writing code until the plan is approved.

---

## Step 5 — Create a feature branch

Derive the branch name from `CURRENT_TASK`:

- Type prefix from the task nature: `feat/`, `fix/`, `refactor/`, `docs/`, `chore/`
- Ticket ID if available: `CU-<id>-`
- Slug from the task name: lowercase, hyphens, max 40 characters

Determine the source branch:
- **Single task** (`MULTI_SUBTASK_MODE = false`): branch from the inferred base branch (`main` / `master` / `develop`)
- **Multi-subtask** (`MULTI_SUBTASK_MODE = true`): branch from `CURRENT_BASE` (set by Step 1b for this iteration)

```bash
git checkout <source branch>
git checkout -b <type>/CU-<id>-<slug>
```

Example (single task): `feat/CU-abc123-add-user-auth-flow` branched from `main`  
Example (subtask 2): `feat/CU-sub2-add-token-service` branched from `feat/CU-sub1-add-auth-endpoint`

If the branch already exists locally, switch to it:
```bash
git checkout <branch>
```

---

## Step 6 — Implement

Execute the plan from Step 4 in order. For each action:

**Creating a file:**
- Follow the naming and structure conventions identified in Step 3
- Reuse existing utilities, components, and patterns — do not reinvent what already exists
- Match the code style of adjacent files exactly (indentation, import order, export style)

**Modifying a file:**
- Read the file again immediately before editing
- Make the minimum change required — do not refactor unrelated code
- Do not alter formatting of untouched lines

**Running commands:**
- Use the commands from `AGENTS.md` (dev commands section) as the authority
- If a command fails, diagnose and fix the root cause before continuing — do not skip

After all files are written, do a final pass:
- Re-read every file you created or modified
- Verify naming conventions, import patterns, and structure match the project
- Confirm the **Acceptance criteria** from the ticket or plan are addressed by the code

---

## Step 7 — Verify

### 7a — Automated checks

Run all applicable verification commands from `AGENTS.md`. At minimum:

```bash
# Lint
<lint command>

# Type check (if typed language)
<type check command>

# Tests targeting affected files
<test command> <affected file pattern>
```

If any command fails:
- Read the error output
- Fix the root cause in the affected file
- Re-run the failing command
- Do not mark 7a complete until all commands pass

### 7b — Code review

Run the full `code-review` skill as defined in its SKILL.md, scoping the review to the current feature branch:

- Pass the feature branch base as the `--base-branch` argument so the review covers only the files changed in this task
- `code-review` will run its Phase 1 (fast checks) and Phase 2 (SOLID / structural audit) on those files

**If `code-review` reports errors or warnings:**
- Apply every fix marked as ❌ Error — these are blocking
- Apply fixes marked as ⚠️ Warning unless they conflict with the task's explicit Out of scope section
- After applying all fixes, re-run the automated checks from 7a to confirm nothing broke
- Do not proceed until `code-review` produces no blocking errors

**If `code-review` reports no issues or only passing items:**
- Proceed to Step 8 immediately

Do not proceed to Step 8 with unresolved code-review errors.

---

## Step 8 — Commit

Stage only the files that are part of this task:

```bash
git add <file1> <file2> ...
```

Do not use `git add .` — it risks including unrelated changes or generated files.

Write the commit message following Conventional Commits:

```
<type>(<scope>): <short imperative description>

<body — bullet points of what was done, one per meaningful change>

Refs: <ticket ID or "n/a">
```

```bash
git commit -m "<message>"
```

If the commit is rejected by a pre-commit hook, fix the issue the hook reports and recommit. Do not use `--no-verify`.

---

## Step 9 — Open the PR/MR

Run the `create-pr` skill as defined in its SKILL.md, passing:
- `--auto` — skip confirmation steps inside `create-pr`
- `--ticket-id <id>` — the current subtask or single task ID
- `--base <branch>` — set explicitly:
  - **Single task**: the inferred base branch (`main` / `master` / `develop`)
  - **Multi-subtask**: `CURRENT_BASE` for this iteration (the previous subtask's branch, or the parent feature branch for subtask 1)

Passing `--base` explicitly prevents `create-pr` from re-inferring the target and ensures each subtask PR/MR targets its correct predecessor branch.

`create-pr` will populate the full PR/MR template from the diff against `--base`, auto-detect GitHub/GitLab from `origin` unless `--provider` is passed, and open the Draft PR/MR automatically. Capture the returned `PR_URL` or `MR_URL`.

---

## Step 10 — Report

```
## Task Implementation Complete

**Task:** <task name>
**Branch:** <branch name>
**PR/MR:** <PR_URL or MR_URL>

### What was implemented
<bullet list — semantics: add | update | fix | refactor | delete>

### Acceptance criteria
<for each criterion: ✅ Met | ⚠️ Partial — <note> | ❌ Not met — <reason>>

### Known gaps or follow-up
<items from Definition of done not yet completed, or "None">
```

---

## Constraints

- Never modify files outside the approved implementation plan without re-confirming with the user.
- Never disable linting, type checking, or test commands to force verification to pass.
- Never commit secrets, credentials, `.env` files, or generated build artifacts.
- Never use `git add .` or `git commit --no-verify`.
- If the task turns out to be significantly larger than estimated after reading the codebase, stop and surface it:
  > "After reading the codebase, this task is larger than the ticket suggests. Here is what I found: <summary>. Should I proceed, split the work, or adjust the scope?"
