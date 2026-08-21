# Claude Marketplace Submission Packet — ShipFrame v0.4.1

**Status:** Ready for submission  
**Owner:** Juan Urquiza  
**Prepared on:** 2026-08-21  
**Scope:** Manual submission packet for Claude Code community marketplace review.

This packet is intentionally conservative: avoid any public wording that presents ShipFrame as official, accepted, approved, or Anthropic verified. Update the status to **Submitted / pending review** only after the manual form submission is complete.

## Product details

| Field | Value |
| --- | --- |
| Name | ShipFrame |
| Public repo | https://github.com/juanitourquiza/shipframe |
| GitHub release | v0.4.1 — https://github.com/juanitourquiza/shipframe/releases/tag/v0.4.1 |
| Landing page | https://shipframe.hackeruna.com/ |
| Works with | Claude Code |
| License | MIT |
| Recommended status before form submit | Ready for submission |
| Recommended status after form submit | Submitted / pending review |

## Paste-ready submission copy

### Name

```text
ShipFrame
```

### Short description

```text
AI coding workflows for teams that plan, prove, and ship.
```

### Long description

```text
ShipFrame gives Claude Code reusable skills, agents, hooks, templates, project profiles, and release-evidence workflows for disciplined software delivery.
```

### Works with

```text
Claude Code
```

### Tags

```text
ai-coding, workflow, skills, agents, code-review, release, evidence
```

### Repository URL

```text
https://github.com/juanitourquiza/shipframe
```

### Release URL

```text
https://github.com/juanitourquiza/shipframe/releases/tag/v0.4.1
```

### Landing URL

```text
https://shipframe.hackeruna.com/
```

## Install commands to include when useful

ShipFrame can currently be tested as a GitHub-backed marketplace:

```text
/plugin marketplace add juanitourquiza/shipframe
/plugin install shipframe
```

After install, reload plugins if Claude Code prompts for it:

```text
/reload-plugins
```

## Submission checklist

- [x] Public repository is available: https://github.com/juanitourquiza/shipframe
- [x] Latest GitHub release is `v0.4.1`.
- [x] README and release metadata are updated for `v0.4.1`.
- [x] Landing page is available: https://shipframe.hackeruna.com/
- [x] `claude plugin validate .` passes locally before submission.
- [x] `bash -n install.sh` passes locally before submission.
- [x] `shellcheck install.sh` passes locally before submission.
- [x] `./install.sh --doctor --repo-only` passes locally before submission.
- [x] No public copy claims “official” before Anthropic acceptance.
- [x] No public copy claims “Anthropic verified” unless Anthropic explicitly grants that status.
- [ ] Manual form has been submitted by Juan.
- [ ] ClickUp has been updated from “submission packet ready” to “submitted / pending review” after manual submission.


## Validation evidence

Verified from the ShipFrame repository root on 2026-08-21:

| Check | Result |
| --- | --- |
| `claude plugin validate .` | Passed — `✔ Validation passed` |
| `bash -n install.sh` | Passed |
| `shellcheck install.sh` | Passed |
| `./install.sh --doctor --repo-only` | Passed — 12 ok, 0 warnings, 0 errors |
| Latest GitHub release | `v0.4.1` |
| Repo link | HTTP 200 |
| Release link | HTTP 200 |
| Landing link | HTTP 200 |

## Manual submission notes

According to the current Claude Code plugin documentation:

- Community marketplace submissions go through in-app forms on claude.ai or Console.
- The claude.ai form may require a Team or Enterprise organization with directory-management access.
- Individual authors can use the Console form.
- The review pipeline runs `claude plugin validate ./your-plugin` plus automated safety screening.
- Approved community plugins are pinned to a commit SHA in the `anthropics/claude-plugins-community` catalog; public catalog sync may be delayed.
- The submission form does **not** add a plugin to the official Anthropic marketplace.

Use the Console form if the claude.ai admin form is unavailable for the account:

```text
https://platform.claude.com/plugins/submit
```

## Validation commands

Run these from the ShipFrame repository root before submitting:

```bash
claude plugin validate .
bash -n install.sh
shellcheck install.sh
./install.sh --doctor --repo-only
```

Optional full installer regression gate:

```bash
./tests/test-install.sh
```

## Link verification commands

```bash
curl -I -L https://github.com/juanitourquiza/shipframe
curl -I -L https://github.com/juanitourquiza/shipframe/releases/tag/v0.4.1
curl -I -L https://shipframe.hackeruna.com/
```

## ClickUp updates

### First update — submission packet ready

Post this when this document is committed and validation has passed:

```text
ShipFrame Claude marketplace submission packet is ready for manual submission.

Status: Ready for submission
Repo: https://github.com/juanitourquiza/shipframe
Release: v0.4.1
Landing: https://shipframe.hackeruna.com/
Doc: docs/claude-marketplace-submission.md

Validation completed:
- claude plugin validate .
- bash -n install.sh
- shellcheck install.sh
- ./install.sh --doctor --repo-only

Next: Juan submits the form manually, then we update status to submitted / pending review.
```

### Second update — submitted / pending review

Post this only after Juan confirms the manual submission is complete:

```text
ShipFrame has been submitted for Claude community marketplace review.

Status: Submitted / pending review
Repo: https://github.com/juanitourquiza/shipframe
Release: v0.4.1
Landing: https://shipframe.hackeruna.com/

Public copy will avoid “official” and “Anthropic verified” wording unless Anthropic explicitly grants that status.
```

## Source links

- Claude Code plugin creation and submission docs: https://code.claude.com/docs/en/plugins
- Claude Code marketplace discovery docs: https://code.claude.com/docs/en/discover-plugins
- Claude Code marketplace validation docs: https://code.claude.com/docs/en/plugin-marketplaces
- Claude plugins directory: https://claude.com/plugins
