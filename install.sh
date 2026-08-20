#!/usr/bin/env bash
# shellcheck disable=SC2015,SC2016
set -euo pipefail

_C='\033[0;36m'; _P='\033[0;35m'; _D='\033[2;37m'; _R='\033[0m'

print_banner() {
  echo -e "${_P}"
  cat << 'WORDMARK'
███████╗██╗  ██╗██╗██████╗ ███████╗██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██║  ██║██║██╔══██╗██╔════╝██╔══██╗██╔══██╗████╗ ████║██╔════╝
███████╗███████║██║██████╔╝█████╗  ██████╔╝███████║██╔████╔██║█████╗
╚════██║██╔══██║██║██╔═══╝ ██╔══╝  ██╔══██╗██╔══██║██║╚██╔╝██║██╔══╝
███████║██║  ██║██║██║     ██║     ██║  ██║██║  ██║██║ ╚═╝ ██║███████╗
╚══════╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
WORDMARK
  echo -e "${_D}"
  echo   "                  AI workflows for teams that ship"
  echo -e "${_R}"
}

print_usage() {
  cat <<USAGE
Usage: install.sh [ACTION] [TARGET] [OPTIONS]

Install targets:
  --claude       Install for Claude Code.
  --opencode     Install for OpenCode (skills + converted agents).
  --codex        Install for Codex CLI (skills + orchestrator workflow).
  --all          Install for Claude Code, OpenCode, and Codex.

Actions:
  install        Default action. Preserves the v0.3 command behavior.
  --doctor       Read-only diagnostics. Use --repo-only for CI-safe repo checks.
  --repair       Repair ShipFrame-owned artifacts. Dry-run unless --yes is passed.
  --uninstall    Remove ShipFrame-owned artifacts. Dry-run unless --yes is passed.

Options:
  --repo-only                         Only validate the ShipFrame repository.
  --yes                               Apply --repair/--uninstall changes.
  --purge                             With --uninstall, remove ShipFrame cache/state too.
  --opencode-model provider/model     Explicit OpenCode model override for converted agents.
  -h, --help                          Show this help.

Examples:
  ./install.sh --codex
  ./install.sh --doctor --repo-only
  ./install.sh --repair --opencode --yes
  ./install.sh --uninstall --all --yes --purge

Optional memory:
  ShipFrame checks whether Engram is installed and prints setup guidance.
  It never installs or configures Engram automatically.
USAGE
}

ACTION="install"
TARGET=""
REPO_ONLY=false
YES=false
PURGE=false
OPENCODE_MODEL=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    install) ACTION="install" ;;
    --doctor|--check) ACTION="doctor" ;;
    --repair) ACTION="repair" ;;
    --uninstall) ACTION="uninstall" ;;
    --claude) TARGET="claude" ;;
    --opencode) TARGET="opencode" ;;
    --codex) TARGET="codex" ;;
    --all) TARGET="all" ;;
    --repo-only) REPO_ONLY=true ;;
    --yes) YES=true ;;
    --purge) PURGE=true ;;
    --opencode-model|--model)
      shift || { echo "Missing value for --opencode-model" >&2; exit 2; }
      OPENCODE_MODEL="$1"
      ;;
    -h|--help) print_banner; print_usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; print_usage; exit 2 ;;
  esac
  shift
done

if [ "$ACTION" = "doctor" ] && [ "$REPO_ONLY" = true ] && [ -n "$TARGET" ]; then
  echo "--doctor --repo-only does not use install targets." >&2
  exit 2
fi

print_banner

prompt_choice() {
  local choice=""
  while :; do
    echo "Select an option:"
    echo "  1) Install for Claude Code"
    echo "  2) Install for OpenCode"
    echo "  3) Install for Codex CLI"
    echo "  4) Install for all"
    echo "  5) Exit"
    printf "> "

    if [ -t 0 ]; then
      if ! read -r choice; then echo ""; echo "Aborted."; exit 0; fi
    else
      choice="$( { read -r line < /dev/tty && printf '%s' "$line"; } 2>/dev/null )" || true
      if [ -z "$choice" ] && ! { : < /dev/tty; } 2>/dev/null; then
        echo ""
        echo "No TTY available. Re-run with --claude, --opencode, --codex, or --all." >&2
        exit 1
      fi
    fi

    case "$choice" in
      1) TARGET="claude"; return ;;
      2) TARGET="opencode"; return ;;
      3) TARGET="codex"; return ;;
      4) TARGET="all"; return ;;
      5) echo "Aborted."; exit 0 ;;
      *) echo "Invalid choice: $choice"; echo "" ;;
    esac
  done
}

if [ -z "$TARGET" ] && [ "$ACTION" != "doctor" ]; then
  prompt_choice
fi
if [ -z "$TARGET" ] && [ "$ACTION" = "doctor" ] && [ "$REPO_ONLY" = false ]; then
  TARGET="all"
fi

PLUGIN_REPO="https://github.com/juanitourquiza/shipframe.git"
PLUGIN_CACHE="${XDG_DATA_HOME:-$HOME/.local/share}/shipframe"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/shipframe"
MANIFEST_FILE="$STATE_DIR/install-state.json"
SOURCE_DIR=""
_HTTPS_REWRITE_ADDED=false
trap cleanup_https_fallback EXIT

resolve_source_dir() {
  [ -n "$SOURCE_DIR" ] && return
  local src="${BASH_SOURCE[0]:-}"
  if [ -n "$src" ] && [ -f "$src" ]; then
    SOURCE_DIR="$(cd "$(dirname "$src")" && pwd)"
    return
  fi
  if [ -d "$PLUGIN_CACHE/.git" ]; then
    echo "Updating plugin cache at $PLUGIN_CACHE..."
    git -C "$PLUGIN_CACHE" pull --ff-only --quiet
  else
    echo "Cloning plugin into $PLUGIN_CACHE..."
    mkdir -p "$(dirname "$PLUGIN_CACHE")"
    git clone --quiet "$PLUGIN_REPO" "$PLUGIN_CACHE"
  fi
  SOURCE_DIR="$PLUGIN_CACHE"
}

_ssh_works() {
  ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 | grep -qi "successfully authenticated"
}
ensure_https_fallback() {
  if _ssh_works; then return; fi
  if git config --global --get url."https://github.com/".insteadOf >/dev/null 2>&1; then
    echo "SSH not available — HTTPS rewrite already configured, continuing."
    return
  fi
  echo "SSH not available — configuring git to use HTTPS for github.com..."
  git config --global url."https://github.com/".insteadOf "git@github.com:"
  _HTTPS_REWRITE_ADDED=true
}
cleanup_https_fallback() {
  if [ "${_HTTPS_REWRITE_ADDED:-false}" = true ]; then
    echo "Cleaning up temporary HTTPS rewrite..."
    git config --global --unset url."https://github.com/".insteadOf || true
    _HTTPS_REWRITE_ADDED=false
  fi
}

sha_file() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'; else sha256sum "$1" | awk '{print $1}'; fi
}
plugin_version() {
  resolve_source_dir
  node -e "const fs=require('fs'); const p='$SOURCE_DIR/.claude-plugin/plugin.json'; console.log(JSON.parse(fs.readFileSync(p,'utf8')).version)" 2>/dev/null || echo unknown
}
atomic_write_json() {
  local file="$1"; shift
  mkdir -p "$(dirname "$file")"
  local tmp; tmp="$(mktemp "${file}.tmp.XXXXXX")"
  "$@" > "$tmp"
  node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$tmp"
  mv "$tmp" "$file"
}
write_manifest() {
  resolve_source_dir
  mkdir -p "$STATE_DIR"
  local version; version="$(plugin_version)"
  node - "$MANIFEST_FILE" "$SOURCE_DIR" "$version" "$TARGET" <<'JS'
const fs=require('fs');
const [,,file,source,version,target]=process.argv;
let current={schemaVersion:1, installs:[]};
if (fs.existsSync(file)) { try { current=JSON.parse(fs.readFileSync(file,'utf8')); } catch { current={schemaVersion:1, installs:[]}; } }
current.schemaVersion=1;
current.updatedAt=new Date().toISOString();
current.sourceDir=source;
current.shipframeVersion=version;
current.lastTarget=target;
fs.writeFileSync(file, JSON.stringify(current,null,2)+'\n');
JS
}
record_artifacts() {
  resolve_source_dir
  local target_name="$1"; shift
  mkdir -p "$STATE_DIR"
  node - "$MANIFEST_FILE" "$target_name" "$@" <<'JS'
const fs=require('fs');
const crypto=require('crypto');
const [,,file,target,...paths]=process.argv;
let m={schemaVersion:1, installs:[]};
if (fs.existsSync(file)) { try { m=JSON.parse(fs.readFileSync(file,'utf8')); } catch {} }
m.installs = (m.installs||[]).filter(i => i.target !== target);
const artifacts=[];
for (const p of paths) {
  if (!fs.existsSync(p)) continue;
  const stat=fs.lstatSync(p);
  const item={path:p, type:stat.isSymbolicLink()?'symlink':'file'};
  if (stat.isSymbolicLink()) item.linkTarget=fs.readlinkSync(p);
  if (stat.isFile()) item.sha256=crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
  artifacts.push(item);
}
m.installs.push({target, installedAt:new Date().toISOString(), artifacts});
fs.writeFileSync(file, JSON.stringify(m,null,2)+'\n');
JS
}

status_counts_ok=0; status_counts_warn=0; status_counts_err=0
report_ok(){ printf '✓ %s\n' "$1"; status_counts_ok=$((status_counts_ok+1)); }
report_warn(){ printf '⚠ %s\n' "$1"; status_counts_warn=$((status_counts_warn+1)); }
report_err(){ printf '✗ %s\n' "$1"; status_counts_err=$((status_counts_err+1)); }
command_exists(){ command -v "$1" >/dev/null 2>&1; }

repo_doctor() {
  resolve_source_dir
  cd "$SOURCE_DIR"
  status_counts_ok=0; status_counts_warn=0; status_counts_err=0
  bash -n install.sh && report_ok "install.sh syntax" || report_err "install.sh syntax (run: bash -n install.sh)"
  if command_exists shellcheck; then shellcheck install.sh && report_ok "shellcheck install.sh" || report_err "shellcheck install.sh"; else report_warn "shellcheck not installed (run: brew install shellcheck)"; fi
  node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/plugin.json','utf8')); JSON.parse(require('fs').readFileSync('.claude-plugin/marketplace.json','utf8'))" && report_ok "plugin JSON parses" || report_err "plugin JSON parses"
  node <<'JS' && report_ok "plugin/marketplace versions match" || report_err "plugin/marketplace versions differ"
const fs=require('fs');
const plugin=JSON.parse(fs.readFileSync('.claude-plugin/plugin.json','utf8'));
const market=JSON.parse(fs.readFileSync('.claude-plugin/marketplace.json','utf8'));
if (plugin.version !== market.metadata.version || plugin.version !== market.plugins[0].version) process.exit(1);
JS
  node <<'JS' && report_ok "marketplace schema compatibility" || report_err "marketplace has unsupported top-level license"
const fs=require('fs'); const m=JSON.parse(fs.readFileSync('.claude-plugin/marketplace.json','utf8')); if (Object.prototype.hasOwnProperty.call(m,'license')) process.exit(1);
JS
  python3 - <<'PY' && report_ok "skill and agent frontmatter" || report_err "frontmatter invalid in skills/ or agents/"
from pathlib import Path
bad=[]
for root, pat in [('skills','*/SKILL.md'), ('agents','*.md')]:
  for p in sorted(Path(root).glob(pat)):
    txt=p.read_text()
    if not txt.startswith('---\n') or txt.find('\n---', 4) == -1:
      bad.append(str(p))
if bad: raise SystemExit('\n'.join(bad))
PY
  local skill_count agent_count
  skill_count="$(find skills -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
  agent_count="$(find agents -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
  [ "$skill_count" = "33" ] && report_ok "skill count is 33" || report_warn "skill count is $skill_count (docs/tests may need update)"
  [ "$agent_count" = "14" ] && report_ok "agent count is 14" || report_warn "agent count is $agent_count (docs/tests may need update)"
  node <<'JS' && report_ok "README skill catalog covers installed skills" || report_err "README missing skills from skills/*"
const fs=require('fs'); const path=require('path');
const readme=fs.readFileSync('README.md','utf8');
const skills=fs.readdirSync('skills').filter(d=>fs.existsSync(path.join('skills',d,'SKILL.md')));
const missing=skills.filter(s=>!readme.includes('`'+s+'`'));
if (missing.length) { console.error(missing.join('\n')); process.exit(1); }
JS
  node <<'JS' && report_ok "Codex README routing matches workflow intents" || report_warn "Codex README routing summary omits some workflow intents"
const fs=require('fs');
const wf=fs.readFileSync('codex/dev-workflow.md','utf8'); const rm=fs.readFileSync('README.md','utf8');
const intents=[...wf.matchAll(/\| `([^`]+)` \|/g)].map(m=>m[1]).filter(x=>x!=='unknown');
const missing=intents.filter(i=>!rm.includes('`'+i+'`'));
if (missing.length) { console.error(missing.join('\n')); process.exit(1); }
JS
  [ -s wiki/index.md ] && ! grep -q '\*(empty — filled by `/wiki-forge`)\*' wiki/index.md && report_ok "wiki/index.md populated" || report_warn "wiki/index.md still has placeholders (run wiki-forge/wiki-sync)"
  echo "Doctor summary: $status_counts_ok ok, $status_counts_warn warnings, $status_counts_err errors"
  [ "$status_counts_err" -eq 0 ]
}

doctor_bin() {
  local bin="$1" label="$2"
  if command_exists "$bin"; then report_ok "$label binary: $(command -v "$bin")"; else report_warn "$label binary missing (install/configure if you use this target)"; fi
}
check_symlink_dir() {
  local dir="$1" expected_root="$2" label="$3"
  if [ ! -d "$dir" ]; then report_warn "$label missing: $dir"; return; fi
  local broken=0 unmanaged=0 total=0
  while IFS= read -r -d '' p; do
    total=$((total+1))
    if [ ! -e "$p" ]; then broken=$((broken+1)); continue; fi
    local dest; dest="$(readlink "$p")"
    case "$dest" in "$expected_root"/*) ;; *) unmanaged=$((unmanaged+1));; esac
  done < <(find "$dir" -maxdepth 1 -type l -print0 2>/dev/null)
  [ "$broken" -eq 0 ] && report_ok "$label symlinks ($total)" || report_err "$label has $broken broken symlink(s); run ./install.sh --repair --yes"
  [ "$unmanaged" -eq 0 ] || report_warn "$label has $unmanaged unmanaged symlink(s)"
}

environment_doctor() {
  resolve_source_dir
  status_counts_ok=0; status_counts_warn=0; status_counts_err=0
  case "$TARGET" in
    claude|all) doctor_bin claude "Claude Code" ;;
  esac
  case "$TARGET" in
    opencode|all) doctor_bin opencode "OpenCode" ;;
  esac
  case "$TARGET" in
    codex|all) doctor_bin codex "Codex" ;;
  esac
  doctor_bin node "Node.js"; doctor_bin git "Git"; doctor_bin engram "Engram"
  case "$TARGET" in
    opencode|all) check_symlink_dir "$HOME/.config/opencode/skills" "$SOURCE_DIR/skills" "OpenCode skills" ;;
  esac
  case "$TARGET" in
    codex|all) check_symlink_dir "$HOME/.codex/skills" "$SOURCE_DIR/skills" "Codex skills" ;;
  esac
  if [[ "$TARGET" =~ ^(codex|all)$ ]]; then
    if [ -f "$HOME/.codex/AGENTS.md" ] && grep -q '<!-- BEGIN shipframe' "$HOME/.codex/AGENTS.md"; then
      grep -q 'shipframe-block-version: 1' "$HOME/.codex/AGENTS.md" && report_ok "Codex managed block versioned" || report_warn "Codex managed block lacks version; re-run install or repair"
    else report_warn "Codex managed block missing"; fi
    if command_exists codex; then codex doctor --summary >/dev/null 2>&1 && report_ok "codex doctor" || report_warn "codex doctor reported issues; run codex doctor --summary"; fi
  fi
  if [[ "$TARGET" =~ ^(claude|all)$ ]]; then
    [ -f "$SOURCE_DIR/hooks/hooks.json" ] && report_ok "Claude plugin hooks present" || report_err "hooks/hooks.json missing"
    if [ -f "$HOME/.claude/settings.json" ]; then
      node - "$HOME/.claude/settings.json" <<'JS' && report_ok "Claude settings JSON parses" || report_err "Claude settings JSON invalid"
JSON.parse(require('fs').readFileSync(process.argv[2],'utf8'))
JS
      grep -q 'MANDATORY ACTION: Before doing anything else' "$HOME/.claude/settings.json" && report_warn "Legacy manual ShipFrame hook found; run ./install.sh --repair --claude --yes" || report_ok "No legacy manual ShipFrame hooks"
    fi
  fi
  echo "Doctor summary: $status_counts_ok ok, $status_counts_warn warnings, $status_counts_err errors"
  [ "$status_counts_err" -eq 0 ]
}

run_doctor() {
  if [ "$REPO_ONLY" = true ]; then repo_doctor; else environment_doctor; fi
}

remove_legacy_claude_hooks() {
  local settings_file="$HOME/.claude/settings.json"
  [ -f "$settings_file" ] || return 0
  local tmp; tmp="$(mktemp "${settings_file}.tmp.XXXXXX")"
  node - "$settings_file" > "$tmp" <<'JS'
const fs=require('fs'); const file=process.argv[2]; const s=JSON.parse(fs.readFileSync(file,'utf8'));
const EXACT=new Set([
 "echo 'MANDATORY ACTION: Before doing anything else, invoke the shipframe:orchestrator-agent agent to handle this request.'",
 "echo 'MANDATORY ACTION: A subagent started. Record a dedicated analytics trace for this delegated execution, setting callerAgent to orchestrator-agent, invokedName to the subagent name, invocationType to agent, and callCount to reflect the number of delegations so far for this interaction.'"
]);
if (s.hooks) for (const key of Object.keys(s.hooks)) {
  s.hooks[key]=(s.hooks[key]||[]).map(e=>({...e, hooks:(e.hooks||[]).filter(h=>!EXACT.has(String(h.command||'')))})).filter(e=>(e.hooks||[]).length);
  if (!s.hooks[key].length) delete s.hooks[key];
}
if (s.hooks && !Object.keys(s.hooks).length) delete s.hooks;
process.stdout.write(JSON.stringify(s,null,2)+'\n');
JS
  node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$tmp"
  if [ "$YES" = true ]; then mv "$tmp" "$settings_file"; else rm "$tmp"; echo "dry-run: would remove exact legacy ShipFrame hooks from $settings_file"; fi
}

install_claude_code() {
  ensure_https_fallback
  echo "Adding marketplace source..."
  claude plugin marketplace add juanitourquiza/shipframe
  echo "Installing shipframe plugin..."
  claude plugin install shipframe
  cleanup_https_fallback
  echo "Claude Code install complete."
  echo "  Plugin : shipframe"
  echo "  Hooks  : plugin-managed hooks/hooks.json"
  write_manifest
  record_artifacts claude "$SOURCE_DIR/hooks/hooks.json" "$SOURCE_DIR/.claude-plugin/plugin.json"
}

link_skills() {
  local skills_dst="$1" mode="${2:-install}"
  resolve_source_dir
  local skills_src="$SOURCE_DIR/skills"
  [ -d "$skills_src" ] || { echo "Error: no skills/ directory in $SOURCE_DIR" >&2; exit 1; }
  mkdir -p "$skills_dst"
  echo "Linking skills into $skills_dst..."
  local installed=0 skipped=0 repaired=0
  for skill_dir in "$skills_src"/*/; do
    [ -f "$skill_dir/SKILL.md" ] || continue
    local name target desired
    name="$(basename "$skill_dir")"; target="$skills_dst/$name"; desired="${skill_dir%/}"
    if [ -L "$target" ]; then
      if [ "$(readlink "$target")" = "$desired" ] && [ -e "$target" ]; then echo "  ok $name"; installed=$((installed+1)); continue; fi
      if [ "$mode" = "repair" ] || [ "$mode" = "install" ]; then
        [ "$mode" = "repair" ] && repaired=$((repaired+1))
        rm "$target"; ln -s "$desired" "$target"; echo "  link $name"; installed=$((installed+1)); continue
      fi
    elif [ -e "$target" ]; then
      if [ "$mode" = "repair" ]; then
        local backup
        backup="$target.shipframe-backup-$(date +%Y%m%d%H%M%S)"
        if [ "$YES" = true ]; then mv "$target" "$backup"; ln -s "$desired" "$target"; echo "  repair $name (moved existing to $backup)"; repaired=$((repaired+1)); installed=$((installed+1)); else echo "  dry-run repair $name (would move $target to $backup and symlink)"; skipped=$((skipped+1)); fi
      else
        echo "  skip $name (real directory at $target — run --repair --yes to back up and re-link)"; skipped=$((skipped+1))
      fi
      continue
    else
      ln -s "$desired" "$target"; echo "  link $name"; installed=$((installed+1)); continue
    fi
  done
  echo "  Linked  : $installed"; [ "$repaired" -gt 0 ] && echo "  Repaired: $repaired"; [ "$skipped" -gt 0 ] && echo "  Skipped : $skipped"
  return 0
}

collect_skill_artifacts() {
  local dir="$1"
  find "$dir" -maxdepth 1 -type l -print | sort || true
}

validate_opencode_model() {
  [ -z "$OPENCODE_MODEL" ] && return 0
  case "$OPENCODE_MODEL" in */*) ;; *) echo "Error: OpenCode models must use provider/model format: $OPENCODE_MODEL" >&2; exit 2;; esac
  if command_exists opencode; then
    if opencode models 2>/dev/null | grep -Fq "$OPENCODE_MODEL"; then return 0; fi
    echo "Warning: $OPENCODE_MODEL was not found in 'opencode models'; continuing because custom providers may be configured." >&2
  fi
}

install_opencode_skills() { link_skills "$HOME/.config/opencode/skills" "install"; }
install_opencode_agents() {
  resolve_source_dir; validate_opencode_model
  local agents_src="$SOURCE_DIR/agents" agents_dst="$HOME/.config/opencode/agents"
  [ -d "$agents_src" ] || { echo "Error: no agents/ directory in $SOURCE_DIR" >&2; exit 1; }
  mkdir -p "$agents_dst"
  echo "Converting agents into $agents_dst..."
  node - "$agents_src" "$agents_dst" "$OPENCODE_MODEL" <<'JS'
const fs = require('fs'); const path = require('path');
const [, , srcDir, dstDir, modelOverride] = process.argv;
const PRIMARY_AGENT='orchestrator-agent';
const WRITE_TOOLS=new Set(['Write','Edit','NotebookEdit','MultiEdit']);
const BASH_TOOLS=new Set(['Bash']);
function parseFrontmatter(text){ if(!text.startsWith('---\n')) return {fm:{},body:text}; const end=text.indexOf('\n---',4); if(end===-1) return {fm:{},body:text}; return {fm:parseYamlSubset(text.slice(4,end)), body:text.slice(end+4).replace(/^\n/,'')}; }
function parseYamlSubset(raw){ const lines=raw.split('\n'), out={}; let i=0; while(i<lines.length){ const line=lines[i]; if(!line.trim()||line.trim().startsWith('#')){i++;continue;} const m=line.match(/^([a-zA-Z_][\w-]*)\s*:\s*(.*)$/); if(!m){i++;continue;} const key=m[1], rest=m[2]; if(rest==='>'||rest==='|'){ const buf=[]; i++; while(i<lines.length&&(lines[i].startsWith('  ')||lines[i]==='')){buf.push(lines[i].replace(/^  /,'')); i++;} out[key]=buf.join(rest==='>'?' ':'\n').trim(); continue;} if(rest===''){ const items=[]; let j=i+1; while(j<lines.length&&/^\s*-\s+/.test(lines[j])){items.push(lines[j].replace(/^\s*-\s+/, '').trim()); j++;} if(items.length){out[key]=items; i=j; continue;} out[key]=''; i++; continue;} out[key]=rest.replace(/^["']|["']$/g,''); i++; } return out; }
function build(name,fm){ const lines=['---','# shipframe-generated: opencode-agent-v1']; const mode=name===PRIMARY_AGENT?'primary':'subagent'; if(fm.description){lines.push(`description: ${JSON.stringify(String(fm.description).replace(/\s+/g,' ').trim())}`);} lines.push(`mode: ${mode}`); if(modelOverride) lines.push(`model: ${modelOverride}`); const tools=Array.isArray(fm.tools)?fm.tools:[]; const canWrite=tools.some(t=>WRITE_TOOLS.has(t)); const canBash=tools.some(t=>BASH_TOOLS.has(t)); lines.push('permission:'); lines.push(`  edit: ${canWrite ? 'allow' : 'deny'}`); lines.push(`  bash: ${canBash ? 'allow' : 'ask'}`); lines.push(`  webfetch: ask`); lines.push('---'); return lines.join('\n'); }
const files=fs.readdirSync(srcDir).filter(f=>f.endsWith('.md')).sort(); let converted=0;
for(const file of files){ const text=fs.readFileSync(path.join(srcDir,file),'utf8'); const {fm,body}=parseFrontmatter(text); const name=String(fm.name||path.basename(file,'.md')).trim(); const dst=path.join(dstDir,`${name}.md`); if(fs.existsSync(dst)){ const cur=fs.readFileSync(dst,'utf8'); if(!cur.includes('shipframe-generated: opencode-agent-v1')){ console.log(`  skip ${name} (unmanaged file exists)`); continue; } } fs.writeFileSync(dst, `${build(name,fm)}\n\n${body}`); console.log(`  convert ${name} (${name===PRIMARY_AGENT?'primary':'subagent'})`); converted++; }
console.log(`  Converted : ${converted}`);
JS
}
install_opencode() {
  install_opencode_skills; echo ""; install_opencode_agents; echo ""
  echo "OpenCode install complete."
  echo "  Skills : $HOME/.config/opencode/skills   (symlinks — auto-update via git pull)"
  echo "  Agents : $HOME/.config/opencode/agents   (converted copies — re-run install to update)"
  echo "  Model  : ${OPENCODE_MODEL:-inherits OpenCode global/default model}"
  echo "  Source : $SOURCE_DIR"
  write_manifest
  mapfile -t artifacts < <(collect_skill_artifacts "$HOME/.config/opencode/skills"; find "$HOME/.config/opencode/agents" -maxdepth 1 -name '*.md' -print | sort)
  record_artifacts opencode "${artifacts[@]}"
  return 0
}

install_codex_skills() { link_skills "$HOME/.codex/skills" "install"; }
install_codex_workflow() {
  resolve_source_dir
  local workflow_src="$SOURCE_DIR/codex/dev-workflow.md" codex_home agents_file
  codex_home="$HOME/.codex"
  agents_file="$codex_home/AGENTS.md"
  [ -f "$workflow_src" ] || { echo "Error: no codex/dev-workflow.md in $SOURCE_DIR" >&2; exit 1; }
  mkdir -p "$codex_home"
  echo "Injecting workflow into $agents_file..."
  node - "$workflow_src" "$agents_file" <<'JS'
const fs=require('fs'); const [,,src,dst]=process.argv;
const BEGIN='<!-- BEGIN shipframe (managed by install.sh — do not edit) -->'; const END='<!-- END shipframe -->';
const content=fs.readFileSync(src,'utf8').trim(); const block=`${BEGIN}\n<!-- shipframe-block-version: 1 -->\n${content}\n${END}`;
let existing=fs.existsSync(dst)?fs.readFileSync(dst,'utf8'):'';
const begins=[...existing.matchAll(new RegExp(BEGIN.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),'g'))].map(m=>m.index);
const ends=[...existing.matchAll(new RegExp(END.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),'g'))].map(m=>m.index);
if(begins.length>1 || ends.length>1) throw new Error('Duplicate ShipFrame managed markers in '+dst+'. Run --repair --codex --yes or edit manually.');
const b=begins[0]??-1, e=ends[0]??-1;
if(b!==-1 && e!==-1 && e>b){ existing=`${existing.slice(0,b)}${block}${existing.slice(e+END.length)}`; console.log('  replaced managed block'); }
else if(b===-1 && e===-1){ const sep=existing && !existing.endsWith('\n')?'\n\n':(existing?'\n':''); existing=`${existing}${sep}${block}\n`; console.log(existing.trim()===block?'  created AGENTS.md with workflow':'  appended workflow block'); }
else throw new Error('Partial ShipFrame managed block in '+dst+'. Run --repair --codex --yes or edit manually.');
fs.writeFileSync(dst, existing);
JS
}
install_codex() {
  install_codex_skills; echo ""; install_codex_workflow; echo ""
  echo "Codex CLI install complete."
  echo "  Skills   : $HOME/.codex/skills    (symlinks — auto-update via git pull)"
  echo "  Workflow : $HOME/.codex/AGENTS.md (managed block — re-run install to update)"
  echo "  Model    : unchanged (Codex config.toml is user-owned)"
  echo "  Source   : $SOURCE_DIR"
  write_manifest
  mapfile -t artifacts < <(collect_skill_artifacts "$HOME/.codex/skills"; printf '%s\n' "$HOME/.codex/AGENTS.md")
  record_artifacts codex "${artifacts[@]}"
  return 0
}

uninstall_symlinked_skills() {
  local dst="$1"
  resolve_source_dir
  [ -d "$dst" ] || return 0
  for skill_dir in "$SOURCE_DIR/skills"/*/; do
    [ -f "$skill_dir/SKILL.md" ] || continue
    local name target desired; name="$(basename "$skill_dir")"; target="$dst/$name"; desired="${skill_dir%/}"
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$desired" ]; then
      if [ "$YES" = true ]; then rm "$target"; echo "  removed $target"; else echo "  dry-run: would remove $target"; fi
    fi
  done
}
remove_codex_block() {
  local agents_file="$HOME/.codex/AGENTS.md"; [ -f "$agents_file" ] || return 0
  if [ "$YES" = true ]; then
    node - "$agents_file" <<'JS'
const fs=require('fs'); const file=process.argv[2]; let s=fs.readFileSync(file,'utf8');
const BEGIN='<!-- BEGIN shipframe (managed by install.sh — do not edit) -->'; const END='<!-- END shipframe -->'; const b=s.indexOf(BEGIN), e=s.indexOf(END);
if(b!==-1&&e!==-1&&e>b){ s=(s.slice(0,b)+s.slice(e+END.length)).replace(/\n{3,}/g,'\n\n'); fs.writeFileSync(file,s.trim()?s.replace(/[ \t]+\n/g,'\n'):''); console.log('  removed Codex managed block'); }
JS
  else echo "  dry-run: would remove ShipFrame block from $agents_file"; fi
}
remove_opencode_agents() {
  local dir="$HOME/.config/opencode/agents"; [ -d "$dir" ] || return 0
  for f in "$dir"/*.md; do [ -f "$f" ] || continue; if grep -q 'shipframe-generated: opencode-agent-v1' "$f"; then if [ "$YES" = true ]; then rm "$f"; echo "  removed $f"; else echo "  dry-run: would remove $f"; fi; fi; done
}
run_uninstall() {
  case "$TARGET" in
    claude|all)
      echo "Removing Claude legacy hooks and plugin..."; remove_legacy_claude_hooks
      if command_exists claude; then if [ "$YES" = true ]; then claude plugin uninstall shipframe || true; else echo "  dry-run: would run claude plugin uninstall shipframe"; fi; fi ;;
  esac
  case "$TARGET" in opencode|all) echo "Removing OpenCode artifacts..."; uninstall_symlinked_skills "$HOME/.config/opencode/skills"; remove_opencode_agents ;; esac
  case "$TARGET" in codex|all) echo "Removing Codex artifacts..."; uninstall_symlinked_skills "$HOME/.codex/skills"; remove_codex_block ;; esac
  if [ "$PURGE" = true ]; then
    if [ "$YES" = true ]; then rm -rf "$PLUGIN_CACHE" "$STATE_DIR"; echo "Purged $PLUGIN_CACHE and $STATE_DIR"; else echo "dry-run: would purge $PLUGIN_CACHE and $STATE_DIR"; fi
  fi
}
run_repair() {
  case "$TARGET" in claude|all) echo "Repairing Claude settings..."; remove_legacy_claude_hooks ;; esac
  case "$TARGET" in opencode|all) echo "Repairing OpenCode skills/agents..."; link_skills "$HOME/.config/opencode/skills" repair; install_opencode_agents ;; esac
  case "$TARGET" in codex|all) echo "Repairing Codex skills/workflow..."; link_skills "$HOME/.codex/skills" repair; install_codex_workflow ;; esac
  [ "$YES" = true ] && write_manifest || true
}
check_engram_memory() {
  [ "$ACTION" = "doctor" ] || [ "$ACTION" = "uninstall" ] || echo ""
  [ "$ACTION" = "doctor" ] || [ "$ACTION" = "uninstall" ] || echo "Optional persistent memory:"
  if [ "$ACTION" = "doctor" ] || [ "$ACTION" = "uninstall" ]; then return 0; fi
  if command_exists engram; then
    local engram_bin engram_version; engram_bin="$(command -v engram)"; engram_version="$(engram --version 2>/dev/null || engram version 2>/dev/null || true)"
    echo "  Engram : detected at $engram_bin"; [ -n "$engram_version" ] && echo "  Version: $engram_version"; echo "  Status : persistent memory is available if configured for your agent."
  else
    echo "  Engram : not detected"; echo "  Install: brew install gentleman-programming/tap/engram"
  fi
  echo "  Setup  : run the matching optional command when you want memory enabled:"
  case "$TARGET" in
    claude) echo "           claude plugin marketplace add Gentleman-Programming/engram && claude plugin install engram" ;;
    opencode) echo "           engram setup opencode" ;;
    codex) echo "           engram setup codex" ;;
    all) echo "           claude plugin marketplace add Gentleman-Programming/engram && claude plugin install engram"; echo "           engram setup opencode"; echo "           engram setup codex" ;;
  esac
}

case "$ACTION" in
  doctor) run_doctor; exit $? ;;
  repair) run_repair; exit $? ;;
  uninstall) run_uninstall; exit $? ;;
  install)
    case "$TARGET" in
      claude) install_claude_code ;;
      opencode) install_opencode ;;
      codex) install_codex ;;
      all) install_claude_code; echo ""; install_opencode; echo ""; install_codex ;;
      *) echo "Missing target. Use --claude, --opencode, --codex, or --all." >&2; exit 2 ;;
    esac
    check_engram_memory
    ;;
  *) echo "Invalid action: $ACTION" >&2; exit 2 ;;
esac
