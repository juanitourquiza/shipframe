---
name: plan-expert
description: Plan a ticket or task into ordered subtasks with context, acceptance criteria, out-of-scope, and done definition.
argument-hint: '[--ticket-id <id>] [--description "<text>"]'
allowed-tools: Read Grep Glob Bash AskUserQuestion mcp__clickup__clickup_get_task mcp__clickup__clickup_create_task mcp__clickup__clickup_get_workspace_hierarchy TaskCreate TaskUpdate Skill
effort: medium
---

# plan-expert

**Role:** Senior Technical Project Planner.  
**Goal:** Decompose a task, ticket, or description into a precise, ordered, actionable execution plan with enough detail that any engineer on the team can pick up and implement each step independently.

---

## Usage

**Plan from a ClickUp ticket:**
```
/plan-expert --ticket-id abc123xyz
```

**Plan from a description:**
```
/plan-expert --description "Build a user authentication flow with email and OAuth"
```

**Plan from both (description overrides/extends the ticket):**
```
/plan-expert --ticket-id abc123xyz --description "Focus only on the backend part"
```

**Without arguments** — Claude will ask the user what to plan:
```
/plan-expert
```

---

## Step 1 — Resolve Input

Parse `$ARGUMENTS` to extract `--ticket-id` and `--description`.

**Case A — Neither argument provided:**  
Use `AskUserQuestion` with:
- Question: "What do you want to plan?"
- Header: "Plan Expert"
- Accept free-form text. Treat the answer as the `--description` input and continue to Step 2B.

**Case B — `--ticket-id` provided:**  
Fetch the ticket using the ClickUp MCP:
```
mcp__clickup__clickup_get_task { task_id: "<ticket-id>" }
```
Extract from the response:
- `name` → task title
- `description` → full task description (may be markdown or plain text)
- `status` → current status
- `assignees` → assigned team members
- `subtasks` (if any already exist — note them to avoid duplication)

If the ticket cannot be fetched, inform the user: "Could not fetch ticket `<id>`. Please check the ID or verify ClickUp MCP access." and stop.

**Case C — `--description` provided (no ticket):**  
Use the description text directly as the planning input. Skip to Step 2.

**Case D — Both provided:**  
Fetch the ticket as in Case B. Treat the `--description` as a scope modifier or focus area that overrides or narrows the ticket content for planning purposes. Note both sources when generating the plan.

---

## Step 2 — Analyze & Decompose

Read the resolved input (ticket content and/or description) carefully. Think as a senior engineer scoping a sprint ticket.

### 2.0 Establish codebase scope (REQUIRED — do this before anything else)

Explore the repository to determine what layers and technologies are actually present. Use `Glob`, `Grep`, and `Read` to inspect the project structure. Identify:

- **Project type** — Is this a frontend-only app, a backend API, a full-stack monorepo, a mobile app, a CLI tool, etc.?
- **Tech stack** — Languages, frameworks, and runtimes in use (e.g., React, Next.js, Node/Express, Django, Rails, etc.)
- **Layers present** — Which of the following actually exist in this repo: UI/components, API routes, database models, auth logic, infrastructure config, etc.

**Hard rule: you may only plan work that lives inside the codebase you are operating on.** If the task description implies work in a layer that does not exist in this repo (e.g., backend endpoints in a frontend-only project, database migrations in a UI library, mobile screens in a web app), do NOT plan those subtasks. Instead, flag them explicitly:

> ⚠️ Out of codebase scope: `<description of the work>` requires a `<layer>` that does not exist in this repository. This must be planned and executed in a separate project.

Do not assume a layer exists just because the task description mentions it. Verify in the actual code first.

### 2.1 Identify the goal

Summarize the objective in one sentence: what needs to be true when this is done?

### 2.2 Identify concerns

For each of the following areas, decide if it is relevant to this task. Only include areas that actually apply:

- **Backend / API** — endpoints, business logic, data models, migrations
- **Frontend / UI** — components, pages, routing, state management
- **Database** — schema changes, queries, indexes, seeds
- **Authentication / Authorization** — access control, roles, sessions
- **Integrations** — third-party APIs, webhooks, SDKs
- **Testing** — unit, integration, E2E
- **Infrastructure / DevOps** — deployment, env vars, CI/CD
- **Documentation** — README, inline docs, API docs
- **Security** — input validation, secrets, permissions
- **Performance** — caching, pagination, query optimization

### 2.3 Decompose into subtasks

Break the work into sequential subtasks. Each subtask must:
- Have a clear, imperative title starting with a verb (e.g., "Add `POST /auth/login` endpoint", "Write unit tests for TokenService")
- Be independently completable by one engineer
- Be scoped to a single concern — avoid "and" in the title
- Be populated using the **Subtask Template** defined in Step 3

Order subtasks from foundational to dependent (data layer → logic → API → UI → tests → docs).

Aim for 4–10 subtasks for most tasks. If the task is very large, note that it should be split into separate tickets after planning.

Every field in the template is required. If a field genuinely does not apply (e.g., "Out of scope" has nothing notable), write "N/A" — never omit the field.

---

## Step 3 — Output the Plan

> **MANDATORY TEMPLATE RULE**
> Every subtask — without exception — must be written using the template below.
> All 8 sections are required in every subtask, both in this preview and in what gets written to ClickUp or local files.
> If a section has nothing to say, write `N/A`. Never skip, collapse, or summarize a section.

Present the full plan before taking any write actions:

```
## Plan: <task title or goal>

**Goal:** <one-sentence objective — what must be true when this is done>
**Scope:** <comma-separated concern areas from 2.2>
**Subtasks:** <count>

---

### Subtask 1 — <imperative title starting with a verb>

#### Context
<Why this subtask exists and how it fits the overall goal. One or two sentences.>

#### What to implement
<Detailed description of the work — no ambiguity. Use bullet points for multi-part work.>

#### Where
<Specific file paths, modules, or layers involved. If not inferable, write the closest known location.>

#### Acceptance criteria
- [ ] <Specific, testable criterion — written so a reviewer can verify it without asking questions>
- [ ] <Add as many criteria as needed>

#### Out of scope
<Explicitly list what this subtask must NOT do. If nothing notable, write "N/A".>

#### Depends on
<"Subtask N — <title>" for each blocker. If none, write "None".>

#### Technical notes
<Implementation hints, known edge cases, gotchas, or relevant prior art in the codebase. If nothing notable, write "N/A".>

#### Definition of done
- [ ] Implementation satisfies all acceptance criteria above
- [ ] Relevant unit or integration tests written and passing
- [ ] No new lint, type, or build errors introduced
- [ ] Code reviewed and approved by at least one teammate
- [ ] Any new public API or behavior is documented (inline or in relevant docs)

---

### Subtask 2 — <imperative title starting with a verb>

#### Context
<...>

#### What to implement
<...>

#### Where
<...>

#### Acceptance criteria
- [ ] <...>

#### Out of scope
<...>

#### Depends on
<...>

#### Technical notes
<...>

#### Definition of done
- [ ] Implementation satisfies all acceptance criteria above
- [ ] Relevant unit or integration tests written and passing
- [ ] No new lint, type, or build errors introduced
- [ ] Code reviewed and approved by at least one teammate
- [ ] Any new public API or behavior is documented (inline or in relevant docs)

---

(repeat the full template for every subsequent subtask)
```

After presenting the plan, ask:

> "Does this plan look correct? Should I proceed to create the subtasks?"

Wait for user confirmation before proceeding to Step 4.

---

## Step 4 — Write Subtasks

### If `--ticket-id` was provided (Case B or D):

Fetch the parent task's `list` field to get the correct `list_id`. Create each subtask in order (1 → N) using:

```
mcp__clickup__clickup_create_task {
  list_id: "<same list as parent task>",
  name: "<subtask title>",
  description: "<full subtask body using the template from Step 3 — all sections included>",
  parent: "<ticket-id>"
}
```

The `description` field must be the complete rendered template for that subtask exactly as presented in Step 3 — all 8 sections in order: Context, What to implement, Where, Acceptance criteria, Out of scope, Depends on, Technical notes, Definition of done. Do not abbreviate, merge, or omit any section. A task created without all 8 sections is invalid.

After all subtasks are created, report:

```
## Subtasks Created

✅ Subtask 1 — <title> (id: ...)
✅ Subtask 2 — <title> (id: ...)
...

All subtasks have been added to ticket <ticket-id>.
```

### If only `--description` was provided (Case C):

First, create a parent ClickUp task for this work by delegating to the `create-task` skill. Pass the description and let `create-task` classify it and apply the correct template:

```
/create-task --input "<planning description>"
```

`create-task` will:
1. Classify the input into the appropriate task type ([US], [TASK], [IMP], etc.)
2. Fill out the standardized template
3. Ask the user to confirm the ticket
4. Ask which ClickUp list to use
5. Create the parent task and return the task ID and URL

After `create-task` completes, capture `PARENT_TICKET_ID` and `PARENT_TICKET_URL` from its output.

Then create each subtask as a child of the parent task using:

```
mcp__clickup__clickup_create_task {
  list_id: "<same list as parent task>",
  name: "<subtask title>",
  description: "<full subtask body using the template from Step 3 — all sections included>",
  parent: "<PARENT_TICKET_ID>"
}
```

The `description` field must be the complete rendered template for that subtask — all 8 sections in order. Do not abbreviate, merge, or omit any section.

After all subtasks are created, report:

```
## Subtasks Created

✅ Subtask 1 — <title> (id: ...)
✅ Subtask 2 — <title> (id: ...)
...

Parent ticket: <PARENT_TICKET_URL>
All subtasks have been added to the parent ticket.
```

**Fallback (if user declines ClickUp creation in `create-task`):** create local tasks using `TaskCreate` for each subtask and report:

```
## Task List Created (local)

✅ Task 1 — <title>
✅ Task 2 — <title>
...

These tasks are local to this session. To persist them in ClickUp, run `/create-task` to create a ticket, then re-run `/plan-expert --ticket-id <id>`.
```

---

## Constraints

- **Every task written — to ClickUp or locally — must use the mandatory 8-section template defined in Step 3. No exceptions. A task missing any section is incomplete and must not be created.**
- **Never plan work outside the codebase scope established in Step 2.0.** If a task implies work in a layer not present in this repository, flag it with `⚠️ Out of codebase scope:` and exclude it from the generated subtasks. Do not assume any layer exists without verifying it in the actual code.
- Do not invent technical details that cannot be inferred from the input. If a detail is ambiguous, note it explicitly in the subtask description as: `⚠️ Clarify: <question>`.
- Do not create subtasks for work that is already marked as done in the existing ticket subtasks.
- Do not skip the user confirmation step between Step 3 and Step 4.
- If the ticket is in a "done" or "closed" status, warn the user before proceeding: "This ticket appears to be already closed. Do you still want to create subtasks on it?"
