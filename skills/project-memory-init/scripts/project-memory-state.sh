#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: project-memory-state.sh <status|decline|enable|reset> [repo-path]" >&2
}

action="${1:-}"
repo_path="${2:-$PWD}"
if [ "$#" -gt 2 ]; then usage; exit 2; fi
case "$action" in status|decline|enable|reset) ;; *) usage; exit 2 ;; esac

repo_root="$(git -C "$repo_path" rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Error: not inside a Git repository: $repo_path" >&2
  exit 1
}
key="shipframe.memory.setup"

case "$action" in
  status)
    value="$(git -C "$repo_root" config --local --get "$key" 2>/dev/null || true)"
    case "$value" in
      "") echo "unconfigured" ;;
      declined|enabled) echo "$value" ;;
      *) echo "Error: invalid local project-memory state '$value'; inspect .git/config." >&2; exit 2 ;;
    esac
    ;;
  decline)
    git -C "$repo_root" config --local --replace-all "$key" declined
    ;;
  enable)
    git -C "$repo_root" config --local --replace-all "$key" enabled
    ;;
  reset)
    git -C "$repo_root" config --local --unset-all "$key" 2>/dev/null || true
    ;;
esac
