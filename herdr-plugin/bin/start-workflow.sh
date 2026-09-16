#!/bin/sh
set -eu
# shellcheck source=herdr-plugin/bin/common.sh
. "$(dirname "$0")/common.sh"

cwd="$(context_cwd)"
repo=""
status="ready"
doctor_command=""
shipframe_check_label="ShipFrame install"
shipframe_check_status="skipped"
doctor_log="$(state_dir)/doctor.log"

if repo="$(find_repo "$cwd" 2>/dev/null)"; then
  :
else
  status="no_repo"
fi

if [ "$status" = "ready" ] && repo_has_shipframe_source "$repo"; then
  doctor_command="./install.sh --doctor --repo-only"
  shipframe_check_label="ShipFrame source doctor"
  (
    cd "$repo"
    ./install.sh --doctor --repo-only
  ) >"$doctor_log" 2>&1 && shipframe_check_status="passed" || shipframe_check_status="failed"
elif [ "$status" = "ready" ] && shipframe_installed; then
  shipframe_check_label="ShipFrame install"
  shipframe_check_status="detected"
elif [ "$status" = "ready" ]; then
  status="shipframe_missing"
fi

write_state \
  "MODE=workflow" \
  "CWD=$cwd" \
  "REPO=$repo" \
  "STATUS=$status" \
  "DOCTOR_COMMAND=$doctor_command" \
  "SHIPFRAME_CHECK_LABEL=$shipframe_check_label" \
  "SHIPFRAME_CHECK_STATUS=$shipframe_check_status" \
  "DOCTOR_LOG=$doctor_log"

if ! open_plugin_pane workflow; then
  printf 'ShipFrame Herdr plugin prepared workflow state but could not open pane.\n' >&2
  printf 'Status: %s\nRepo: %s\n' "$status" "${repo:-none}" >&2
  exit 1
fi
