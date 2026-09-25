#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
cleanup(){ rm -rf "$TMP"; }
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
    find "$HOME/.agents/skills" "$HOME/.codex/skills" "$HOME/.config/opencode/skills" "$HOME/.config/opencode/agents" -maxdepth 1 \( -type l -o -type f \) -print 2>/dev/null | sort | while read -r p; do
      if [ -L "$p" ]; then printf 'L %s -> %s\n' "$p" "$(readlink "$p")"; else printf 'F %s ' "$p"; shasum -a 256 "$p"; fi
    done
    [ -L "$HOME/.config/opencode/plugins/shipframe-prompt-router" ] && printf 'L %s -> %s\n' "$HOME/.config/opencode/plugins/shipframe-prompt-router" "$(readlink "$HOME/.config/opencode/plugins/shipframe-prompt-router")"
  } > "$out"
}

assert_file(){ [ -f "$1" ] || { echo "Missing file: $1" >&2; exit 1; }; }
assert_link(){ [ -L "$1" ] || { echo "Missing symlink: $1" >&2; exit 1; }; }

bash -n "$ROOT/install.sh"
"$ROOT/install.sh" --doctor --repo-only

"$ROOT/install.sh" --all --opencode-model anthropic/claude-sonnet-4-5 >/tmp/shipframe-install-1.log
grep -q 'plugins/shipframe-prompt-router' /tmp/shipframe-install-1.log
assert_file "$HOME/.codex/AGENTS.md"
grep -q 'shipframe-block-version: 1' "$HOME/.codex/AGENTS.md"
assert_link "$HOME/.agents/skills/code-review"
assert_link "$HOME/.codex/skills/code-review"
assert_link "$HOME/.config/opencode/skills/code-review"
assert_link "$HOME/.config/opencode/plugins/shipframe-prompt-router"
count_agents="$(find "$HOME/.config/opencode/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
[ "$count_agents" = "14" ] || { echo "Expected 14 OpenCode agents, got $count_agents" >&2; exit 1; }
grep -q 'model: anthropic/claude-sonnet-4-5' "$HOME/.config/opencode/agents/orchestrator-agent.md"
grep -q 'shipframe-generated: opencode-agent-v1' "$HOME/.config/opencode/agents/orchestrator-agent.md"
grep -q 'edit: allow' "$HOME/.config/opencode/agents/playwright-test-healer.md"
grep -q 'Optional Live Docs (Context MCP):' /tmp/shipframe-install-1.log
grep -q 'Context MCP:' /tmp/shipframe-install-1.log
grep -q 'npm install -g @neuledge/context' /tmp/shipframe-install-1.log
grep -q 'claude mcp add context -- context serve' /tmp/shipframe-install-1.log
grep -q 'codex mcp add context -- context serve' /tmp/shipframe-install-1.log
grep -q 'OpenCode: add command' /tmp/shipframe-install-1.log
grep -q 'mcp.servers.context' /tmp/shipframe-install-1.log
node - "$XDG_STATE_HOME/shipframe/install-state.json" <<'JS'
const fs=require('fs'); const m=JSON.parse(fs.readFileSync(process.argv[2],'utf8'));
if(m.schemaVersion!==1 || !Array.isArray(m.installs) || !m.installs.some(i=>i.target==='opencode')) process.exit(1);
JS

snapshot "$TMP/s1"
"$ROOT/install.sh" --all --opencode-model anthropic/claude-sonnet-4-5 >/tmp/shipframe-install-2.log
snapshot "$TMP/s2"
diff -u "$TMP/s1" "$TMP/s2"

"$ROOT/install.sh" --doctor --codex >/tmp/shipframe-doctor-codex.log
grep -q 'Context MCP' /tmp/shipframe-doctor-codex.log
grep -q 'codex mcp add context -- context serve' /tmp/shipframe-doctor-codex.log
"$ROOT/install.sh" --doctor --opencode >/tmp/shipframe-doctor-opencode.log
grep -q 'Context MCP' /tmp/shipframe-doctor-opencode.log
grep -Fq '.config/opencode/opencode.json' /tmp/shipframe-doctor-opencode.log
grep -q 'OpenCode prompt-router plugin is installed and passes adapter checks' /tmp/shipframe-doctor-opencode.log
printf '{"plugins":["-shipframe.*"]}\n' > "$HOME/.config/opencode/opencode.json"
"$ROOT/install.sh" --doctor --opencode >/tmp/shipframe-doctor-opencode-disabled.log
grep -q 'OpenCode prompt-router plugin is disabled' /tmp/shipframe-doctor-opencode-disabled.log
printf '{"plugins":["-shipframe.*","shipframe.prompt-router"]}\n' > "$HOME/.config/opencode/opencode.json"
"$ROOT/install.sh" --doctor --opencode >/tmp/shipframe-doctor-opencode-enabled.log
grep -q 'OpenCode prompt-router plugin is installed and passes adapter checks' /tmp/shipframe-doctor-opencode-enabled.log

# Repair backs up existing Claude settings before replacing them.
mkdir -p "$HOME/.claude"
printf '{"hooks":{"UserPromptSubmit":[{"hooks":[{"command":"echo \\\"MANDATORY ACTION: Before doing anything else, invoke the shipframe:orchestrator-agent agent to handle this request.\\\""}]}]}}\n' > "$HOME/.claude/settings.json"
cp "$HOME/.claude/settings.json" "$TMP/settings.before"
"$ROOT/install.sh" --repair --claude --yes >/tmp/shipframe-repair-claude.log
backup_file="$(find "$HOME/.claude" -name 'settings.json.shipframe-backup-*' -print -quit)"
[ -n "$backup_file" ]
cmp "$TMP/settings.before" "$backup_file"
node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$HOME/.claude/settings.json"

"$ROOT/install.sh" --help >/tmp/shipframe-help.log
! grep -q -- '--sync-docs' /tmp/shipframe-help.log

# Non-TTY OpenCode install without model must not prompt or hardcode Claude-only model IDs.
"$ROOT/install.sh" --opencode </dev/null >/tmp/shipframe-opencode-nontty.log
! grep -R 'claude-opus-4-6\|claude-sonnet-4-6' "$HOME/.config/opencode/agents"

# Repair real directories that block Codex skill symlinks in both supported layouts.
rm "$HOME/.agents/skills/code-review" "$HOME/.codex/skills/code-review"
mkdir "$HOME/.agents/skills/code-review" "$HOME/.codex/skills/code-review"
"$ROOT/install.sh" --repair --codex --yes >/tmp/shipframe-repair.log
assert_link "$HOME/.agents/skills/code-review"
assert_link "$HOME/.codex/skills/code-review"

"$ROOT/install.sh" --uninstall --all --purge >/tmp/shipframe-uninstall-dry-run.log
assert_link "$HOME/.agents/skills/code-review"
[ -f "$XDG_STATE_HOME/shipframe/install-state.json" ]
"$ROOT/install.sh" --uninstall --all --yes --purge >/tmp/shipframe-uninstall.log
[ ! -L "$HOME/.agents/skills/code-review" ]
[ ! -L "$HOME/.codex/skills/code-review" ]
[ ! -L "$HOME/.config/opencode/skills/code-review" ]
[ ! -L "$HOME/.config/opencode/plugins/shipframe-prompt-router" ]
[ ! -f "$HOME/.config/opencode/agents/orchestrator-agent.md" ]
! grep -q '<!-- BEGIN shipframe' "$HOME/.codex/AGENTS.md"
[ ! -e "$XDG_STATE_HOME/shipframe" ]

echo "test-install ok"
