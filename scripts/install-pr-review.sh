#!/usr/bin/env bash
# Opt-in, provider-aware AI PR/MR reviewer installer. Never handles credentials.
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$SOURCE_DIR/templates/pr-review"
usage() { echo "Usage: install-pr-review.sh <nan-builders|claude|openai|custom|off> [project_dir] [--platform github|gitlab] [--model id]"; }

provider="${1:-}"
if [ -z "$provider" ]; then usage >&2; exit 2; fi
shift
project_dir="$(pwd)"
if [ "$#" -gt 0 ] && [[ "$1" != --* ]]; then project_dir="$1"; shift; fi
platform=""
model_override=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --platform) [ "$#" -ge 2 ] || { echo "Missing value for --platform" >&2; exit 2; }; platform="$2"; shift ;;
    --model) [ "$#" -ge 2 ] || { echo "Missing value for --model" >&2; exit 2; }; model_override="$2"; shift ;;
    --detect) exec "$SOURCE_DIR/scripts/detect-pr-review-platform.sh" "$project_dir" ;;
    --default-model)
      case "$provider" in nan-builders) echo glm5.3-flash;; claude) echo claude-sonnet-4-5;; openai) echo gpt-4o-mini;; *) echo;; esac
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

case "$provider" in nan-builders|claude|openai|custom|off) ;; *) usage >&2; exit 2 ;; esac
if [ "$provider" = off ]; then
  echo "AI PR/MR reviewer: disabled. Existing reviewer files were left untouched; remove them with --uninstall."
  exit 0
fi
[ -d "$project_dir" ] || { echo "Error: project dir not found: $project_dir" >&2; exit 2; }
project_dir="$(git -C "$project_dir" rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Error: project directory is not inside a Git repository." >&2
  exit 2
}

provider_config() {
  case "$1" in
    nan-builders) echo "openai_compatible|https://api.nan.builders/v1|glm5.3-flash" ;;
    claude) echo "anthropic|https://api.anthropic.com|claude-sonnet-4-5" ;;
    openai) echo "openai_compatible|https://api.openai.com/v1|gpt-4o-mini" ;;
    *) return 1 ;;
  esac
}
sed_escape() { printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'; }

if [ "$provider" = custom ]; then
  api=openai_compatible
  base_url="${SF_REVIEW_BASE_URL:-}"
  model="${model_override:-${SF_REVIEW_MODEL:-}}"
  if { [ -z "$base_url" ] || [ -z "$model" ]; } && [ -t 0 ] && [ -t 1 ]; then
    [ -n "$base_url" ] || { printf 'Custom OpenAI-compatible base URL (e.g. https://host/v1): '; read -r base_url || true; }
    [ -n "$model" ] || { printf 'Model name: '; read -r model || true; }
  fi
  if [ -z "$base_url" ] || [ -z "$model" ]; then
    echo "Error: --pr-review custom needs SF_REVIEW_BASE_URL and SF_REVIEW_MODEL (or --pr-review-model)." >&2
    exit 2
  fi
else
  IFS='|' read -r api base_url model <<< "$(provider_config "$provider")"
  [ -z "$model_override" ] || model="$model_override"
fi

case "$base_url" in http://*|https://*) ;; *) echo "Error: base URL must start with http:// or https://" >&2; exit 2 ;; esac
case "$base_url$model" in *\"*|*\\*|*$'\n'*|*$'\r'*) echo "Error: quotes, backslashes, and newlines are not allowed in URL/model values" >&2; exit 2 ;; esac

if [ -z "$platform" ]; then
  platform="$("$SOURCE_DIR/scripts/detect-pr-review-platform.sh" "$project_dir")" || exit $?
fi
case "$platform" in github|gitlab) ;; *) echo "Error: platform must be github or gitlab" >&2; exit 2 ;; esac

script_dst="$project_dir/scripts/sf_pr_review.py"
if [ "$platform" = gitlab ]; then
  config="$project_dir/.gitlab-ci.yml"
  python3 "$SOURCE_DIR/scripts/manage-gitlab-ci-include.py" --check "$config"
  workflow_dir="$project_dir/.gitlab/ci"
  workflow_dst="$workflow_dir/shipframe-review.yml"
  template="$TEMPLATE_DIR/shipframe-review.gitlab.yml.tmpl"
else
  workflow_dir="$project_dir/.github/workflows"
  workflow_dst="$workflow_dir/shipframe-review.yml"
  template="$TEMPLATE_DIR/shipframe-review.yml.tmpl"
fi

mkdir -p "$workflow_dir" "$project_dir/scripts"
sed \
  -e "s|__SF_PROVIDER__|$(sed_escape "$provider")|g" \
  -e "s|__SF_REVIEW_API__|$(sed_escape "$api")|g" \
  -e "s|__SF_REVIEW_BASE_URL__|$(sed_escape "$base_url")|g" \
  -e "s|__SF_REVIEW_MODEL__|$(sed_escape "$model")|g" \
  "$template" > "$workflow_dst"
cp "$TEMPLATE_DIR/sf_pr_review.py" "$script_dst"
chmod +x "$script_dst"
if [ "$platform" = gitlab ]; then
  python3 "$SOURCE_DIR/scripts/manage-gitlab-ci-include.py" "$project_dir/.gitlab-ci.yml" "$workflow_dst"
fi

echo "  wrote $workflow_dst (platform: $platform, provider: $provider, model: $model)"
echo "  wrote $script_dst"
echo ""
echo "AI PR/MR reviewer installed. Configure CI/CD secrets before the next request:"
echo "  - SF_REVIEW_API_KEY: API key for $provider (GitHub Actions secret or GitLab CI/CD variable)."
if [ "$platform" = gitlab ]; then
  echo "  - SF_REVIEW_GITLAB_TOKEN: project access token with api scope and Reporter role, stored as a masked CI/CD variable."
  echo "  - GitLab: fork MRs are skipped; only run reviewer pipelines for trusted project contributors."
else
  echo "  - GitHub: fork PRs are skipped; permissions are limited to read code and comment."
fi
echo "One updating comment is maintained per PR/MR; the reviewer never pushes code or prints credentials."
