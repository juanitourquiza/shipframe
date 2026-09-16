#!/bin/sh
set -eu
# shellcheck source=herdr-plugin/bin/common.sh
. "$(dirname "$0")/common.sh"

cwd="$(context_cwd)"
repo=""
if repo="$(find_repo "$cwd" 2>/dev/null)"; then :; fi
write_state "MODE=checklist" "CWD=$cwd" "REPO=$repo" "STATUS=checklist" "SHIPFRAME_CHECK_LABEL=ShipFrame install" "SHIPFRAME_CHECK_STATUS=skipped" "DOCTOR_COMMAND=" "DOCTOR_LOG="
open_plugin_pane checklist
