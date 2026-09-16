#!/bin/sh
set -eu
# shellcheck source=herdr-plugin/bin/common.sh
. "$(dirname "$0")/common.sh"
read_state
clear 2>/dev/null || true
cat <<MSG
ShipFrame checklist
===================

Repo: ${REPO:-not detected}

[ ] CONTEXT: Read WIKI.md/wiki index/AGENTS, inspect git state, search docs.
[ ] DEFINE: Clarify requirements or use the existing ticket/plan.
[ ] PLAN: List files to create/modify/delete, commands, verification, out of scope.
[ ] BUILD: Create a branch, make the narrowest safe change.
[ ] VERIFY: Run targeted checks and record exact commands + results.
[ ] REVIEW: Run ShipFrame code-review. Fix blocking findings.
[ ] EVIDENCE: Separate local tests, CI, deploy, smoke, and provider/device proof.
[ ] PR/MR: Open Draft unless explicitly told otherwise.

Never from this plugin:
- merge branches
- deploy to production
- approve reviews
- edit global config without explicit confirmation

Press Ctrl-D or close this pane when done.
MSG
cat >/dev/null || true
