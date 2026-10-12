---
name: code-review
description: Review changed code before commit or PR with strict quality, structural, security, performance, and test coverage gates.
argument-hint: '[--base-branch <branch>]'
allowed-tools: Read Grep Glob Bash
effort: high
---

# code-review

Two-phase code review skill. Phase 1 catches correctness and safety issues. Phase 2 holds the change to a high bar for clarity, cohesion, testability, and maintainability. SOLID, KISS, DRY, and YAGNI are complementary lenses for reaching that bar, not substitutes for judgment.

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
Treat the returned files as the review scope. Read those files and only additional callers, contracts, or tests needed to verify their changed behavior; do not broaden the review into unrelated code.

If the diff is empty, inform the user: "No changes detected between the current branch and `<BASE_BRANCH>`." and stop.

Review the changed code and its directly affected callers/contracts. Do not expand into unrelated pre-existing issues; report one only when this change exposes it, worsens it, or makes a narrowly scoped fix necessary. Apply the same scope rule in both phases.

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

- [ ] Relevant existing tests pass
- [ ] New or changed behavior has appropriate test coverage (unit or integration)
- [ ] There is observable evidence the change works (test output, screenshot, logs)


### 1.5 Security Checks

- [ ] No hardcoded secrets or credentials
- [ ] No sensitive data in logs or error messages
- [ ] Input validation prevents injection attacks
- [ ] Changed dependencies have no known relevant security or compatibility issue

### 1.6 Performance Checks

- [ ] No avoidable performance cost with a credible impact in the affected workload (for example, an N+1 query or repeated expensive call)
- [ ] Database queries, API calls, and computations are necessary for the changed behavior

**Phase 1 outcome:**
- Continue to Phase 2 after recording relevant findings and evidence.
- Apply the finding severity rules in **Reporting** consistently to both phases; a checklist concern is not automatically a blocking error.

---

## Phase 2 — Quality and Structural Review

Hold changed code to a high standard: it should be easy to understand, cohesive, straightforward to test, and no more complex than the requirement needs. Actively look for avoidable complexity, unclear control flow, misplaced responsibilities, fragile coupling, and duplication that can drift. Do not approve merely because tests pass or no functional bug is obvious.

Use SOLID, KISS, DRY, and YAGNI as complementary lenses, not quotas or automatic design prescriptions. A heuristic such as function length is a prompt to inspect: determine whether the code is harder to understand, verify, or change because of it. A material quality problem has a concrete consequence, such as branches that cannot be tested independently, duplicated business rules already diverging, hidden state transitions that obscure behavior, or a dependency that prevents a necessary test or safe change. If so, request a focused improvement and explain why. If not, do not demand a mechanical rewrite. Prefer the smallest change that reaches the quality bar; a refactor is warranted when it materially improves clarity, cohesion, testability, or change safety without adding greater complexity.

### Gate 1: Single Responsibility (SRP)

- **Pass:** Each unit has a coherent purpose, and its control flow makes the behavior easy to follow. Long functions and deep nesting must be examined for mixed responsibilities, hidden state transitions, or difficult-to-test branches.
- **Fail:** A unit combines responsibilities or control flow in a way that obscures behavior, prevents focused tests, or makes a likely change risky (for example, hidden I/O in a function presented as pure).
- **Action on Fail:** Propose a focused decomposition or simplification that measurably improves cohesion or comprehension. Do not count lines as the defect; show what the split clarifies or makes independently verifiable.

### Gate 2: Open/Closed + Liskov Substitution (OCP/LSP)

- **Pass:** Changes preserve caller contracts and handle variation through the clearest maintainable design. Extending an existing implementation is fine when that remains simpler and safer.
- **Fail:** A change violates an existing contract, or growing conditional logic for actual variants is already difficult to reason about, test, or extend safely.
- **Action on Fail:** Fix contract violations. Where real variation exists, recommend the smallest useful extension point (for example, composition or polymorphism) and explain why it reduces the current complexity; reject both speculative frameworks and brittle conditionals that are already costly.

### Gate 3: Interface Segregation + Dependency Inversion (ISP/DIP)

- **Pass:** Dependencies and interfaces keep responsibilities clear and required behavior testable without needless indirection. Concrete dependencies are acceptable only when they do not make the relevant code fragile or hard to verify.
- **Fail:** A dependency prevents a needed substitution or focused test, a broad interface burdens clients with unrelated behavior, or an external detail leaks across a boundary and makes change risky.
- **Action on Fail:** Add the smallest seam that restores testability or isolates the volatile boundary. Select dependency injection, a narrow interface, or a wrapper based on the actual coupling; avoid both needless abstractions and coupling that makes tests or changes brittle.

### Gate 4: Pragmatic Quality (KISS / DRY / YAGNI)

- **Pass:** The solution is the clearest maintainable design for the requirement: names reveal intent, logic has one source of truth where it represents one rule, and abstractions earn their complexity. Keep independent behavior separate when combining it would obscure the model.
- **Fail:** Accidental complexity makes the change harder to understand than necessary; the same rule is implemented in multiple places and can diverge; names hide intent; or indirection has no current value.
- **Action on Fail:** Simplify, clarify, or consolidate when doing so makes the code materially easier to reason about and maintain. Do not preserve avoidable complexity in the name of minimal diffs, and do not force zero duplication when the cases genuinely have different meanings or change for different reasons.

### Finding quality

Every finding must point to changed code or a directly affected contract and state the specific clarity, cohesion, testability, correctness, safety, or maintenance problem and its likely consequence if left unchanged. For a structural recommendation, explain why a smaller local fix would not meet the quality bar, propose the smallest effective improvement, and account for any complexity it adds. Do not report unrelated pre-existing problems unless this change exposes or worsens them. Do not block for line-count preferences, pattern choices, or hypothetical reuse alone; do block when avoidable complexity materially degrades the changed code even if current tests pass.

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

- **Errors (must fix / Request Changes):** A demonstrated correctness, security, data-integrity, compatibility, or high-impact reliability failure; or a material maintainability defect in changed code that makes likely changes unsafe or prevents adequate verification. State the evidence and consequence.
- **Warnings (should fix):** A concrete, lower-impact quality concern within scope. Warnings are not blockers by themselves; explain the benefit of addressing them.
- **Passed:** State what was actually verified. Do not imply a check ran when it did not.
- Do not turn personal style preferences, numeric heuristics, or speculative future needs into findings. Apply these severity rules to Phase 1 and Phase 2 alike; checklist location does not determine severity.

- If errors exist: report them and ask "Should I apply the fixes?"
- After applying fixes: re-run the relevant phase to verify resolution
- If the codebase has no `AGENTS.md`, suggest running `/init-project` first for better stack-aware review
