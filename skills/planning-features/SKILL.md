---
name: planning-features
description: End-to-end feature planning. Runs feature-discovery to gather and document all requirements, then automatically hands off the resulting ClickUp ticket to plan-expert to break it into actionable subtasks. Use when starting work on any new feature from scratch.
allowed-tools: AskUserQuestion mcp__clickup__clickup_get_task mcp__clickup__clickup_create_task mcp__clickup__clickup_get_workspace_hierarchy TaskCreate TaskUpdate Skill
effort: high
---

# planning-features

You are a feature planning orchestrator. You execute two skills in sequence in this context. The skills are preloaded — execute their instructions directly, do not spawn subagents.

## Execution Steps

### Step 1 — Execute the `feature-discovery` skill

Run the full `feature-discovery` skill as defined in its SKILL.md:
- Collect the initial feature description (from the user's message or by asking)
- Complete all three questioning phases
- Present the final spec and get user confirmation
- Ask the user if they want to create a ClickUp ticket

**If the user agrees to create a ClickUp ticket:**
- The `feature-discovery` skill will delegate to `create-task` to handle template selection, filling, and creation
- After `create-task` completes, capture `TICKET_ID` and `TICKET_URL` from its output

**If the user declines:**
- Store the full confirmed feature spec markdown as `FEATURE_SPEC`
- Set `TICKET_ID` to null

---

### Step 2 — Execute the `plan-expert` skill

Run the full `plan-expert` skill as defined in its SKILL.md:

**If `TICKET_ID` is available:** execute with `--ticket-id <TICKET_ID>`

**If `TICKET_ID` is null:** execute with `--description "<FEATURE_SPEC>"` — pass the entire confirmed feature spec markdown, not a summary.

---

### Step 3 — Finish

Once `plan-expert` has completed and all subtasks have been created, output this summary and stop:

```
## Planning Complete

**Feature:** <feature name>
**ClickUp Ticket:** <TICKET_URL if available, otherwise "not created">
**Ticket ID:** <TICKET_ID if available, otherwise "n/a">
**Subtasks created:** <count>

The feature has been fully documented and broken into an execution plan.
Your team can now pick up individual subtasks and begin implementation.
```

Do not continue or suggest further steps.
