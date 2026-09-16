#!/bin/sh
set -eu
# shellcheck source=herdr-plugin/bin/common.sh
. "$(dirname "$0")/common.sh"

cwd="$(context_cwd)"
repo=""
status="ready"
doctor_command=""
doctor_status="skipped"
doctor_log="$(state_dir)/doctor.log"

if repo="$(find_repo "$cwd" 2>/dev/null)"; then
  :
else
  status="no_repo"
fi

if [ "$status" = "ready" ] && repo_has_shipframe_source "$repo"; then
  doctor_command="./install.sh --doctor --repo-only"
  (
    cd "$repo"
    ./install.sh --doctor --repo-only
  ) >"$doctor_log" 2>&1 && doctor_status="passed" || doctor_status="failed"
elif [ "$status" = "ready" ] && shipframe_installed; then
  doctor_status="installed"
elif [ "$status" = "ready" ]; then
  status="shipframe_missing"
fi

write_state \
  "MODE=workflow" \
  "CWD=$cwd" \
  "REPO=$repo" \
  "STATUS=$status" \
  "DOCTOR_COMMAND=$doctor_command" \
  "DOCTOR_STATUS=$doctor_status" \
  "DOCTOR_LOG=$doctor_log"

if ! open_plugin_pane workflow; then
  printf 'ShipFrame Herdr plugin prepared workflow state but could not open pane.\n' >&2
  printf 'Status: %s\nRepo: %s\n' "$status" "${repo:-none}" >&2
  exit 1
fi
