#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

make_repo() {
  local path="$1" remote="$2"
  mkdir -p "$path"
  git -C "$path" init -q
  git -C "$path" remote add origin "$remote"
}

GITLAB="$TMP/gitlab-project"
make_repo "$GITLAB" "https://gitlab.example.com/group/team/project.git"
"$ROOT/scripts/install-pr-review.sh" nan-builders "$GITLAB" --model glm5.3 > "$TMP/gitlab-install.log"
test -f "$GITLAB/.gitlab-ci.yml"
test -f "$GITLAB/.gitlab/ci/shipframe-review.yml"
test -f "$GITLAB/scripts/sf_pr_review.py"
grep -q "include:.*" "$GITLAB/.gitlab-ci.yml"
grep -q ".gitlab/ci/shipframe-review.yml" "$GITLAB/.gitlab-ci.yml"
grep -q "CI_PIPELINE_SOURCE.*merge_request_event" "$GITLAB/.gitlab-ci.yml"
grep -q 'extends: .shipframe-ai-mr-review-template' "$GITLAB/.gitlab-ci.yml"
grep -q '^\.shipframe-ai-mr-review-template:' "$GITLAB/.gitlab/ci/shipframe-review.yml"
grep -q 'SF_REVIEW_GITLAB_TOKEN' "$GITLAB/.gitlab/ci/shipframe-review.yml"
grep -q 'SF_REVIEW_MODEL: "glm5.3"' "$GITLAB/.gitlab/ci/shipframe-review.yml"

# Reinstallation must not duplicate the CI include.
"$ROOT/scripts/install-pr-review.sh" nan-builders "$GITLAB" --model glm5.3 >/dev/null
test "$(grep -c '.gitlab/ci/shipframe-review.yml' "$GITLAB/.gitlab-ci.yml")" = 1

# Existing include lists are preserved and extended once.
GITLAB_EXISTING="$TMP/gitlab-existing"
make_repo "$GITLAB_EXISTING" "git@gitlab.company.test:group/project.git"
cat > "$GITLAB_EXISTING/.gitlab-ci.yml" <<'YAML'
include:
  - local: .gitlab/ci/base.yml
stages: [test, deploy]
YAML
"$ROOT/scripts/install-pr-review.sh" openai "$GITLAB_EXISTING" >/dev/null
grep -q '.gitlab/ci/base.yml' "$GITLAB_EXISTING/.gitlab-ci.yml"
test "$(grep -c '.gitlab/ci/shipframe-review.yml' "$GITLAB_EXISTING/.gitlab-ci.yml")" = 1
test "$(grep -c '^shipframe-ai-mr-review:' "$GITLAB_EXISTING/.gitlab-ci.yml")" = 1
"$ROOT/scripts/manage-gitlab-ci-include.py" --remove "$GITLAB_EXISTING/.gitlab-ci.yml"
grep -q '.gitlab/ci/base.yml' "$GITLAB_EXISTING/.gitlab-ci.yml"
! grep -q 'shipframe-ai-mr-review\|.gitlab/ci/shipframe-review.yml' "$GITLAB_EXISTING/.gitlab-ci.yml"

# Respect an existing workflow gate instead of silently making MRs unrunnable.
BLOCKED="$TMP/gitlab-workflow-blocked"
make_repo "$BLOCKED" "https://gitlab.com/group/blocked.git"
printf 'workflow:\n  rules:\n    - if: "$CI_COMMIT_BRANCH"\n' > "$BLOCKED/.gitlab-ci.yml"
if "$ROOT/scripts/install-pr-review.sh" nan-builders "$BLOCKED" >/dev/null 2>&1; then
  echo 'incompatible workflow unexpectedly accepted' >&2
  exit 1
fi
test ! -e "$BLOCKED/.gitlab/ci/shipframe-review.yml"

# Unsupported repositories fail closed without creating reviewer files.
UNKNOWN="$TMP/unknown"
make_repo "$UNKNOWN" "https://code.example.com/group/project.git"
if "$ROOT/scripts/install-pr-review.sh" nan-builders "$UNKNOWN" >/dev/null 2>&1; then
  echo 'unknown provider unexpectedly accepted' >&2
  exit 1
fi
test ! -e "$UNKNOWN/.gitlab-ci.yml"
test ! -e "$UNKNOWN/.github/workflows/shipframe-review.yml"

echo 'PR review platform installer tests passed.'
