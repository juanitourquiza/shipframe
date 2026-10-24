#!/usr/bin/env bash
# Resolve the host from the target project's origin remote without displaying its URL.
set -euo pipefail
project_dir="${1:-$(pwd)}"
[ -d "$project_dir" ] || { echo "Error: project directory not found." >&2; exit 2; }
remote="$(git -C "$project_dir" remote get-url origin 2>/dev/null || true)"
[ -n "$remote" ] || { echo "Error: no origin remote found; use --pr-review-platform to specify github or gitlab." >&2; exit 2; }
normalized="$(printf '%s' "$remote" | tr '[:upper:]' '[:lower:]')"
case "$normalized" in
  *github.com*|*github.*) echo github ;;
  *gitlab*) echo gitlab ;;
  *) echo "Error: origin host is not recognized as GitHub or GitLab; specify --pr-review-platform github|gitlab." >&2; exit 2 ;;
esac
