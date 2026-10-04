#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$ROOT/tests/test-project-memory-state.sh"

init="$ROOT/skills/project-memory-init/SKILL.md"
refresh="$ROOT/skills/project-memory-refresh/SKILL.md"
curator="$ROOT/skills/memory-curator/SKILL.md"
handoff="$ROOT/skills/handoff/SKILL.md"

for file in "$init" "$refresh" "$curator" "$handoff"; do
  [ -f "$file" ] || { echo "Missing project-memory workflow file: $file" >&2; exit 1; }
done

grep -qi 'only after confirmation' "$init"
grep -qi 'public repository\|public repo' "$init"
grep -qi 'gh auth status\|gh.*authentication' "$init"
grep -qi 'uncommitted\|worktree' "$init"
grep -qi 'transcript' "$init"
grep -qi 'scripts/project-memory-state.sh' "$init"
grep -qi 'sandbox denies writing' "$init"
grep -qi '\.shipframe/memory' "$refresh"
grep -q '\.shipframe/memory/tasks/' "$curator"
grep -qi 'enabled' "$refresh"
grep -qi 'project-memory-state.sh' "$curator"
grep -qi 'project-memory-state.sh' "$handoff"
grep -qi 'Engram' "$curator"

echo "project-memory workflow contract tests passed"
