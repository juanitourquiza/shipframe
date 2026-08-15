---
name: client-copy-review
description: Reviews product/client-facing copy for clarity, approval constraints, bilingual consistency, and implementation-safe wording.
allowed-tools: Read Glob Grep Bash
argument-hint: '[--language <en|es|both>]'
effort: medium
---

# Client Copy Review

Use before changing visible product text, emails, landing pages, app UI labels, or client-approved copy.

## Rules

- Preserve explicitly approved copy verbatim unless the user asks to revise it.
- If the project is bilingual or localized, update every required locale together.
- Separate factual claims, marketing claims, and implementation status.
- Do not present planned, demo, experimental, or partially shipped work as released.
- Prefer paste-ready final wording.

## Output

```markdown
## Client Copy Review

**Files/areas checked:** <paths>
**Languages:** <languages>

### Recommended copy
<final wording>

### Consistency checks
- ✅/⚠️ <i18n, tone, legal/safety, approval status>

### Implementation notes
- <where to update>
```
