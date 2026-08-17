---
name: create-pr
description: Creates a GitHub Pull Request or GitLab Merge Request (always as Draft) with a fully auto-populated standardized template. Infers the base branch, derives the description from the diff and commits, detects shared code impact, tags stakeholders from CODEOWNERS, and builds a concrete test plan from the changes. Uses gh for GitHub and glab for GitLab, preserving GitHub MCP fallback for GitHub PRs. Designed to run without human input when called by an agent, or with a confirmation step when invoked directly.
argument-hint: '[--base <branch>] [--ticket-id <id>] [--provider <auto|github|gitlab>] [--auto]'
allowed-tools: Bash AskUserQuestion mcp__github__create_pull_request mcp__github__list_branches
effort: low
---

# create-pr

**Role:** Senior engineer opening a pull request or merge request.
**Goal:** Auto-generate a complete, reviewer-ready PR/MR from git context alone. Every section is derived from the diff, commits, branch name, and project files — no manual writing required. When `--auto` is passed (or when called by another skill/agent), skip all confirmation steps and create the PR/MR immediately.

---

## Step 1 — Parse arguments

Parse `$ARGUMENTS` for:
- `--base <branch>` — target branch for the PR/MR (skip inference if provided)
- `--ticket-id <id>` — ClickUp or issue ID to reference (optional)
- `--provider <auto|github|gitlab>` — host provider to use; default is `auto`
- `--auto` — skip all confirmation steps and create the PR/MR without asking

Capture any provided values. Set `AUTO_MODE = true` if `--auto` is present. Set `PROVIDER_INPUT = auto` when `--provider` is omitted. Reject any provider value outside `auto`, `github`, or `gitlab` with a clear error before doing network operations.

---

## Step 2 — Gather git context

Run all commands via Bash. Capture every output — it feeds every section of the template.

```bash
# Current branch
git branch --show-current

# Remote URL (to detect provider and extract host/owner/repo)
git remote get-url origin

# Current git user email (to exclude from FYI tagging)
git config user.email

# All remote branches (for base branch inference)
git branch -r --format='%(refname:short)' | sed 's/origin\///'

# Last 20 commits on this branch (used for description and module inference)
git log HEAD --oneline -20

# All changed files vs each candidate base branch (resolved once base is confirmed)
# Run after base is resolved:
git diff <BASE_BRANCH>...HEAD --name-only
git diff <BASE_BRANCH>...HEAD --stat
git diff <BASE_BRANCH>...HEAD
```

Extract `HOST`, `OWNER`, and `REPO` from the remote URL:
- GitHub SSH: `git@github.com:owner/repo.git`
- GitHub HTTPS: `https://github.com/owner/repo.git`
- GitLab SSH: `git@gitlab.com:owner/repo.git` or `git@gitlab.example.com:group/subgroup/repo.git`
- GitLab HTTPS: `https://gitlab.com/owner/repo.git` or `https://gitlab.example.com/group/subgroup/repo.git`

Determine `PROVIDER`:
- If `--provider github` was passed, use `github`.
- If `--provider gitlab` was passed, use `gitlab`.
- If `--provider auto` is active and `origin` contains `github.com`, use `github`.
- If `--provider auto` is active and `origin` contains `gitlab.com`, use `gitlab`.
- If `--provider auto` is active and the host is not GitHub, treat remotes whose host or path contains `gitlab` as self-hosted GitLab and use `gitlab`.
- If auto-detection cannot identify the provider, stop and ask the caller to rerun with `--provider github` or `--provider gitlab`.

For GitLab repositories with nested groups, keep the full namespace as `OWNER` (for example, `group/subgroup`) and the final path segment as `REPO`.

If the working tree has uncommitted changes, warn:
> "Uncommitted changes detected. These will not be included in the PR/MR. Commit them first or proceed anyway."
In `AUTO_MODE`, proceed without asking.

---

## Step 3 — Infer the base branch

If `--base` was provided, use it as `BASE_BRANCH` without any confirmation or inference and skip to Step 4. This is always correct when called by `implement-task` — do not second-guess it.

Otherwise, infer from the remote branches list using this priority order:

1. `main`
2. `master`
3. `develop`
4. `staging`
5. First `release/*` branch found
6. If none of the above exist, use the most recently committed remote branch

If `AUTO_MODE` is false and the inferred branch is not `main` or `master`, confirm with the user:
> "Inferred base branch: `<branch>`. Is this correct?"
In `AUTO_MODE`, proceed with the inferred branch silently.

If the current branch equals `BASE_BRANCH`, stop:
> "The current branch is the same as the base branch. Switch to a feature branch first."

---

## Step 4 — Infer PR/MR title

Derive the PR/MR title from the branch name:
1. Strip the type prefix: `feat/`, `fix/`, `chore/`, `refactor/`, `docs/`, `hotfix/`
2. Strip any ticket/sprint/module prefix (e.g. `CU-abc123-`, `M3-S12-`)
3. Replace hyphens and underscores with spaces
4. Title-case the result
5. Prepend the type label in brackets: `[Feature]`, `[Fix]`, `[Refactor]`, `[Docs]`, `[Chore]`, `[Hotfix]`
6. If a ticket ID is available (from `--ticket-id` or extracted from the branch name), append it: `(CU-abc123)`

Example: `feat/CU-abc123-user-auth-flow` → `[Feature] User auth flow (CU-abc123)`

---

## Step 5 — Populate the PR/MR template

The canonical PR/MR body structure is defined in `templates/pull_request_template.md` at the project root of the **ShipFrame** repo (the repo where this skill lives). Read that file and use it as the exact skeleton — do not invent or remove sections. Populate every placeholder by analyzing the git context from Step 2. Instructions inside each section below describe how to derive the content — follow them precisely. The rendered output must not contain the instruction text or placeholder markers.

---

### Section: Description

Using the commit messages and `git diff` output:

- Write 2–4 bullet points summarising the "Why" (motivation / problem solved) and "What" (what was changed at a high level)
- Every bullet must start with exactly one of these semantic keywords: `add`, `update`, `fix`, `refactor`, `delete`
- Do not paste raw commit messages — rewrite them as coherent intent statements
- Be specific: reference function names, component names, or API routes where relevant

---

### Section: Type of Change

From the PR/MR title type label (inferred in Step 4) or the branch prefix, tick exactly one checkbox:

| Branch prefix / label | Checkbox to tick |
|---|---|
| `feat/` / `[Feature]` | `- [x] Feature` |
| `fix/` / `[Fix]` | `- [x] Bug Fix` |
| `refactor/` / `[Refactor]` | `- [x] Refactor` |
| `docs/` / `[Docs]` | `- [x] Docs` |
| `chore/` / `[Chore]` | `- [x] Chore` |
| `hotfix/` / `[Hotfix]` | `- [x] Hotfix` |

Leave all others unchecked.

---

### Section: Related Ticket

- If `--ticket-id` was provided, format it as a ClickUp URL: `https://app.clickup.com/t/<id>`
- If a ticket ID was extracted from the branch name (e.g. `CU-abc123`), use the same format
- If no ticket is available, write: `N/A`

---

### Section: Module

Parse the branch name and the last 20 commit messages for:

- **Migration Number / Section Name** — look for patterns like `M1`, `M2`, `M3`, `migration-1`, `section-2` in the branch name or commits. Extract as `M{N}`. If not found, write `<!-- TBD -->`.
- **Sprint** — look for patterns like `S12`, `sprint-12`, `sprint/12` in the branch name or commits. Extract as `S{N}`. If not found, write `<!-- TBD -->`.

Never invent values. Placeholders are correct when data is absent.

---

### Section: Shared Code Impact

Inspect the list of changed files (`git diff --name-only`) for any files inside directories that suggest shared or cross-cutting code:

- Common directory names: `shared/`, `core/`, `common/`, `lib/`, `utils/`, `helpers/`, `hooks/`, `composables/`, `services/`, `types/`, `constants/`

If any matches are found:
- Answer: **Yes**
- List each affected file path
- Add: `Team notified: No` (the author must verify before merge)

If no matches: Do not include the `### Shared Code Impact` section in the rendered PR body.

---

### Section: Breaking Changes

Analyze the git diff and commit messages for indications of breaking changes, such as:
- Modified or removed API route parameters/responses
- Changes to shared library function signatures/interfaces
- Database schema changes that remove or alter columns
- Commit messages containing `BREAKING CHANGE:` or `!` in the type prefix (e.g. `feat!:`)

If breaking changes are detected:
- Answer: **Yes**
- Describe what breaks and the required migration path for other developers

If no breaking changes: Do not include the `### Breaking Changes` section in the rendered PR body.

---

### Section: FYI

1. Check if a `CODEOWNERS` file exists at the project root or `.github/CODEOWNERS`.  
   If it exists, read it and extract GitHub handles (`@username`) mapped to the changed files.

2. Also run:
   ```bash
   git log <BASE_BRANCH>...HEAD --invert-grep -E --format="%ae" -- <changed files> | sort | uniq
   ```
   Map contributor emails to GitHub handles where possible (use the handle from CODEOWNERS if the same person appears there).

3. Combine both sources into a de-duplicated list of `@handles`.

4. **Mandatory:** remove the current PR author's handle from the list (identified by `git config user.email` from Step 2).

5. If the list is empty after deduplication, write: `No additional stakeholders identified.`

---

### Section: Screenshots

Inspect the changed file paths for UI indicators:
- Directories: `pages/`, `views/`, `routes/`, `screens/`, `app/`, `src/app/`
- File extensions or names containing: `.vue`, `.svelte`, `Page.`, `View.`, `Screen.`, `Layout.`
- Any component file touched inside a route-level directory

**If UI changes are detected:**
- List each modified route or page
- For each, provide a provider-specific raw/blob URL format for evidence screenshots:
  ```
  # GitHub
  https://github.com/<OWNER>/<REPO>/blob/<CURRENT_BRANCH>/.github/evidence/<filename>.png?raw=true

  # GitLab
  https://<HOST>/<OWNER>/<REPO>/-/blob/<CURRENT_BRANCH>/.github/evidence/<filename>.png
  ```
- Note: "Add screenshots at the paths above before requesting review."

**If no UI changes:** write: `No UI changes in this PR.`

---

### Section: Test Plan

Derive a concrete, ordered checkbox list a reviewer can follow to verify the changes end-to-end.

Rules:
- Every step must come from the actual diff — no generic steps like "verify the app works"
- Start from the entry point a real user or caller would use (navigate to a route, call an endpoint, trigger an action)
- Cover the happy path first, then at least one edge or error case if changes touch validation, error handling, or conditional logic
- Include any required setup (env vars, feature flags, seed data, running migrations)
- One action per checkbox — short and imperative
- If the change is backend-only: describe the API call (method, endpoint, payload, expected response)
- If the change is UI-only: describe the user interaction and the expected visual or functional outcome
- If new tests were added: include a step to run them with the specific command (e.g. `npm test -- --testPathPattern=<file>`)

Format:
```
- [ ] <imperative step>
- [ ] <imperative step>
```

---

### Section: Release Readiness

- `Ready for release:` Yes — if all test plan steps are expected to pass based on the implementation
- `Needs additional work:` No — unless there are known gaps, open questions, or incomplete items identified during implementation

---

## Step 6 — Render and confirm

Assemble the full PR body using this exact structure:

```markdown
## Description 📝
<populated description bullets>

### Type of Change
<checkbox list with exactly one item checked based on branch type>

### Related Ticket
<ticket URL or "N/A">

### Module
- Migration: <M{N} or TBD>
- Sprint: <S{N} or TBD>

### Shared Code Impact
<Include only if Yes: file list and Team notified>

### Breaking Changes
<Include only if Yes: describe what breaks and the migration path>

### FYI 🙋
<@handles or "No additional stakeholders identified.">

### Screenshots 📸
<screenshot entries or "No UI changes in this PR.">

### Test Plan 🧪
<checkbox list>

### Release Readiness
- Ready for release: <Yes/No>
- Needs additional work: <Yes/No>
```

If `AUTO_MODE` is **false**, present the rendered body and the inferred title to the user and ask:
> "Does this PR/MR look correct? Reply Yes to create it, or paste corrections."
Apply any corrections before proceeding.

If `AUTO_MODE` is **true**, skip confirmation and proceed immediately.

---

## Step 7 — Create the PR/MR

**All PRs and MRs must be created as Draft. This is non-negotiable — never omit `--draft`.**

Before invoking provider CLIs, write the rendered body to a temporary file and keep its path in `BODY_FILE` so the user can reuse it if creation fails:

```bash
BODY_FILE="$(mktemp -t shipframe-pr-mr-body.XXXXXX.md)"
printf '%s\n' "<rendered PR/MR body>" > "$BODY_FILE"
```

### GitHub provider: gh CLI

Use this path when `PROVIDER=github`.

First verify the local CLI and authentication:

```bash
command -v gh
gh auth status
```

If `gh` is missing or unauthenticated, stop and report:

```text
GitHub PR not created. ShipFrame generated the body at <BODY_FILE>.
Install/authenticate GitHub CLI, then rerun:
  brew install gh
  gh auth login
  gh auth status
```

Create the Draft PR:

```bash
gh pr create \
  --title "<PR/MR title>" \
  --body-file "$BODY_FILE" \
  --base "<BASE_BRANCH>" \
  --head "<current branch>" \
  --draft
```

If the command exits with a non-zero status, capture the error and proceed to the GitHub MCP fallback below.

### GitHub fallback: GitHub MCP (only if gh CLI fails)

If `gh pr create` failed, create the PR using the MCP tool:

```
mcp__github__create_pull_request {
  owner: "<OWNER>",
  repo: "<REPO>",
  title: "<PR/MR title>",
  body: "<rendered PR/MR body>",
  head: "<current branch>",
  base: "<BASE_BRANCH>",
  draft: true
}
```

If both GitHub methods fail, report the errors from both attempts, include `BODY_FILE`, and stop.

### GitLab provider: glab CLI

Use this path when `PROVIDER=gitlab`. There is no GitLab MCP fallback in ShipFrame v1.

First verify the local CLI and authentication:

```bash
command -v glab
glab auth status
```

If `glab` is missing or unauthenticated, stop and report:

```text
GitLab MR not created. ShipFrame generated the body at <BODY_FILE>.
Install/authenticate GitLab CLI, then rerun:
  brew install glab
  glab auth login
  glab auth status
```

Create the Draft MR:

```bash
glab mr create \
  --title "<PR/MR title>" \
  --description "$(cat "$BODY_FILE")" \
  --target-branch "<BASE_BRANCH>" \
  --source-branch "<current branch>" \
  --draft \
  --yes
```

If `glab mr create` fails, report the captured error, include `BODY_FILE`, and stop. Do not fall back to GitHub MCP for GitLab remotes.

---

## Step 8 — Report

```
## Pull Request / Merge Request Created (Draft)

Title:    <title>
URL:      <pr_or_mr_url>
Provider: <github|gitlab>
Base:     <BASE_BRANCH> <- <current branch>
Files:    <count> changed
Method:   <gh CLI | GitHub MCP (fallback) | glab CLI>
Body:     <BODY_FILE>
```

Store `PR_URL` or `MR_URL` and the request number/IID in context — downstream skills or agents may need them.
