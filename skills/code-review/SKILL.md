---
name: code-review
description: Two-phase code review. Phase 1 runs fast pre-commit checks for spec compliance, type safety, and stack alignment. Phase 2 audits SOLID principles and structural integrity. Use before committing or opening a PR.
argument-hint: '[--base-branch <branch>]'
allowed-tools: Read Grep Glob Bash
effort: high
---

# code-review

Two-phase code review skill. Phase 1 catches surface-level issues fast. Phase 2 audits structural correctness using SOLID as the primary framework and KISS/DRY/YAGNI for implementation quality.

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

## Phase 2 — Deep SOLID & Structural Audit

### Gate 1: Single Responsibility (SRP)

- **Pass:** Each function/class has one reason to change. Logic is encapsulated by domain. Functions are under ~20 lines.
- **Fail:** "God objects" that mix UI, state, and I/O logic. Deep nesting (>2 levels). Side effects inside functions advertised as pure.
- **Action on Fail:** Trigger decomposition — split logic into atomic, single-purpose units. Each extracted piece should be testable in isolation.

### Gate 2: Open/Closed + Liskov Substitution (OCP/LSP)

- **Pass:** New behavior is added by extending, not by modifying existing code. Subtypes are drop-in replacements for their parents without breaking contracts.
- **Fail:** Large `if/else` or `switch` chains that must grow for each new type. Subclass methods throwing "Not Implemented".
- **Action on Fail:** Refactor using the Strategy pattern or polymorphism. Close the current abstraction and extend via composition.

### Gate 3: Interface Segregation + Dependency Inversion (ISP/DIP)

- **Pass:** Interfaces are narrow — clients only depend on what they use. High-level modules depend on abstractions, not concrete implementations.
- **Fail:** "Fat" interfaces where implementors are forced to stub unused methods. Hardcoded `new SpecificClass()` inside constructors. Tight coupling to third-party SDKs in business logic.
- **Action on Fail:** Introduce dependency injection. Split fat interfaces into focused contracts. Wrap third-party dependencies behind an abstraction layer owned by your code.

### Gate 4: Pragmatic Quality (KISS / DRY / YAGNI)

- **Pass:** Zero duplicated logic. Simplest solution that satisfies the requirement. Intent-revealing names (`isExpired` vs `flag`). Related code is colocated.
- **Fail:** Over-engineering for hypothetical future requirements. Magic numbers. Single-use abstractions with more complexity than the code they replaced. Abbreviated names (`ptr`, `tmp`, `idx`).
- **Action on Fail:** Inline over-engineered abstractions. Replace magic numbers with named constants. Choose duplication over a premature abstraction when the abstraction adds net complexity.

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
