---
name: deploy-evidence
description: Collects concrete proof that a deploy or release actually reached the intended environment. Use before saying a release, publish, or deploy is done.
allowed-tools: Read Glob Grep Bash
argument-hint: '[--environment <name>] [--url <url>]'
effort: medium
---

# Deploy Evidence

Verify that a release reached the intended environment with concrete evidence.

## Evidence hierarchy

Prefer direct proof over inferred proof:

1. Production/staging URL smoke result with timestamp.
2. Version endpoint, visible version, release tag, or commit SHA in deployed artifact.
3. CI/deployment job result for the exact commit.
4. Application-specific smoke checks: key routes, API endpoints, queues, webhooks, auth flows.
5. Logs only as supporting evidence, not sole proof.

## Output

```markdown
## Deploy Evidence

**Environment:** <environment>
**Commit/tag/version checked:** <value>
**Timestamp:** <local time>

### Evidence collected
- ✅ <proof>

### Smoke checks
- ✅/⚠️/❌ <check>

### Gaps
- <missing proof or "None">

### Verdict
<Complete only if exact-environment evidence exists; otherwise Not complete>
```
