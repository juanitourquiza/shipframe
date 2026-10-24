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

# Platform detection must inspect the remote host, not strings in the path.
HOST_TEST="$TMP/host-detect"
make_repo "$HOST_TEST" "https://gitlab.com/acme/github.io.git"
test "$("$ROOT/scripts/detect-pr-review-platform.sh" "$HOST_TEST")" = gitlab
git -C "$HOST_TEST" remote set-url origin "https://bitbucket.org/acme/gitlab-mirror.git"
if "$ROOT/scripts/detect-pr-review-platform.sh" "$HOST_TEST" >/dev/null 2>&1; then
  echo 'provider detected from repository path instead of host' >&2
  exit 1
fi
git -C "$HOST_TEST" remote set-url origin "ssh://git@notgitlab.internal/group/project.git"
if "$ROOT/scripts/detect-pr-review-platform.sh" "$HOST_TEST" >/dev/null 2>&1; then
  echo 'host containing the gitlab substring was incorrectly accepted' >&2
  exit 1
fi

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

# Optional project_dir works when provider flags follow the provider argument.
GITLAB_NO_DIR="$TMP/gitlab-no-dir"
make_repo "$GITLAB_NO_DIR" "git@gitlab.example.com:group/project.git"
(cd "$GITLAB_NO_DIR" && "$ROOT/scripts/install-pr-review.sh" nan-builders --platform gitlab >/dev/null)
test -f "$GITLAB_NO_DIR/.gitlab-ci.yml"

# Reinstallation must not duplicate the CI include.
"$ROOT/scripts/install-pr-review.sh" nan-builders "$GITLAB" --model glm5.3 >/dev/null
test "$(grep -c '.gitlab/ci/shipframe-review.yml' "$GITLAB/.gitlab-ci.yml")" = 1

# Existing include lists are preserved and extended once.
GITLAB_EXISTING="$TMP/gitlab-existing"
make_repo "$GITLAB_EXISTING" "git@gitlab.company.test:group/project.git"
printf "include: ['.gitlab/ci/base.yml', { project: group/central, file: shared.yml }]\nstages: [test, deploy]\n" > "$GITLAB_EXISTING/.gitlab-ci.yml"
chmod 644 "$GITLAB_EXISTING/.gitlab-ci.yml"
"$ROOT/scripts/install-pr-review.sh" openai "$GITLAB_EXISTING" >/dev/null
grep -q '.gitlab/ci/base.yml' "$GITLAB_EXISTING/.gitlab-ci.yml"
test "$(grep -c '.gitlab/ci/shipframe-review.yml' "$GITLAB_EXISTING/.gitlab-ci.yml")" = 1
test "$(grep -c '^include:' "$GITLAB_EXISTING/.gitlab-ci.yml")" = 1
grep -q 'project: group/central' "$GITLAB_EXISTING/.gitlab-ci.yml"
if command -v ruby >/dev/null 2>&1; then ruby -e 'require "yaml"; YAML.load_file(ARGV[0])' "$GITLAB_EXISTING/.gitlab-ci.yml"; fi
test "$(grep -c '^shipframe-ai-mr-review:' "$GITLAB_EXISTING/.gitlab-ci.yml")" = 1
test "$(stat -f '%Lp' "$GITLAB_EXISTING/.gitlab-ci.yml")" = 644
"$ROOT/scripts/manage-gitlab-ci-include.py" --remove "$GITLAB_EXISTING/.gitlab-ci.yml"
grep -q '.gitlab/ci/base.yml' "$GITLAB_EXISTING/.gitlab-ci.yml"
! grep -q 'shipframe-ai-mr-review\|.gitlab/ci/shipframe-review.yml' "$GITLAB_EXISTING/.gitlab-ci.yml"

# Inline mapping and empty flow-list include forms stay valid after extension.
for inline in "{ local: .gitlab/ci/base.yml }" "[]"; do
  INLINE_INCLUDE="$TMP/gitlab-inline-include-${RANDOM}"
  make_repo "$INLINE_INCLUDE" "https://gitlab.com/group/inline-include.git"
  printf 'include: %s\n' "$inline" > "$INLINE_INCLUDE/.gitlab-ci.yml"
  "$ROOT/scripts/install-pr-review.sh" nan-builders "$INLINE_INCLUDE" >/dev/null
  test "$(grep -c '^include:' "$INLINE_INCLUDE/.gitlab-ci.yml")" = 1
  if command -v ruby >/dev/null 2>&1; then ruby -e 'require "yaml"; YAML.load_file(ARGV[0])' "$INLINE_INCLUDE/.gitlab-ci.yml"; fi
done

EMPTY_INCLUDE="$TMP/gitlab-empty-inline-include"
make_repo "$EMPTY_INCLUDE" "https://gitlab.com/group/empty-inline-include.git"
printf 'include: []\nstages: [test]\n' > "$EMPTY_INCLUDE/.gitlab-ci.yml"
"$ROOT/scripts/install-pr-review.sh" nan-builders "$EMPTY_INCLUDE" >/dev/null
"$ROOT/scripts/manage-gitlab-ci-include.py" --remove "$EMPTY_INCLUDE/.gitlab-ci.yml"
! grep -q '^include:' "$EMPTY_INCLUDE/.gitlab-ci.yml"
grep -q '^stages:' "$EMPTY_INCLUDE/.gitlab-ci.yml"
if command -v ruby >/dev/null 2>&1; then ruby -e 'require "yaml"; YAML.load_file(ARGV[0])' "$EMPTY_INCLUDE/.gitlab-ci.yml"; fi

# Unsupported multiline flow YAML is refused before any reviewer file is created.
MULTILINE_INCLUDE="$TMP/gitlab-multiline-include"
make_repo "$MULTILINE_INCLUDE" "https://gitlab.com/group/multiline-include.git"
cat > "$MULTILINE_INCLUDE/.gitlab-ci.yml" <<'YAML'
include: [
  '.gitlab/ci/base.yml',
  { project: group/central, file: shared.yml },
]
stages: [test]
YAML
cp "$MULTILINE_INCLUDE/.gitlab-ci.yml" "$TMP/multiline-before.yml"
if "$ROOT/scripts/install-pr-review.sh" nan-builders "$MULTILINE_INCLUDE" >/dev/null 2>&1; then
  echo 'multiline flow include unexpectedly accepted' >&2
  exit 1
fi
cmp -s "$TMP/multiline-before.yml" "$MULTILINE_INCLUDE/.gitlab-ci.yml"
test ! -e "$MULTILINE_INCLUDE/.gitlab/ci/shipframe-review.yml"

# Respect an existing workflow gate instead of silently making MRs unrunnable.
BLOCKED="$TMP/gitlab-workflow-blocked"
make_repo "$BLOCKED" "https://gitlab.com/group/blocked.git"
printf 'workflow:\n  rules:\n    - if: "$CI_COMMIT_BRANCH"\n' > "$BLOCKED/.gitlab-ci.yml"
if "$ROOT/scripts/install-pr-review.sh" nan-builders "$BLOCKED" >/dev/null 2>&1; then
  echo 'incompatible workflow unexpectedly accepted' >&2
  exit 1
fi
test ! -e "$BLOCKED/.gitlab/ci/shipframe-review.yml"

COMMENTED_EVENT="$TMP/gitlab-workflow-comment"
make_repo "$COMMENTED_EVENT" "https://gitlab.com/group/commented-event.git"
printf 'workflow:\n  rules:\n    - if: "$CI_COMMIT_BRANCH" # merge_request_event is not enabled here\n' > "$COMMENTED_EVENT/.gitlab-ci.yml"
if "$ROOT/scripts/install-pr-review.sh" nan-builders "$COMMENTED_EVENT" >/dev/null 2>&1; then
  echo 'comment-only workflow event unexpectedly accepted' >&2
  exit 1
fi
test ! -e "$COMMENTED_EVENT/.gitlab/ci/shipframe-review.yml"

for invalid_workflow in name_only denied_rule; do
  INVALID_WORKFLOW="$TMP/gitlab-workflow-$invalid_workflow"
  make_repo "$INVALID_WORKFLOW" "https://gitlab.com/group/$invalid_workflow.git"
  if [ "$invalid_workflow" = name_only ]; then
    printf 'workflow:\n  name: "merge_request_event"\n  rules:\n    - if: "$CI_COMMIT_BRANCH"\n' > "$INVALID_WORKFLOW/.gitlab-ci.yml"
  else
    printf 'workflow:\n  rules:\n    - if: "$CI_PIPELINE_SOURCE == \\\"merge_request_event\\\""\n      when: never\n' > "$INVALID_WORKFLOW/.gitlab-ci.yml"
  fi
  if "$ROOT/scripts/install-pr-review.sh" nan-builders "$INVALID_WORKFLOW" >/dev/null 2>&1; then
    echo "unsafe workflow unexpectedly accepted: $invalid_workflow" >&2
    exit 1
  fi
  test ! -e "$INVALID_WORKFLOW/.gitlab/ci/shipframe-review.yml"
done

INLINE_BLOCKED="$TMP/gitlab-inline-workflow"
make_repo "$INLINE_BLOCKED" "https://gitlab.com/group/inline-workflow.git"
printf 'workflow: { rules: [{ if: "$CI_COMMIT_BRANCH" }] }\n' > "$INLINE_BLOCKED/.gitlab-ci.yml"
if "$ROOT/scripts/install-pr-review.sh" nan-builders "$INLINE_BLOCKED" >/dev/null 2>&1; then
  echo 'inline incompatible workflow unexpectedly accepted' >&2
  exit 1
fi

COLLISION="$TMP/gitlab-job-collision"
make_repo "$COLLISION" "https://gitlab.com/group/job-collision.git"
printf 'shipframe-ai-mr-review: { script: [echo existing] }\n' > "$COLLISION/.gitlab-ci.yml"
if "$ROOT/scripts/install-pr-review.sh" nan-builders "$COLLISION" >/dev/null 2>&1; then
  echo 'inline job collision unexpectedly accepted' >&2
  exit 1
fi

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
