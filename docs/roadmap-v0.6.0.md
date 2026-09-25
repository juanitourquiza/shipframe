# ShipFrame roadmap closeout — v0.6.0

This roadmap groups the planned work into four release waves. **v0.6.0 is the intended closeout for this initiative; v1.0 is a separate future decision.** No version in this document is evidence of a tag, published artifact, Homebrew update, landing deployment, or release.

## Wave 1 — Reliability / v0.4.9

- Publish the OpenCode runtime-import fix only after release validation.
- Test type-only import and load/setup smoke with Bun when installed; repo-only doctor checks source without requiring host CLIs.
- Keep routing intent catalogs in parity and verify meaningful prompt-router signals.
- Validate installed/configured OpenCode state in environment doctor separately from repo-only checks.
- Gate: Ubuntu and macOS CI, including deliberate negative doctor regression.

## Wave 2 — Security and E2E / v0.5.0

- Add `security-review` and `e2e-verify`; require scoped evidence, explicit test data, and host/tool limits.
- Document that scans, local browser runs, and live-provider proof are distinct claims.

## Wave 3 — Maintenance and contracts / v0.5.x

- Add `dependency-upgrade` and `api-contract-review`.
- Supply optional starter packs for Next.js, NestJS, FastAPI, and Go.
- Include migration/deprecation guidance in release workflows, performance checks only when change-triggered, and framework-pack discovery in onboarding.

## Wave 4 — Production and memory / v0.6.0

- Add `incident-response` and `memory-curator`, a postmortem template, runbook starter, and observability/alerting profile prompts.
- Incident response checks authorized access to logs, metrics/traces, deployment history, and operational consoles first. Missing access is the first deliverable, not a reason to bypass controls.
- Keep any `ai-cost-review` experiment as a script prototype, not a catalog skill.

## Release evidence and non-goals

- No native Windows/PowerShell support or test matrix is planned; supported terminal environments provide Bash or Zsh.
- Core, Homebrew, and landing are independent release surfaces. Validate version content per surface before claiming publication; one surface never implies another.
- The work may be merged without being tagged, published, deployed, or distributed. Report each state separately.
