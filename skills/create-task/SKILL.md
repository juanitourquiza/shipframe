---
name: create-task
description: Create a ClickUp task from raw input by classifying it as US, BUG, IMP, TASK, or SPIKE and filling the template.
argument-hint: '[--input "<raw description>" | --type <US|BUG|IMP|TASK|SPIKE>]'
allowed-tools: Read Bash AskUserQuestion mcp__clickup__clickup_get_workspace_hierarchy mcp__clickup__clickup_create_task
effort: medium
---

# create-task

**Role:** Senior Issue Triager following the agency's unified task creation standard.  
**Goal:** Transform any raw input — a client message, a rough idea, a transcribed audio — into a well-structured ClickUp task using the correct template and the master prompt rules from the agency's task creation guide (Version 1.0, June 2026).

---

## Master Prompt Rules (always apply)

1. Title always starts with the task type in brackets: `[US]`, `[BUG]`, `[IMP]`, `[TASK]`, or `[SPIKE]`.
2. Never invent information not present in the input — mark missing critical fields with `⚠ MISSING: [what's missing]`.
3. Do not include technical implementation details in functional tasks (US, IMP) — that belongs in Technical Notes or separate subtasks.
4. AC criteria must be functional and testable. Avoid vague criteria like "works correctly".
5. If the input is ambiguous in scope, take the most conservative interpretation and add an "Open Questions" section at the end.
6. Use direct language, no filler. The ticket must be taken by a dev without prior meetings.
7. Every ticket must end with a "Summary" section: max 3 lines covering what to do, why, and how to verify it's done.

---

## Step 1 — Gather Input

Parse `$ARGUMENTS` for:
- `--input "<text>"` — the raw description to process
- `--type <US|BUG|IMP|TASK|SPIKE>` — force a specific task type (skip classification)

**If `--input` is provided:** acknowledge briefly and proceed to Step 2.

**If no input is provided:** use `AskUserQuestion` with:
- Header: "Create Task"
- Question: "Describe the task, bug, or idea you want to capture. You can paste a client message, a rough note, or a voice transcription — I'll handle the formatting."

---

## Step 2 — Classify the Task Type

If `--type` was explicitly provided, use that type and skip classification.

Otherwise, analyze the raw input and classify it into one of the 5 types using these rules:

| Type | When to use |
|---|---|
| `[US]` | Describes a new feature or capability from a user's perspective. Focus is on what the user wants to achieve. |
| `[BUG]` | Describes something that is broken, behaves unexpectedly, or produces an error. |
| `[IMP]` | Describes an improvement, change, or redesign of an existing feature. Not a new feature and not a bug. |
| `[TASK]` | Describes internal technical work: refactoring, infrastructure, tooling, migrations, configuration. No user-facing story. |
| `[SPIKE]` | Describes an investigation or research effort needed before committing to implementation. Centers on a specific question. |

If the input clearly maps to one type, proceed silently.

If the input is ambiguous between two types (e.g., IMP vs US), state your classification and reasoning in one line before continuing:
> "I'm classifying this as `[IMP]` because it modifies an existing feature rather than introducing new functionality."

---

## Step 3 — Read the Corresponding Template

Based on the classified type, read the template file:

| Type | Template file |
|---|---|
| `[US]` | `templates/clickup/us_task_template.md` |
| `[BUG]` | `templates/clickup/bug_task_template.md` |
| `[IMP]` | `templates/clickup/imp_task_template.md` |
| `[TASK]` | `templates/clickup/task_task_template.md` |
| `[SPIKE]` | `templates/clickup/spike_task_template.md` |

Use the `Read` tool to load the template. This is the exact structure that must be used — do not invent or remove sections.

---

## Step 4 — Fill Out the Template

Populate every field in the template using only information present in the input. Apply the master prompt rules strictly:

- **Required fields:** must be filled. If the input does not provide enough information, mark the field with `⚠ MISSING: [description of what's missing]` — never leave a required field blank or invent content.
- **Optional fields:** fill them only if the input contains relevant information. If there is nothing to say, omit the entire optional section from the output.
- **AC criteria:** write each criterion as a functional, testable statement a QA engineer can verify independently.
- **"Summary":** always include this section at the end. Summarize in 3 lines max: what to do, why it matters, and how to confirm it's done.
- **Open questions:** if the input is ambiguous about scope, add an "Open Questions" section at the end listing each uncertainty as a numbered question.

Produce the fully filled-out ticket as a markdown block.

---

## Step 5 — Confirm with User

Present the filled-out ticket to the user and ask:

> "Here is the ticket I'm going to create in ClickUp. Does this look correct? Let me know if you'd like any changes before I create it."

Incorporate any requested changes. Repeat if necessary until the user confirms.

---

## Step 6 — Select Target List in ClickUp

Fetch the workspace hierarchy to identify the correct list:

```
mcp__clickup__clickup_get_workspace_hierarchy
```

Present the available spaces and lists in a readable format. Use `AskUserQuestion` to ask:

> "Which ClickUp list should I create this ticket in?"

Skip this step if the user already specified a list name or ID in the original input or arguments.

---

## Step 7 — Create the Task in ClickUp

Create the task using:

```
mcp__clickup__clickup_create_task {
  list_id: "<selected list id>",
  name: "<ticket title>",
  description: "<full ticket body in markdown — all sections>"
}
```

The `description` must contain the complete filled-out template — all sections in order, exactly as confirmed in Step 5. Do not truncate, summarize, or omit any section.

Extract the `url` from the response.

---

## Step 8 — Report

Output the result in this exact format:

```
✅ Task successfully created in ClickUp.

Type:   <[US] | [BUG] | [IMP] | [TASK] | [SPIKE]>
Title:  <task title>
URL:    <clickup task url>
```

If any required fields were marked with `⚠ MISSING:`, include a reminder:

```
⚠ Incomplete fields: some required fields could not be filled with the available information.
  Review the ticket and complete the fields marked with ⚠ MISSING before assigning it.
```
