#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
README="$ROOT/README.md"

packs=(angular fastapi go javascript laravel nestjs nextjs nodejs php python react-vite rust typescript)
for pack in "${packs[@]}"; do
  path="$ROOT/project-packs/$pack/README.md"
  if [[ ! -f "$path" ]]; then
    echo "Missing technology pack: project-packs/$pack/README.md" >&2
    exit 1
  fi
  if ! grep -Fq "project-packs/$pack/" "$README"; then
    echo "README does not list project-packs/$pack/" >&2
    exit 1
  fi
done

init_project="$ROOT/skills/init-project/SKILL.md"
live_docs="$ROOT/skills/live-docs/SKILL.md"
grep -Fq 'matching optional technology packs' "$init_project"
grep -Fq 'Context MCP' "$init_project"
grep -Fq 'Context MCP is optional' "$init_project"
grep -Fq 'exact package/version resolved from its lockfile' "$live_docs"
grep -Fq 'Versioned Documentation' "$init_project"
grep -Fq 'Cargo.lock' "$init_project"
grep -Fq 'laravel/framework' "$init_project"
grep -Fq '@angular/core' "$init_project"
grep -Fq 'vite' "$init_project"

echo "Technology packs and opt-in Context guidance passed"
