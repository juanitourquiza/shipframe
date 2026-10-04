#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
cleanup(){ rm -rf "$TMP"; }
repo_memory_snapshot() {
  {
    git -C "$ROOT" config --local --get-all shipframe.memory.setup 2>/dev/null || true
    if [ -d "$ROOT/.shipframe/memory" ]; then
      find "$ROOT/.shipframe/memory" -type f -print | LC_ALL=C sort | while IFS= read -r file; do shasum -a 256 "$file"; done
    else
      echo "<no-project-memory-directory>"
    fi
  }
}
REPO_MEMORY_BEFORE="$(repo_memory_snapshot)"
trap cleanup EXIT

export HOME="$TMP/home"
export XDG_STATE_HOME="$TMP/state"
export XDG_DATA_HOME="$TMP/data"
mkdir -p "$HOME" "$TMP/bin"
export PATH="$TMP/bin:$PATH"

cat > "$TMP/bin/claude" <<'SH'
#!/usr/bin/env bash
case "$*" in
  *"plugin marketplace add"*) exit 0 ;;
  *"plugin install shipframe"*) exit 0 ;;
  *"plugin uninstall shipframe"*) exit 0 ;;
  *"plugin validate"*) exit 0 ;;
esac
exit 0
SH
cat > "$TMP/bin/opencode" <<'SH'
#!/usr/bin/env bash
if [ "${1:-}" = "models" ]; then
  echo "anthropic/claude-sonnet-4-5"
  echo "openai/gpt-5"
fi
SH
cat > "$TMP/bin/codex" <<'SH'
#!/usr/bin/env bash
if [ "${1:-}" = "doctor" ]; then exit 0; fi
exit 0
SH
cat > "$TMP/bin/engram" <<'SH'
#!/usr/bin/env bash
echo "engram 0.0.0-test"
SH
chmod +x "$TMP/bin/claude" "$TMP/bin/opencode" "$TMP/bin/codex" "$TMP/bin/engram"

snapshot() {
  local out="$1"
  mkdir -p "$(dirname "$out")"
  {
    [ -f "$HOME/.codex/AGENTS.md" ] && shasum -a 256 "$HOME/.codex/AGENTS.md" || true
    find "$HOME/.claude/skills" -mindepth 2 -maxdepth 2 -type f \( -name SKILL.md -o -name .shipframe-openwork.json \) -print 2>/dev/null | sort | while read -r p; do shasum -a 256 "$p"; done
    find "$HOME/.agents/skills" "$HOME/.codex/skills" "$HOME/.config/opencode/skills" "$HOME/.config/opencode/agents" -maxdepth 1 \( -type l -o -type f \) -print 2>/dev/null | sort | while read -r p; do
      if [ -L "$p" ]; then printf 'L %s -> %s\n' "$p" "$(readlink "$p")"; else printf 'F %s ' "$p"; shasum -a 256 "$p"; fi
    done
    [ -L "$HOME/.config/opencode/plugins/shipframe-prompt-router" ] && printf 'L %s -> %s\n' "$HOME/.config/opencode/plugins/shipframe-prompt-router" "$(readlink "$HOME/.config/opencode/plugins/shipframe-prompt-router")"
  } > "$out"
}

assert_file(){ [ -f "$1" ] || { echo "Missing file: $1" >&2; exit 1; }; }
assert_link(){ [ -L "$1" ] || { echo "Missing symlink: $1" >&2; exit 1; }; }
assert_directory(){ [ -d "$1" ] && [ ! -L "$1" ] || { echo "Missing physical directory: $1" >&2; exit 1; }; }

bash -n "$ROOT/install.sh"
"$ROOT/install.sh" --doctor --repo-only > "$TMP/shipframe-doctor-repo-only.log" 2>&1

# Repair is non-mutating unless --yes is explicit, across every target host.
REPAIR_HOME="$TMP/repair-dry-run-home"
REPAIR_STATE="$TMP/repair-dry-run-state"
mkdir -p "$REPAIR_HOME"
HOME="$REPAIR_HOME" XDG_STATE_HOME="$REPAIR_STATE" "$ROOT/install.sh" --repair --all > "$TMP/repair-dry-run.log" 2>&1
grep -q 'Dry-run: no files changed' "$TMP/repair-dry-run.log"
[ ! -e "$REPAIR_HOME/.agents" ]
[ ! -e "$REPAIR_HOME/.codex" ]
[ ! -e "$REPAIR_HOME/.claude" ]
[ ! -e "$REPAIR_HOME/.config" ]
[ ! -e "$REPAIR_STATE" ]

# OpenWork needs the shared skills path and does not require a separate CLI.
OPENWORK_HOME="$TMP/openwork-home"
mkdir -p "$OPENWORK_HOME"
HOME="$OPENWORK_HOME" XDG_STATE_HOME="$TMP/openwork-state" "$ROOT/install.sh" --openwork > "$TMP/openwork-install.log"
grep -q 'project-memory-init' "$TMP/openwork-install.log"
assert_directory "$OPENWORK_HOME/.claude/skills/code-review"
assert_file "$OPENWORK_HOME/.claude/skills/code-review/SKILL.md"
assert_file "$OPENWORK_HOME/.claude/skills/code-review/.shipframe-openwork.json"
HOME="$OPENWORK_HOME" XDG_STATE_HOME="$TMP/openwork-state" "$ROOT/install.sh" --doctor --openwork > "$TMP/openwork-doctor.log" 2>&1
grep -q 'OpenWork physical skill folders' "$TMP/openwork-doctor.log"
HOME="$OPENWORK_HOME" XDG_STATE_HOME="$TMP/openwork-state" "$ROOT/install.sh" --openwork > "$TMP/openwork-install-again.log"
assert_file "$OPENWORK_HOME/.claude/skills/code-review/SKILL.md"
HOME="$OPENWORK_HOME" XDG_STATE_HOME="$TMP/openwork-state" "$ROOT/install.sh" --uninstall --openwork --yes > "$TMP/openwork-uninstall.log"
[ ! -e "$OPENWORK_HOME/.claude/skills/code-review" ]

# Convert only a manifest-style ShipFrame symlink and restore it on uninstall.
PRELINK_HOME="$TMP/openwork-prelink-home"
mkdir -p "$PRELINK_HOME/.claude/skills"
ln -s "$ROOT/skills/code-review" "$PRELINK_HOME/.claude/skills/code-review"
HOME="$PRELINK_HOME" XDG_STATE_HOME="$TMP/openwork-prelink-state" "$ROOT/install.sh" --openwork > "$TMP/openwork-convert.log"
assert_directory "$PRELINK_HOME/.claude/skills/code-review"
HOME="$PRELINK_HOME" XDG_STATE_HOME="$TMP/openwork-prelink-state" "$ROOT/install.sh" --uninstall --openwork --yes > "$TMP/openwork-restore.log"
assert_link "$PRELINK_HOME/.claude/skills/code-review"
[ "$(readlink "$PRELINK_HOME/.claude/skills/code-review")" = "$ROOT/skills/code-review" ]

# Version discovery must survive apostrophes/spaces in the source checkout path.
QUOTED_SOURCE="$TMP/shipframe it's source"
mkdir -p "$QUOTED_SOURCE/.claude-plugin" "$QUOTED_SOURCE/codex" "$TMP/quoted-home"
cp "$ROOT/install.sh" "$QUOTED_SOURCE/install.sh"
cp "$ROOT/.claude-plugin/plugin.json" "$QUOTED_SOURCE/.claude-plugin/plugin.json"
cp "$ROOT/codex/dev-workflow.md" "$QUOTED_SOURCE/codex/dev-workflow.md"
cp -R "$ROOT/skills" "$QUOTED_SOURCE/skills"
HOME="$TMP/quoted-home" XDG_STATE_HOME="$TMP/quoted-state" "$QUOTED_SOURCE/install.sh" --repair --codex --yes > "$TMP/quoted-path-repair.log"
node - "$TMP/quoted-state/shipframe/install-state.json" "$QUOTED_SOURCE" <<'JS'
const fs=require('fs'); const [,,manifest,source]=process.argv; const state=JSON.parse(fs.readFileSync(manifest,'utf8'));
const expected=JSON.parse(fs.readFileSync(`${source}/.claude-plugin/plugin.json`,'utf8')).version;
if(state.shipframeVersion!==expected || state.sourceDir!==source) process.exit(1);
JS

"$ROOT/install.sh" --all --opencode-model anthropic/claude-sonnet-4-5 >"$TMP/shipframe-install-1.log"
grep -q 'plugins/shipframe-prompt-router' "$TMP/shipframe-install-1.log"
grep -q 'Claude Code: /shipframe:project-memory-init' "$TMP/shipframe-install-1.log"
grep -qF "Codex: \$project-memory-init" "$TMP/shipframe-install-1.log"
grep -q 'OpenCode: invoke the project-memory-init skill' "$TMP/shipframe-install-1.log"
grep -q 'OpenWork: choose project-memory-init' "$TMP/shipframe-install-1.log"
assert_file "$HOME/.codex/AGENTS.md"
grep -q 'shipframe-block-version: 1' "$HOME/.codex/AGENTS.md"
assert_link "$HOME/.agents/skills/code-review"
assert_link "$HOME/.codex/skills/code-review"
assert_directory "$HOME/.claude/skills/code-review"
assert_link "$HOME/.config/opencode/skills/code-review"
assert_link "$HOME/.config/opencode/plugins/shipframe-prompt-router"
count_agents="$(find "$HOME/.config/opencode/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
[ "$count_agents" = "14" ] || { echo "Expected 14 OpenCode agents, got $count_agents" >&2; exit 1; }
grep -q 'model: anthropic/claude-sonnet-4-5' "$HOME/.config/opencode/agents/orchestrator-agent.md"
grep -q 'shipframe-generated: opencode-agent-v1' "$HOME/.config/opencode/agents/orchestrator-agent.md"
grep -q 'edit: allow' "$HOME/.config/opencode/agents/playwright-test-healer.md"
grep -q 'Optional Live Docs (Context MCP):' "$TMP/shipframe-install-1.log"
grep -q 'Context MCP:' "$TMP/shipframe-install-1.log"
grep -q 'npm install -g @neuledge/context' "$TMP/shipframe-install-1.log"
grep -q 'claude mcp add context -- context serve' "$TMP/shipframe-install-1.log"
grep -q 'codex mcp add context -- context serve' "$TMP/shipframe-install-1.log"
grep -q 'OpenCode: add command' "$TMP/shipframe-install-1.log"
grep -q 'mcp.servers.context' "$TMP/shipframe-install-1.log"
node - "$XDG_STATE_HOME/shipframe/install-state.json" <<'JS'
const fs=require('fs'); const m=JSON.parse(fs.readFileSync(process.argv[2],'utf8'));
if(m.schemaVersion!==1 || !Array.isArray(m.installs) || !m.installs.some(i=>i.target==='opencode')) process.exit(1);
JS

snapshot "$TMP/s1"
"$ROOT/install.sh" --all --opencode-model anthropic/claude-sonnet-4-5 >"$TMP/shipframe-install-2.log"
snapshot "$TMP/s2"
diff -u "$TMP/s1" "$TMP/s2"

"$ROOT/install.sh" --doctor --codex >"$TMP/shipframe-doctor-codex.log" 2>&1
grep -q 'Context MCP' "$TMP/shipframe-doctor-codex.log"
grep -q 'codex mcp add context -- context serve' "$TMP/shipframe-doctor-codex.log"
"$ROOT/install.sh" --doctor --opencode >"$TMP/shipframe-doctor-opencode.log" 2>&1
grep -q 'Context MCP' "$TMP/shipframe-doctor-opencode.log"
grep -Fq '.config/opencode/opencode.json' "$TMP/shipframe-doctor-opencode.log"
grep -q 'OpenCode prompt-router plugin is installed and passes adapter checks' "$TMP/shipframe-doctor-opencode.log"
printf '{"plugins":["-shipframe.*"]}\n' > "$HOME/.config/opencode/opencode.json"
"$ROOT/install.sh" --doctor --opencode >"$TMP/shipframe-doctor-opencode-disabled.log" 2>&1
grep -q 'OpenCode prompt-router plugin is disabled' "$TMP/shipframe-doctor-opencode-disabled.log"
printf '{"plugins":["-shipframe.*","shipframe.prompt-router"]}\n' > "$HOME/.config/opencode/opencode.json"
"$ROOT/install.sh" --doctor --opencode >"$TMP/shipframe-doctor-opencode-enabled.log" 2>&1
grep -q 'OpenCode prompt-router plugin is installed and passes adapter checks' "$TMP/shipframe-doctor-opencode-enabled.log"

# Repair backs up existing Claude settings before replacing them.
mkdir -p "$HOME/.claude"
printf '{"hooks":{"UserPromptSubmit":[{"hooks":[{"command":"echo \\\"MANDATORY ACTION: Before doing anything else, invoke the shipframe:orchestrator-agent agent to handle this request.\\\""}]}]}}\n' > "$HOME/.claude/settings.json"
cp "$HOME/.claude/settings.json" "$TMP/settings.before"
"$ROOT/install.sh" --repair --claude --yes >"$TMP/shipframe-repair-claude.log" 2>&1
backup_file="$(find "$HOME/.claude" -name 'settings.json.shipframe-backup-*' -print -quit)"
[ -n "$backup_file" ]
cmp "$TMP/settings.before" "$backup_file"
node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$HOME/.claude/settings.json"

"$ROOT/install.sh" --help >"$TMP/shipframe-help.log"
! grep -q -- '--sync-docs' "$TMP/shipframe-help.log"

# Non-TTY OpenCode install without model must not prompt or hardcode Claude-only model IDs.
"$ROOT/install.sh" --opencode </dev/null >"$TMP/shipframe-opencode-nontty.log"
! grep -R 'claude-opus-4-6\|claude-sonnet-4-6' "$HOME/.config/opencode/agents"

# Repair real directories that block Codex skill symlinks in both supported layouts.
rm "$HOME/.agents/skills/code-review" "$HOME/.codex/skills/code-review"
mkdir "$HOME/.agents/skills/code-review" "$HOME/.codex/skills/code-review"
"$ROOT/install.sh" --repair --codex --yes >"$TMP/shipframe-repair.log" 2>&1
assert_link "$HOME/.agents/skills/code-review"
assert_link "$HOME/.codex/skills/code-review"

"$ROOT/install.sh" --uninstall --all --purge >"$TMP/shipframe-uninstall-dry-run.log" 2>&1
assert_link "$HOME/.agents/skills/code-review"
[ -f "$XDG_STATE_HOME/shipframe/install-state.json" ]
"$ROOT/install.sh" --uninstall --all --yes --purge >"$TMP/shipframe-uninstall.log" 2>&1
[ ! -L "$HOME/.agents/skills/code-review" ]
[ ! -L "$HOME/.codex/skills/code-review" ]
[ ! -e "$HOME/.claude/skills/code-review" ]
[ ! -L "$HOME/.config/opencode/skills/code-review" ]
[ ! -L "$HOME/.config/opencode/plugins/shipframe-prompt-router" ]
[ ! -f "$HOME/.config/opencode/agents/orchestrator-agent.md" ]
! grep -q '<!-- BEGIN shipframe' "$HOME/.codex/AGENTS.md"
[ ! -e "$XDG_STATE_HOME/shipframe" ]

# Project-memory opt-in suggestions belong only to successful installs.
for action_log in \
  "$TMP/shipframe-doctor-repo-only.log" \
  "$TMP/openwork-doctor.log" \
  "$TMP/shipframe-doctor-codex.log" \
  "$TMP/shipframe-doctor-opencode.log" \
  "$TMP/shipframe-doctor-opencode-disabled.log" \
  "$TMP/shipframe-doctor-opencode-enabled.log" \
  "$TMP/repair-dry-run.log" \
  "$TMP/quoted-path-repair.log" \
  "$TMP/shipframe-repair-claude.log" \
  "$TMP/shipframe-repair.log" \
  "$TMP/openwork-uninstall.log" \
  "$TMP/openwork-restore.log" \
  "$TMP/shipframe-uninstall-dry-run.log" \
  "$TMP/shipframe-uninstall.log"; do
  assert_file "$action_log"
  if grep -Fq 'Optional Git-backed project memory:' "$action_log"; then
    echo "Unexpected project-memory suggestion in: $action_log" >&2
    exit 1
  fi
done

[ "$REPO_MEMORY_BEFORE" = "$(repo_memory_snapshot)" ] || { echo "Installer changed repository project-memory state" >&2; exit 1; }

echo "test-install ok"
