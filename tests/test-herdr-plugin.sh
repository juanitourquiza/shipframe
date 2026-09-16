#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN="$ROOT/herdr-plugin"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

python3 - <<PY
import pathlib, tomllib
manifest = tomllib.loads(pathlib.Path("$PLUGIN/herdr-plugin.toml").read_text())
assert manifest["id"] == "shipframe.workflow"
assert {a["id"] for a in manifest["actions"]} == {"start-workflow", "open-checklist"}
assert {p["id"] for p in manifest["panes"]} == {"workflow", "checklist"}
PY

for script in "$PLUGIN"/bin/*.sh; do
  sh -n "$script"
done

fake_herdr="$TMP/herdr"
cat > "$fake_herdr" <<'SH'
#!/usr/bin/env sh
printf '%s\n' "$*" >> "$HERDR_FAKE_LOG"
SH
chmod +x "$fake_herdr"

run_action() {
  local home="$1" state="$2" cwd="$3" action="$4"
  PATH="/usr/bin:/bin" \
  HOME="$home" \
  HERDR_BIN_PATH="$fake_herdr" \
  HERDR_FAKE_LOG="$state/herdr.log" \
  HERDR_PLUGIN_STATE_DIR="$state" \
  HERDR_PLUGIN_ID="shipframe.workflow" \
  HERDR_PLUGIN_CONTEXT_JSON="{\"workspace\":{\"cwd\":\"$cwd\"}}" \
  "$PLUGIN/bin/$action"
}

# Missing ShipFrame install fails clearly but still opens the explanatory pane.
plain_repo="$TMP/plain-repo"
mkdir -p "$plain_repo"
git -C "$plain_repo" init -q
mkdir -p "$TMP/home-missing" "$TMP/state-missing"
run_action "$TMP/home-missing" "$TMP/state-missing" "$plain_repo" start-workflow.sh
grep "STATUS='shipframe_missing'" "$TMP/state-missing/latest.env" >/dev/null
grep "plugin pane open --plugin shipframe.workflow --entrypoint workflow" "$TMP/state-missing/herdr.log" >/dev/null

# ShipFrame source checkout runs only the read-only repo doctor before opening the pane.
source_repo="$TMP/source-repo"
mkdir -p "$source_repo/skills"
git -C "$source_repo" init -q
cat > "$source_repo/AGENTS.md" <<'MD'
# fixture
MD
cat > "$source_repo/install.sh" <<'SH'
#!/usr/bin/env sh
[ "$1" = "--doctor" ] && [ "$2" = "--repo-only" ]
printf 'doctor ok\n'
SH
chmod +x "$source_repo/install.sh"
mkdir -p "$TMP/home-source" "$TMP/state-source"
run_action "$TMP/home-source" "$TMP/state-source" "$source_repo" start-workflow.sh
grep "DOCTOR_STATUS='passed'" "$TMP/state-source/latest.env" >/dev/null
grep "doctor ok" "$TMP/state-source/doctor.log" >/dev/null

# Checklist action opens the checklist pane and does not run doctor.
mkdir -p "$TMP/state-checklist"
run_action "$TMP/home-source" "$TMP/state-checklist" "$plain_repo" open-checklist.sh
grep "MODE='checklist'" "$TMP/state-checklist/latest.env" >/dev/null
grep "plugin pane open --plugin shipframe.workflow --entrypoint checklist" "$TMP/state-checklist/herdr.log" >/dev/null

# Pane renderers can read saved state without requiring Herdr.
timeout_cmd=(timeout 2)
if ! command -v timeout >/dev/null 2>&1; then
  timeout_cmd=(python3 -c 'import subprocess, sys; sys.exit(subprocess.run(sys.argv[1:], timeout=2).returncode)' )
fi
printf '\004' | HERDR_PLUGIN_STATE_DIR="$TMP/state-source" "${timeout_cmd[@]}" "$PLUGIN/bin/workflow-pane.sh" | grep "ShipFrame workflow for Herdr" >/dev/null
printf '\004' | HERDR_PLUGIN_STATE_DIR="$TMP/state-checklist" "${timeout_cmd[@]}" "$PLUGIN/bin/checklist-pane.sh" | grep "ShipFrame checklist" >/dev/null

printf 'Herdr plugin tests passed\n'
