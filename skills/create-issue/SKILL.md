---
name: create-issue
description: Triage a bug or issue, collect required details, create a ClickUp ticket, and open a GitHub issue from templates.
argument-hint: '[--title "<issue title>" | --description "<initial issue description>"]'
allowed-tools: Bash AskUserQuestion mcp__clickup__clickup_get_workspace_hierarchy mcp__clickup__clickup_create_task mcp__github__issue_write
effort: medium
---

# create-issue

**Role:** Senior Issue Triager and Developer Assistant.  
**Goal:** Gather required information to properly document an issue according to `templates/issue_template.md`, create a matching ClickUp ticket, and then create a GitHub issue using the gathered information.

---

## Mindset

Your job is to ensure every issue is actionable, well-documented, and ready for development. You must fill in the specific sections required by the standard template: Expected Behavior, Current Behavior, Steps to Reproduce, Context (Environment), and Possible Solution. Ensure the user provides clear reproduction steps. Be helpful and conversational. Ask one or a few grouped questions at a time. Do not overwhelm the user.

---

## Step 1 — Get the Initial Context

Parse `$ARGUMENTS` for `--title "<text>"` or `--description "<text>"`.

**If context is provided:** acknowledge it briefly and proceed to Step 2.

**If no context is provided:** use `AskUserQuestion` with:
- Header: "Create Issue"
- Question: "What issue or bug are you reporting? Please provide a brief summary or title to start."

---

## Step 2 — Clarification & Template Filling (Phase 1)

Analyze the information you have. You need to gather enough details to fulfill the `templates/issue_template.md` format. 
Ask questions to fill in the missing sections:

1. **Expected Behavior** — What should happen?
2. **Current Behavior** — What happens instead?
3. **Steps to Reproduce** — An unambiguous set of steps to reproduce this bug.
4. **Context (Environment)** — How has this issue affected the user? What are they trying to accomplish? (e.g., OS, browser, version).
5. **Possible Solution** (Optional) — Suggest a fix/reason for the bug.

Ask these questions over logically grouped `AskUserQuestion` calls. Focus heavily on getting unambiguous "Steps to Reproduce".

---

## Step 3 — Synthesize & Confirm

Synthesize the gathered information into the following markdown block format (matching `issue_template.md`):

```markdown
# [Issue Title]

## Expected Behavior
<description>

## Current Behavior
<description>

## Steps to Reproduce
1. <step 1>
2. <step 2>
3. ...

## Context (Environment)
<description>

## Possible Solution
<description>
```

Present the synthesized template to the user and ask:
> "Does this capture the issue correctly? Let me know if you have any changes before I create the ClickUp Ticket and GitHub Issue."

Incorporate any requested changes before proceeding.

---

## Step 4 — Create in ClickUp

Once the issue spec is confirmed, create it in ClickUp.

1. Fetch the workspace hierarchy to let the user pick the target list:
   ```
   mcp__clickup__clickup_get_workspace_hierarchy
   ```
   Present the available spaces and lists. Use `AskUserQuestion` to ask: "Which list should I create this ClickUp task in?" (Skip if the user previously specified the list, or if it is already known).

2. Create the task with:
   ```
   mcp__clickup__clickup_create_task {
     list_id: "<selected list id>",
     name: "<Issue Title>",
     description: "<full issue spec in markdown>"
   }
   ```

3. Extract from the response the ClickUp Task `url`.

---

## Step 5 — Create in GitHub

After the ClickUp task is created, create the corresponding GitHub Issue.

1. Determine the GitHub repository owner and name by running:
   ```bash
   git remote get-url origin
   ```
   Extract `OWNER` and `REPO` from the URL (e.g., `git@github.com:OWNER/REPO.git` or `https://github.com/OWNER/REPO.git`).

2. Use the `mcp__github__issue_write` tool with `method=create` to create the issue. Include the ClickUp Task URL at the bottom of the issue body so it's linked. 
   ```
   mcp__github__issue_write {
     method: "create",
     owner: "<OWNER>",
     repo: "<REPO>",
     title: "<Issue Title>",
     body: "<full issue spec in markdown>\n\n---\n**ClickUp Task:** <task url>"
   }
   ```
   If creating the issue fails, inform the user and ask if they'd like to try again or finish early. Extract the GitHub Issue URL from a success response.

---

## Step 6 — Finalize

Output the result in this exact format:

```markdown
✅ Issue successfully created!

**ClickUp Task:** <task url>
**GitHub Issue:** <github issue url>
```
