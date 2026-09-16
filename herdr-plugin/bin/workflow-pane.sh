#!/bin/sh
set -eu
# shellcheck source=herdr-plugin/bin/common.sh
. "$(dirname "$0")/common.sh"
read_state

clear 2>/dev/null || true
cat <<'BANNER'
ShipFrame workflow for Herdr
===========================

Herdr keeps the workspace, panes, and agent sessions organized.
ShipFrame keeps the delivery process explicit: context, plan, implementation,
verification, review, evidence, and PR/MR.
BANNER

printf '\nRepository: %s\n' "${REPO:-not detected}"
printf 'Status: %s\n' "${STATUS:-unknown}"
printf '%s: %s\n' "${SHIPFRAME_CHECK_LABEL:-ShipFrame install}" "${SHIPFRAME_CHECK_STATUS:-skipped}"
if [ "${DOCTOR_COMMAND:-}" ]; then
  printf 'Check command: %s\n' "$DOCTOR_COMMAND"
fi

case "${STATUS:-}" in
  no_repo)
    cat <<'MSG'

No git repository was detected from the current Herdr context.
Open Herdr inside a project repository, then run this action again.
MSG
    ;;
  shipframe_missing)
    cat <<'MSG'

ShipFrame was not detected in the usual local skill locations and no shipframe
command was found. Install ShipFrame first, then run this action again.

Expected non-destructive checks:
- ShipFrame skill set in ~/.agents/skills
- ShipFrame skill set in ~/.codex/skills
- ShipFrame skill set in ~/.config/opencode/skills
- shipframe on PATH, if your install provides a CLI
MSG
    ;;
  *)
    if [ "${SHIPFRAME_CHECK_STATUS:-}" = "failed" ]; then
      cat <<MSG

ShipFrame repo doctor failed. Review the read-only log:
${DOCTOR_LOG:-}
MSG
    elif [ "${SHIPFRAME_CHECK_STATUS:-}" = "passed" ]; then
      cat <<MSG

ShipFrame source doctor passed. Log:
${DOCTOR_LOG:-}
MSG
    fi
    cat <<'MSG'

Recommended next pane prompt
----------------------------
Paste this into Codex, Claude Code, or OpenCode in this repo:

Use ShipFrame for this task. Refresh project context, classify the intent, plan
at file level, implement only after the plan is clear, run targeted verification,
perform code review, and create a Draft PR/MR. Do not merge or deploy unless I
explicitly authorize it. Report evidence separately from assumptions.

Safe workflow checklist
-----------------------
1. Context refresh: WIKI/AGENTS, git state, docs, prior decisions.
2. Plan: scope, files, commands, acceptance criteria, out of scope.
3. Implement: narrow branch, minimal changes, preserve tool compatibility.
4. Verify: lint/type/test or explicit proof commands with exit-0 evidence.
5. Review: code review and evidence audit for unsupported claims.
6. Ship: Draft PR/MR. Deploy/merge only with explicit authorization.

Danger boundary
---------------
This plugin does not run merge, deploy, destructive git, or global config changes.
MSG
    ;;
esac

printf '\nPress Ctrl-D or close this pane when done.\n'
cat >/dev/null || true
