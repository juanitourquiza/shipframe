#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
_C='\033[0;36m'   # cyan
_P='\033[0;35m'   # purple
_D='\033[2;37m'   # dim white
_R='\033[0m'      # reset

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
Usage: install.sh [TARGET]

Targets:
  --claude     Install for Claude Code.
  --opencode   Install for OpenCode (skills + converted agents).
  --codex      Install for Codex CLI (skills + orchestrator workflow).
  --all        Install for Claude Code, OpenCode, and Codex.
  -h, --help   Show this help.

If no target is given, an interactive menu is shown.
USAGE
}

# ---------------------------------------------------------------------------
# Arg parsing
# ---------------------------------------------------------------------------
TARGET=""
if [ "$#" -gt 0 ]; then
  case "$1" in
    --claude)   TARGET="claude" ;;
    --opencode) TARGET="opencode" ;;
    --codex)    TARGET="codex" ;;
    --all)      TARGET="all" ;;
    -h|--help)  print_banner; print_usage; exit 0 ;;
    *)          echo "Unknown argument: $1" >&2; print_usage; exit 1 ;;
  esac
fi

print_banner

# ---------------------------------------------------------------------------
# Interactive menu (used when no flag is passed)
# ---------------------------------------------------------------------------
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
      if ! read -r choice; then
        echo ""; echo "Aborted."; exit 0
      fi
    else
      choice="$( { read -r line < /dev/tty && printf '%s' "$line"; } 2>/dev/null )" || true
      if [ -z "$choice" ] && ! { : < /dev/tty; } 2>/dev/null; then
        echo ""
        echo "No TTY available. Re-run with --claude, --opencode, or --all." >&2
        exit 1
      fi
    fi

    case "$choice" in
      1) TARGET="claude";   return ;;
      2) TARGET="opencode"; return ;;
      3) TARGET="codex";    return ;;
      4) TARGET="all";      return ;;
      5) echo "Aborted."; exit 0 ;;
      *) echo "Invalid choice: $choice"; echo "" ;;
    esac
  done
}

if [ -z "$TARGET" ]; then
  prompt_choice
fi

# ---------------------------------------------------------------------------
# SSH detection & HTTPS fallback
#
#   Claude Code's plugin manager may use SSH URLs (git@github.com:…) internally.
#   When SSH keys are not configured, plugin install fails. This block detects
#   that scenario and temporarily configures git to rewrite SSH URLs to HTTPS.
# ---------------------------------------------------------------------------
_HTTPS_REWRITE_ADDED=false

trap cleanup_https_fallback EXIT

_ssh_works() {
  ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \
      -T git@github.com 2>&1 | grep -qi "successfully authenticated"
}

ensure_https_fallback() {
  if _ssh_works; then
    return
  fi

  # Check if the user already has the rewrite configured
  if git config --global --get url."https://github.com/".insteadOf >/dev/null 2>&1; then
    echo "SSH not available — HTTPS rewrite already configured, continuing."
    return
  fi

  echo "SSH not available — configuring git to use HTTPS for github.com..."
  git config --global url."https://github.com/".insteadOf "git@github.com:"
  _HTTPS_REWRITE_ADDED=true
}

cleanup_https_fallback() {
  if [ "$_HTTPS_REWRITE_ADDED" = true ]; then
    echo "Cleaning up temporary HTTPS rewrite..."
    git config --global --unset url."https://github.com/".insteadOf || true
    _HTTPS_REWRITE_ADDED=false
  fi
}


# ---------------------------------------------------------------------------
# Source-dir resolution
#
#   Local invocation (./install.sh)  → use the script's own directory.
#   Curl pipe (curl ... | bash)      → clone the repo into a stable cache.
# ---------------------------------------------------------------------------
PLUGIN_REPO="https://github.com/juanitourquiza/shipframe.git"
PLUGIN_CACHE="$HOME/.local/share/shipframe"
SOURCE_DIR=""

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

# ---------------------------------------------------------------------------
# Claude Code install
# ---------------------------------------------------------------------------
install_claude_code() {
  local settings_file="$HOME/.claude/settings.json"

  ensure_https_fallback

  echo "Adding marketplace source..."
  claude plugin marketplace add juanitourquiza/shipframe

  echo "Installing shipframe plugin..."
  claude plugin install shipframe

  cleanup_https_fallback

  if [ ! -f "$settings_file" ]; then
    mkdir -p "$(dirname "$settings_file")"
    echo "{}" > "$settings_file"
  fi

  echo "Configuring hooks in $settings_file..."

  node - "$settings_file" <<'JS'
const fs = require('fs');
const file = process.argv[2];
const settings = JSON.parse(fs.readFileSync(file, 'utf8'));

const UPS_CMD = "echo 'MANDATORY ACTION: Before doing anything else, invoke the shipframe:orchestrator-agent agent to handle this request.'";
const SS_CMD  = "echo 'MANDATORY ACTION: A subagent started. Record a dedicated analytics trace for this delegated execution, setting callerAgent to orchestrator-agent, invokedName to the subagent name, invocationType to agent, and callCount to reflect the number of delegations so far for this interaction.'";

if (!settings.hooks) settings.hooks = {};

function commandPresent(entries, cmd) {
  return (entries || []).some(e => (e.hooks || []).some(h => h.command === cmd));
}

if (!commandPresent(settings.hooks.UserPromptSubmit, UPS_CMD)) {
  settings.hooks.UserPromptSubmit = settings.hooks.UserPromptSubmit || [];
  settings.hooks.UserPromptSubmit.push({ matcher: "", hooks: [{ type: "command", command: UPS_CMD }] });
}

if (!commandPresent(settings.hooks.SubagentStart, SS_CMD)) {
  settings.hooks.SubagentStart = settings.hooks.SubagentStart || [];
  settings.hooks.SubagentStart.push({ hooks: [{ type: "command", command: SS_CMD }] });
}

fs.writeFileSync(file, JSON.stringify(settings, null, 2) + '\n');
console.log('Hooks configured successfully.');
JS

  echo ""
  echo "Claude Code install complete."
  echo "  Plugin : shipframe"
  echo "  Hooks  : UserPromptSubmit, SubagentStart"
}

# ---------------------------------------------------------------------------
# Shared — symlink every skill/ subdir into a target directory
# ---------------------------------------------------------------------------
link_skills() {
  local skills_dst="$1"
  resolve_source_dir
  local skills_src="$SOURCE_DIR/skills"

  if [ ! -d "$skills_src" ]; then
    echo "Error: no skills/ directory in $SOURCE_DIR" >&2
    exit 1
  fi

  mkdir -p "$skills_dst"
  echo "Linking skills into $skills_dst..."

  local installed=0 skipped=0
  for skill_dir in "$skills_src"/*/; do
    [ -d "$skill_dir" ] || continue
    [ -f "$skill_dir/SKILL.md" ] || continue
    local name; name="$(basename "$skill_dir")"
    local target="$skills_dst/$name"

    if [ -L "$target" ]; then
      rm "$target"
    elif [ -e "$target" ]; then
      echo "  skip $name (real directory at $target — remove it manually to re-link)"
      skipped=$((skipped + 1))
      continue
    fi

    ln -s "${skill_dir%/}" "$target"
    echo "  link $name"
    installed=$((installed + 1))
  done

  echo "  Linked  : $installed"
  if [ "$skipped" -gt 0 ]; then
    echo "  Skipped : $skipped"
  fi
}

# ---------------------------------------------------------------------------
# OpenCode — skills (symlinked from the local clone)
# ---------------------------------------------------------------------------
install_opencode_skills() {
  link_skills "$HOME/.config/opencode/skills"
}

# ---------------------------------------------------------------------------
# OpenCode — agents (converted from Claude-shaped frontmatter)
# ---------------------------------------------------------------------------
install_opencode_agents() {
  resolve_source_dir
  local agents_src="$SOURCE_DIR/agents"
  local agents_dst="$HOME/.config/opencode/agents"

  if [ ! -d "$agents_src" ]; then
    echo "Error: no agents/ directory in $SOURCE_DIR" >&2
    exit 1
  fi

  mkdir -p "$agents_dst"
  echo "Converting agents into $agents_dst..."

  node - "$agents_src" "$agents_dst" <<'JS'
const fs = require('fs');
const path = require('path');

const [, , srcDir, dstDir] = process.argv;

const PRIMARY_AGENT = 'orchestrator-agent';
const WRITE_TOOLS = new Set(['Write', 'Edit', 'NotebookEdit']);
const BASH_TOOLS  = new Set(['Bash']);

function parseFrontmatter(text) {
  if (!text.startsWith('---\n')) return { fm: {}, body: text };
  const end = text.indexOf('\n---', 4);
  if (end === -1) return { fm: {}, body: text };
  const fmRaw = text.slice(4, end);
  const body = text.slice(end + 4).replace(/^\n/, '');
  return { fm: parseYamlSubset(fmRaw), body };
}

// Tiny YAML subset: top-level scalars, multiline `>` blocks, and `key:` lists of `- value`.
function parseYamlSubset(raw) {
  const lines = raw.split('\n');
  const out = {};
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (!line.trim() || line.trim().startsWith('#')) { i++; continue; }

    const m = line.match(/^([a-zA-Z_][\w-]*)\s*:\s*(.*)$/);
    if (!m) { i++; continue; }
    const key = m[1];
    const rest = m[2];

    if (rest === '>' || rest === '|') {
      const buf = [];
      i++;
      while (i < lines.length && (lines[i].startsWith('  ') || lines[i] === '')) {
        buf.push(lines[i].replace(/^  /, ''));
        i++;
      }
      out[key] = buf.join(rest === '>' ? ' ' : '\n').trim();
      continue;
    }

    if (rest === '') {
      // possibly a list
      const items = [];
      let j = i + 1;
      while (j < lines.length && /^\s*-\s+/.test(lines[j])) {
        items.push(lines[j].replace(/^\s*-\s+/, '').trim());
        j++;
      }
      if (items.length) {
        out[key] = items;
        i = j;
        continue;
      }
      out[key] = '';
      i++;
      continue;
    }

    out[key] = rest.replace(/^["']|["']$/g, '');
    i++;
  }
  return out;
}

function buildOpenCodeFrontmatter(name, fm) {
  const lines = ['---'];

  const mode = name === PRIMARY_AGENT ? 'primary' : 'subagent';
  if (fm.description) {
    const desc = String(fm.description).replace(/\s+/g, ' ').trim();
    lines.push(`description: ${JSON.stringify(desc)}`);
  }
  lines.push(`mode: ${mode}`);
  if (fm.model) lines.push(`model: ${fm.model}`);

  const tools = Array.isArray(fm.tools) ? fm.tools : [];
  const canWrite = tools.some(t => WRITE_TOOLS.has(t));
  const canBash  = tools.some(t => BASH_TOOLS.has(t));
  lines.push('tools:');
  lines.push(`  write: ${canWrite}`);
  lines.push(`  bash: ${canBash}`);

  lines.push('---');
  return lines.join('\n');
}

const files = fs.readdirSync(srcDir).filter(f => f.endsWith('.md'));
let converted = 0;
for (const file of files) {
  const full = path.join(srcDir, file);
  const text = fs.readFileSync(full, 'utf8');
  const { fm, body } = parseFrontmatter(text);
  const name = (fm.name || path.basename(file, '.md')).trim();

  const newFm = buildOpenCodeFrontmatter(name, fm);
  const out   = `${newFm}\n\n${body}`;
  fs.writeFileSync(path.join(dstDir, `${name}.md`), out);
  const role = name === PRIMARY_AGENT ? 'primary' : 'subagent';
  console.log(`  convert ${name} (${role})`);
  converted++;
}
console.log(`  Converted : ${converted}`);
JS
}

install_opencode() {
  install_opencode_skills
  echo ""
  install_opencode_agents
  echo ""
  echo "OpenCode install complete."
  echo "  Skills : $HOME/.config/opencode/skills   (symlinks — auto-update via git pull)"
  echo "  Agents : $HOME/.config/opencode/agents   (converted copies — re-run install to update)"
  echo "  Source : $SOURCE_DIR"
}

# ---------------------------------------------------------------------------
# Codex CLI — skills (symlinked) + orchestrator workflow (AGENTS.md import)
#
#   Codex has no sub-agent delegation, so the agents/ tree does not map. Instead
#   the orchestrator's intent→skill routing is shipped as codex/dev-workflow.md
#   and imported from the global ~/.codex/AGENTS.md so the single Codex agent
#   follows the same workflow. Skills are symlinked — identical SKILL.md format.
# ---------------------------------------------------------------------------
install_codex_skills() {
  link_skills "$HOME/.codex/skills"
}

install_codex_workflow() {
  resolve_source_dir
  local workflow_src="$SOURCE_DIR/codex/dev-workflow.md"
  local codex_home="$HOME/.codex"
  local agents_file="$codex_home/AGENTS.md"

  if [ ! -f "$workflow_src" ]; then
    echo "Error: no codex/dev-workflow.md in $SOURCE_DIR" >&2
    exit 1
  fi

  mkdir -p "$codex_home"
  echo "Injecting workflow into $agents_file..."

  # Codex does NOT expand @file imports in AGENTS.md — it only merges files by
  # directory proximity. So the workflow is inlined directly into the global
  # AGENTS.md between managed markers. Re-running replaces the block in place.
  node - "$workflow_src" "$agents_file" <<'JS'
const fs = require('fs');
const [, , src, dst] = process.argv;

const BEGIN = '<!-- BEGIN shipframe (managed by install.sh — do not edit) -->';
const END   = '<!-- END shipframe -->';

const content = fs.readFileSync(src, 'utf8').trim();
const block = `${BEGIN}\n${content}\n${END}`;

let existing = fs.existsSync(dst) ? fs.readFileSync(dst, 'utf8') : '';

const b = existing.indexOf(BEGIN);
const e = existing.indexOf(END);

if (b !== -1 && e !== -1 && e > b) {
  const before = existing.slice(0, b);
  const after  = existing.slice(e + END.length);
  existing = `${before}${block}${after}`;
  console.log('  replaced managed block');
} else {
  const sep = existing && !existing.endsWith('\n') ? '\n\n' : (existing ? '\n' : '');
  existing = `${existing}${sep}${block}\n`;
  console.log(existing.trim() === block ? '  created AGENTS.md with workflow' : '  appended workflow block');
}

fs.writeFileSync(dst, existing);
JS
}

install_codex() {
  install_codex_skills
  echo ""
  install_codex_workflow
  echo ""
  echo "Codex CLI install complete."
  echo "  Skills   : $HOME/.codex/skills    (symlinks — auto-update via git pull)"
  echo "  Workflow : $HOME/.codex/AGENTS.md (managed block — re-run install to update)"
  echo "  Source   : $SOURCE_DIR"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
case "$TARGET" in
  claude)
    install_claude_code
    ;;
  opencode)
    install_opencode
    ;;
  codex)
    install_codex
    ;;
  all)
    install_claude_code
    echo ""
    install_opencode
    echo ""
    install_codex
    ;;
esac
