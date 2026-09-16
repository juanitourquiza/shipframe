#!/bin/sh
set -eu

plugin_id() {
  printf '%s\n' "${HERDR_PLUGIN_ID:-shipframe.workflow}"
}

herdr_bin() {
  printf '%s\n' "${HERDR_BIN_PATH:-herdr}"
}

state_dir() {
  dir="${HERDR_PLUGIN_STATE_DIR:-${TMPDIR:-/tmp}/shipframe-herdr-plugin-state}"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

context_cwd() {
  python3 -c '
import json, os, sys
raw = os.environ.get("HERDR_PLUGIN_CONTEXT_JSON") or "{}"
try:
    data = json.loads(raw)
except Exception:
    data = {}
keys = [("cwd",), ("workspace", "cwd"), ("workspace", "path"), ("worktree", "path"), ("pane", "cwd"), ("focused_pane", "cwd")]
for path in keys:
    cur = data
    for key in path:
        if isinstance(cur, dict) and key in cur:
            cur = cur[key]
        else:
            cur = None
            break
    if isinstance(cur, str) and cur:
        print(cur)
        sys.exit(0)
print(os.environ.get("PWD", ""))
' 2>/dev/null || printf '%s\n' "${PWD:-}"
}

find_repo() {
  start="${1:-$(pwd)}"
  if command -v git >/dev/null 2>&1 && git -C "$start" rev-parse --show-toplevel >/dev/null 2>&1; then
    git -C "$start" rev-parse --show-toplevel
    return 0
  fi
  return 1
}

shipframe_skill_set_installed() {
  root="$1"
  [ -d "$root/implement-task" ] && \
  [ -d "$root/code-review" ] && \
  [ -d "$root/project-memory-refresh" ] && \
  [ -d "$root/deploy-evidence" ]
}

shipframe_installed() {
  shipframe_skill_set_installed "$HOME/.agents/skills" || \
  shipframe_skill_set_installed "$HOME/.codex/skills" || \
  shipframe_skill_set_installed "$HOME/.config/opencode/skills" || \
  command -v shipframe >/dev/null 2>&1
}

repo_has_shipframe_source() {
  repo="$1"
  [ -x "$repo/install.sh" ] && [ -d "$repo/skills" ] && [ -f "$repo/AGENTS.md" ]
}

write_state() {
  file="$(state_dir)/latest.env"
  : > "$file"
  for pair in "$@"; do
    key=${pair%%=*}
    value=${pair#*=}
    safe=$(printf '%s' "$value" | sed "s/'/'\\''/g")
    printf "%s='%s'\n" "$key" "$safe" >> "$file"
  done
}

read_state() {
  file="$(state_dir)/latest.env"
  if [ -f "$file" ]; then
    # shellcheck disable=SC1090
    . "$file"
  fi
}

open_plugin_pane() {
  entrypoint="$1"
  herdr="$(herdr_bin)"
  "$herdr" plugin pane open --plugin "$(plugin_id)" --entrypoint "$entrypoint"
}
