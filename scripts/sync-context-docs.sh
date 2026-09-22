#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: sync-context-docs.sh [--project-dir DIR] [--dry-run]

Reads DIR/.shipframe/context-packages.txt. Each non-comment line must be:
  <registry>/<package>@<exact-version>

The command never installs Context MCP. Install it explicitly with:
  npm install -g @neuledge/context
USAGE
}

PROJECT_DIR="$(pwd)"
DRY_RUN=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-dir) shift; [ "$#" -gt 0 ] || { echo "Missing value for --project-dir" >&2; exit 2; }; PROJECT_DIR="$1" ;;
    --dry-run) DRY_RUN=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [ ! -d "$PROJECT_DIR" ]; then
  echo "No Live Docs manifest found at $PROJECT_DIR/.shipframe/context-packages.txt; nothing to sync."
  exit 0
fi
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
MANIFEST="$PROJECT_DIR/.shipframe/context-packages.txt"
if [ ! -f "$MANIFEST" ]; then
  echo "No Live Docs manifest found at $MANIFEST; nothing to sync."
  exit 0
fi

entries=()
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%#*}"
  line="$(printf '%s' "$line" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  [ -n "$line" ] || continue
  if [[ ! "$line" =~ ^[a-z0-9._-]+/[a-zA-Z0-9._@/-]+@[0-9][0-9A-Za-z.+-]*$ ]]; then
    echo "Invalid manifest entry: $line" >&2
    exit 2
  fi
  entries+=("$line")
done < "$MANIFEST"

if [ "${#entries[@]}" -eq 0 ]; then
  echo "Live Docs manifest is empty; nothing to sync."
  exit 0
fi

if [ "$DRY_RUN" = true ]; then
  echo "Dry run: would sync ${#entries[@]} package(s) from $MANIFEST"
  for entry in "${entries[@]}"; do
    package_ref="${entry%@*}"
    version="${entry##*@}"
    printf '  context install %s %s\n' "$package_ref" "$version"
  done
  exit 0
fi

if ! command -v context >/dev/null 2>&1; then
  echo "Context MCP is not installed. Install it explicitly with: npm install -g @neuledge/context" >&2
  exit 1
fi

for entry in "${entries[@]}"; do
  package_ref="${entry%@*}"
  version="${entry##*@}"
  echo "Syncing $package_ref@$version"
  context install "$package_ref" "$version"
done

echo "Live Docs sync complete. Configure the Context MCP server for your client; no client configuration was modified."
