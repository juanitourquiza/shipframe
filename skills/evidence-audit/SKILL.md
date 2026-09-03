---
name: evidence-audit
description: Audit reports, handoffs, or replies and classify delivery claims by evidence strength.
argument-hint: '[--text "<report>"] [--file <path>]'
allowed-tools: Read Grep Glob Bash
effort: medium
---

# Evidence Audit

Audit a response, handoff, PR note, release report, or teammate update for evidence-backed delivery claims.

## Goal

Make ShipFrame reports trustworthy by separating what was actually proven from what was inferred, partially checked, or not checked.

## Inputs

Accept either:

- pasted text from the user;
- a file path to a report, handoff, PR description, changelog, or release notes;
- the current draft response/report in the conversation.

If no text or file is provided, ask for the report to audit.

## Claim classes

For each meaningful claim, assign exactly one class:

| Class | Meaning |
|---|---|
| `Verified` | Direct evidence proves the claim for the stated scope/environment. |
| `Partially verified` | Evidence supports part of the claim, but scope, environment, version, user path, provider, or timing is incomplete. |
| `Unverified` | No direct evidence is provided, or the evidence only shows intent/configuration rather than outcome. |

## Risky claim triggers

Always inspect claims containing words or equivalents like:

- shipped, released, deployed, published, live, in production;
- merged, approved, closed, resolved;
- tested, verified, smoke-tested, validated, passing;
- works, fixed, complete, done;
- available, installed, submitted, accepted, official.

Treat these as risky until the report names concrete evidence.

## Evidence rules

Prefer direct evidence over inferred evidence:

1. Exact production/staging URL response, timestamp, and route checked.
2. Version endpoint, visible version, tag, release object, package version, or deployed commit SHA.
3. CI/build/test job result tied to the exact branch or commit.
4. Local command output with command, environment, and pass/fail result.
5. Screenshots/log snippets as supporting evidence.

Configuration, code presence, an opened PR, or an intended deploy pipeline is not enough to say a behavior is live.

## Generic core boundary

Keep this skill project-agnostic. Do not hardcode client/project-specific gates, tenants, paid providers, private URLs, or product rules here. Load those from `project-profile`, `.shipframe/profile.md`, or repo documentation when available.

## Audit procedure

1. Identify every delivery, verification, release, or availability claim.
2. Extract the evidence quoted or referenced for each claim.
3. Compare the claim scope to the evidence scope:
   - local vs CI vs staging vs production;
   - public route vs authenticated/private behavior;
   - simulated provider vs paid/live provider;
   - branch/PR vs merged main vs deployed commit;
   - tag created vs release object published;
   - config present vs runtime behavior observed.
4. Mark overclaims where wording is stronger than evidence.
5. Rewrite risky wording into an evidence-honest version.
6. List missing checks needed to upgrade `Partially verified` or `Unverified` claims.

## Output format

```markdown
## Evidence Audit

### Verdict
<Trustworthy | Needs wording changes | Not enough evidence>

### Claim table
| Claim | Classification | Evidence found | Gap / risk | Safer wording |
|---|---|---|---|---|
| <claim> | <Verified/Partially verified/Unverified> | <evidence> | <gap> | <rewrite> |

### High-risk overclaims
- <claim and why it is risky, or "None">

### Missing evidence to collect
- <specific command, URL smoke, CI/deploy proof, or "None">

### Recommended final wording
<short evidence-honest summary the user can paste>
```

## Completion rule

Do not approve a report that says “done”, “deployed”, “released”, “published”, or “works in production” unless the report contains exact-environment evidence for that claim.
