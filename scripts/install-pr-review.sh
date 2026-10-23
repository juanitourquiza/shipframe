#!/usr/bin/env bash
# ShipFrame AI PR reviewer — repo-level installer (opt-in).
# Writes the GitHub Action workflow and review script into a project repo.
# Never touches API keys: the user adds SF_REVIEW_API_KEY as a GitHub secret.
#
# Usage: install-pr-review.sh <provider> [project_dir]
#   provider: nan-builders | claude | openai | custom | off
#   custom requires SF_REVIEW_BASE_URL and SF_REVIEW_MODEL (env or TTY prompt).

set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$SOURCE_DIR/templates/pr-review"

usage() {
  echo "Usage: install-pr-review.sh <nan-builders|claude|openai|custom|off> [project_dir]"
}

provider="${1:-}"
project_dir="${2:-$(pwd)}"

case "$provider" in
  nan-builders|claude|openai|custom|off) ;;
  *) usage >&2; exit 2 ;;
esac
[ -d "$project_dir" ] || { echo "Error: project dir not found: $project_dir" >&2; exit 2; }

if [ "$provider" = "off" ]; then
  echo "AI PR reviewer: disabled. Existing reviewer files were left untouched; remove them with --uninstall."
  exit 0
fi

provider_config() {
  case "$1" in
    nan-builders) echo "openai_compatible|https://api.nan.builders/v1|glm5.3-flash" ;;
    claude)       echo "anthropic|https://api.anthropic.com|claude-sonnet-4-5" ;;
    openai)       echo "openai_compatible|https://api.openai.com/v1|gpt-4o-mini" ;;
    *) return 1 ;;
  esac
}

# Escapa caracteres especiales de sed en el reemplazo (& y | con delimitador |).
sed_escape() { printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'; }

if [ "$provider" = "custom" ]; then
  api="openai_compatible"
  base_url="${SF_REVIEW_BASE_URL:-}"
  model="${SF_REVIEW_MODEL:-}"
  if { [ -z "$base_url" ] || [ -z "$model" ]; } && [ -t 0 ] && [ -t 1 ]; then
    if [ -z "$base_url" ]; then
      printf "Custom OpenAI-compatible base URL (e.g. https://host/v1): "
      read -r base_url || true
    fi
    if [ -z "$model" ]; then
      printf "Model name: "
      read -r model || true
    fi
  fi
  if [ -z "$base_url" ] || [ -z "$model" ]; then
    echo "Error: --pr-review custom needs SF_REVIEW_BASE_URL and SF_REVIEW_MODEL (env vars or TTY)." >&2
    exit 2
  fi
else
  IFS='|' read -r api base_url model <<< "$(provider_config "$provider")"
fi

case "$base_url" in
  http://*|https://*) ;;
  *) echo "Error: base URL must start with http:// or https:// (got: $base_url)" >&2; exit 2 ;;
esac

workflow_dir="$project_dir/.github/workflows"
workflow_dst="$workflow_dir/shipframe-review.yml"
script_dst="$project_dir/scripts/sf_pr_review.py"

mkdir -p "$workflow_dir" "$project_dir/scripts"
sed \
  -e "s|__SF_PROVIDER__|$(sed_escape "$provider")|g" \
  -e "s|__SF_REVIEW_API__|$(sed_escape "$api")|g" \
  -e "s|__SF_REVIEW_BASE_URL__|$(sed_escape "$base_url")|g" \
  -e "s|__SF_REVIEW_MODEL__|$(sed_escape "$model")|g" \
  "$TEMPLATE_DIR/shipframe-review.yml.tmpl" > "$workflow_dst"
cp "$TEMPLATE_DIR/sf_pr_review.py" "$script_dst"
chmod +x "$script_dst"

if [ -f "$workflow_dst" ] && [ -f "$script_dst" ]; then
  echo "  wrote $workflow_dst (provider: $provider, model: $model)"
  echo "  wrote $script_dst"
fi

echo ""
echo "AI PR reviewer installed. One manual step remains:"
echo "  1) Add the repository secret SF_REVIEW_API_KEY with your $provider API key:"
echo "       gh secret set SF_REVIEW_API_KEY --body \"<your-key>\"   # or repo Settings → Secrets → Actions"
echo "  2) Open (or push to) a pull request: one review comment will appear and update on every push."
echo "  Security: fork PRs are skipped, the script never prints the key, and the workflow cannot push code."
