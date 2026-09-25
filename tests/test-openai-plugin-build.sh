#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

python3 "$repo_root/scripts/build-openai-plugin.py" --output-dir "$tmp_dir" >/tmp/shipframe-openai-plugin-build.log

bundle="$tmp_dir/shipframe"
manifest="$bundle/.codex-plugin/plugin.json"

[[ -f "$manifest" ]]
[[ -f "$tmp_dir/shipframe-openai-plugin.zip" ]]
[[ -f "$bundle/assets/icon.png" ]]
[[ -f "$bundle/assets/logo.png" ]]
[[ -f "$bundle/hooks/hooks.json" ]]
[[ -f "$bundle/hooks/codex-prompt-router.cjs" ]]
[[ -f "$bundle/hooks/prompt-router-core.cjs" ]]

python3 - "$manifest" "$bundle/assets/icon.png" "$bundle/assets/logo.png" "$repo_root/.claude-plugin/plugin.json" <<'PY'
import json
import struct
import sys
from pathlib import Path

def png_dimensions(path: str) -> tuple[int, int]:
    data = Path(path).read_bytes()
    assert data.startswith(b"\x89PNG\r\n\x1a\n")
    return struct.unpack(">II", data[16:24])

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
source_version = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))["version"]
assert manifest["name"] == "shipframe"
assert manifest["version"] == source_version
assert manifest["skills"] == "./skills/"
assert manifest["interface"]["developerName"] == "Juan Urquiza"
assert manifest["interface"]["composerIcon"] == "./assets/icon.png"
assert manifest["interface"]["logo"] == "./assets/logo.png"
assert len(manifest["interface"]["defaultPrompt"]) <= 3
assert "mcpServers" not in manifest
assert "apps" not in manifest
assert png_dimensions(sys.argv[2]) == (512, 512)
assert png_dimensions(sys.argv[3]) == (512, 512)
hooks = json.loads((Path(sys.argv[1]).parent.parent / "hooks" / "hooks.json").read_text(encoding="utf-8"))
assert "UserPromptSubmit" in hooks["hooks"]
assert "${PLUGIN_ROOT}" in hooks["hooks"]["UserPromptSubmit"][0]["hooks"][0]["command"]
PY

expected_skills=(
  project-memory-refresh
  feature-discovery
  plan-expert
  implement-task
  code-review
  create-pr
  bug-diagnosis
  release-checklist
  project-profile
  project-release
  deploy-evidence
  evidence-audit
  proof-runner
  handoff
  init-project
  codebase-design
  tdd
  research
  frontend-release
  backend-release
  a11y-auditor
  client-copy-review
  mcp-debugging
  generate-readme
  security-review
  e2e-verify
  dependency-upgrade
  api-contract-review
  incident-response
  memory-curator
)

actual_count="$(find "$bundle/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
[[ "$actual_count" == "${#expected_skills[@]}" ]]

for skill in "${expected_skills[@]}"; do
  [[ -f "$bundle/skills/$skill/SKILL.md" ]]
done

if command -v codex >/dev/null 2>&1; then
  market_root="$tmp_dir/marketplace"
  mkdir -p "$market_root/.agents/plugins" "$market_root/plugins"
  cp -R "$bundle" "$market_root/plugins/shipframe"
  cat > "$market_root/.agents/plugins/marketplace.json" <<'JSON'
{
  "name": "shipframe-local",
  "interface": {"displayName": "ShipFrame Local"},
  "plugins": [
    {
      "name": "shipframe",
      "source": {"source": "local", "path": "./plugins/shipframe"},
      "policy": {"installation": "AVAILABLE", "authentication": "ON_INSTALL"},
      "category": "Productivity"
    }
  ]
}
JSON
  mkdir -p "$tmp_dir/home" "$tmp_dir/codex"
  HOME="$tmp_dir/home" CODEX_HOME="$tmp_dir/codex" codex plugin marketplace add "$market_root" --json >/tmp/shipframe-openai-marketplace-add.json
  HOME="$tmp_dir/home" CODEX_HOME="$tmp_dir/codex" codex plugin list --available --json | grep 'shipframe@shipframe-local' >/dev/null
  HOME="$tmp_dir/home" CODEX_HOME="$tmp_dir/codex" codex plugin add shipframe@shipframe-local --json >/tmp/shipframe-openai-plugin-add.json
  plugin_version="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$repo_root/.claude-plugin/plugin.json")"
  [[ -f "$tmp_dir/codex/plugins/cache/shipframe-local/shipframe/$plugin_version/.codex-plugin/plugin.json" ]]
fi
