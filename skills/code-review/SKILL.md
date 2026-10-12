---
name: code-review
description: Review changed code before commit or PR with fast checks plus pragmatic structural, security, performance, and test coverage audit.
argument-hint: '[--base-branch <branch>]'
allowed-tools: Read Grep Glob Bash
effort: high
---

# code-review

Two-phase code review skill. Phase 1 catches surface-level issues. Phase 2 evaluates structural correctness and maintainability in context, using SOLID, KISS, DRY, and YAGNI as complementary review lenses.

## Usage

**With a base branch** — reviews only the files changed between your current branch and the specified base:
```
/code-review --base-branch main
/code-review --base-branch develop
/code-review --base-branch origin/main
```

**Without arguments** — Claude will detect your local branches and ask you to pick the base interactively:
```
/code-review
```
You'll be prompted with a question like:
> "Which branch should be used as the base for this review?"
> Options: `main`, `master`, `develop`, or any other local branch detected. Select one or type a custom name.

> **Tip:** Run `/init-project` first if the project has no `AGENTS.md`. The review uses it for stack-aware checks in Phase 1.

---

> **Mindset**: There is no reward for speed. The reward comes from persistence on resolving issues to a high standard. Consistent iteration produces better outcomes than fast completion.

---

## Setup — Resolve Base Branch

Current branch: `!git branch --show-current`

Available local branches:
```
!git branch
```

**Step 1 — Parse the argument.**
Check if `$ARGUMENTS` contains `--base-branch`. If it does, extract the value that follows it and use that as `BASE_BRANCH`. Skip to Step 3.

**Step 2 — Ask the user (only if `--base-branch` was not provided).**
Use `AskUserQuestion` with the following question:

- Question: "Which branch should be used as the base for this review?"
- Header: "Base branch"
- Build the options from the branch list above. Always include the most common default (`main`) plus any branches found locally. Cap at 4 options; if there are more, include the 3 most relevant and leave "Other" for free input. If there is no more options but default, just use the default.

**Step 3 — Scope the review to changed files.**
Run:
```
git diff <BASE_BRANCH>...HEAD --name-only
```
Read only the files returned by that command. Do not review files that were not changed relative to `BASE_BRANCH`.

If the diff is empty, inform the user: "No changes detected between the current branch and `<BASE_BRANCH>`." and stop.

---

## Phase 1 — Fast Pre-Commit Check

Catch the 80% of issues before going deeper. Run this first.

### 1.1 Spec & Logic

- [ ] Code exactly matches the stated requirements — no more, no less
- [ ] Edge cases are handled: empty states, null/undefined, error boundaries
- [ ] No leftover debug artifacts: `console.log`, commented-out code, TODO-without-ticket

### 1.2 Type Safety & Validation

- [ ] No unconstrained `any` / `unknown` casts without justification
- [ ] External input (API responses, form data, env vars) is validated at the boundary
- [ ] Types are derived from a single source of truth — not duplicated across files

### 1.3 Stack Alignment

Check the detected stack (see `AGENTS.md` if available) and verify conventions are followed:
- Framework-specific patterns are used correctly (e.g., server vs. client components, lifecycle hooks, routing conventions)
- Styling follows the project's chosen approach consistently
- ORM/database queries follow the project's data-access layer patterns

### 1.4 Verification

- [ ] Existing tests pass
- [ ] New behavior has test coverage (unit or integration)
- [ ] There is observable evidence the change works (test output, screenshot, logs)


### 1.5 Security Checks

- [ ] No hardcoded secrets or credentials
- [ ] No sensitive data in logs or error messages
- [ ] Input validation prevents injection attacks
- [ ] Dependencies are up to date

### 1.6 Performance Checks

- [ ] No N+1 queries
- [ ] No unnecessary database queries
- [ ] No unnecessary API calls
- [ ] No unnecessary computations

**Phase 1 outcome:**
- All items pass → proceed to Phase 2
- Any item fails → fix and re-run Phase 1 before continuing

---

## Phase 2 — Contextual Structural Review

Use SOLID, KISS, DRY, and YAGNI as lenses, not quotas or automatic design prescriptions. A review finding must point to a concrete correctness, safety, maintainability, or changeability problem in this code and explain when it occurs. Prefer the smallest fix that resolves that problem; do not request a refactor for style or hypothetical future needs.

### Gate 1: Single Responsibility (SRP)

- **Pass:** Responsibilities are cohesive, and the code is understandable in its context. Function length and nesting are signals to investigate, not limits that require decomposition by themselves.
- **Fail:** Mixed responsibilities or control flow make a concrete behavior difficult to understand, change, or verify (for example, an I/O side effect in a function presented as pure).
- **Action on Fail:** Propose the smallest responsibility split that improves the demonstrated problem. Do not split code merely to meet a line-count target or create helpers used only to shorten a function.

### Gate 2: Open/Closed + Liskov Substitution (OCP/LSP)

- **Pass:** Changes preserve the contracts callers rely on. Modifying existing code is acceptable when it is the clearest, safest way to implement the requested behavior.
- **Fail:** A concrete change or caller breaks an existing contract, or repeated real variations already make conditional logic error-prone.
- **Action on Fail:** Fix the contract break first. Recommend polymorphism or another extension point only when the code has genuine variation that benefits from it; do not introduce patterns for hypothetical future types.

### Gate 3: Interface Segregation + Dependency Inversion (ISP/DIP)

- **Pass:** Callers depend only on the behavior they need. Concrete dependencies are fine when they are stable and do not cause a demonstrated testing or changeability problem.
- **Fail:** A concrete dependency or broad interface prevents a required substitution, forces callers to support unused behavior, or makes relevant behavior untestable.
- **Action on Fail:** Add the smallest seam that solves the demonstrated problem. Use dependency injection, a narrower interface, or a wrapper only when the code has a real need for that seam; do not add abstraction layers by default.

### Gate 4: Pragmatic Quality (KISS / DRY / YAGNI)

- **Pass:** The solution is as simple as the requirement allows, with clear names and behavior. Small duplication is acceptable when the duplicated cases change independently or a shared abstraction would add more complexity.
- **Fail:** Repeated logic has the same meaning and change boundary, so maintaining it separately creates a concrete inconsistency risk; or an abstraction adds complexity without a current use.
- **Action on Fail:** Consolidate only when the shared rule is real and the resulting abstraction is clearer. Otherwise leave the code separate. Do not treat zero duplication as a goal.

### Finding quality

Before recommending a structural change, state the affected code, the concrete scenario or maintenance problem, and why a smaller local change is insufficient. Include the smallest safe fix and its consequence if left unchanged. Do not block a review for line-count preferences, pattern choices, or hypothetical reuse.

---

## Phase 2 — Critical Patterns

### Dependency Impact Scan

Before any signature change, identify every file that imports the target.  
If a signature changes, all dependent files **must** be updated in the same change. Never leave broken imports or type errors downstream.

### Structural Integrity

- Check for unreachable code and dead exports
- Check for circular dependencies
- Verify files are in the correct location per the project's structure (reference `AGENTS.md`)
- Run the project's lint and type-check commands. Block completion if they fail.

---

## Reporting

After completing both phases, report findings in this format:

```
## Code Review Results

### ❌ Errors (must fix)
- <specific issue, file:line, remediation>

### ⚠️ Warnings (should fix)
- <specific issue, file:line, remediation>

### ✅ Passed
- <what was verified>

### Recommendation
Approve / Request Changes — <one-line rationale>
```

- If errors exist: report them and ask "Should I apply the fixes?"
- After applying fixes: re-run the relevant phase to verify resolution
- If the codebase has no `AGENTS.md`, suggest running `/init-project` first for better stack-aware review
