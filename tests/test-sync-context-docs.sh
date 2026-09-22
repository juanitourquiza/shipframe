#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
PROJECT="$TMP/project"; mkdir -p "$PROJECT/.shipframe"
SCRIPT="$ROOT/scripts/sync-context-docs.sh"

"$SCRIPT" --project-dir "$TMP/no-manifest"
cat > "$PROJECT/.shipframe/context-packages.txt" <<'MANIFEST'
# exact package versions
npm/react@19.0.0
pip/fastapi@0.115.0 # pinned docs
MANIFEST
before="$(find "$PROJECT" -type f -print -exec shasum -a 256 {} \;)"
out="$($SCRIPT --project-dir "$PROJECT" --dry-run)"
printf '%s\n' "$out" | grep -F 'context install npm/react 19.0.0'
printf '%s\n' "$out" | grep -F 'context install pip/fastapi 0.115.0'
after="$(find "$PROJECT" -type f -print -exec shasum -a 256 {} \;)"
[ "$before" = "$after" ]
cat > "$PROJECT/.shipframe/context-packages.txt" <<'MANIFEST'
not-valid
MANIFEST
if "$SCRIPT" --project-dir "$PROJECT" --dry-run >/dev/null 2>&1; then
  echo "invalid manifest unexpectedly passed" >&2; exit 1
fi
printf 'test-sync-context-docs ok\n'
