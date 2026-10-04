#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/project with spaces"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" config user.name Test
git -C "$REPO" config user.email test@example.invalid
export HOME="$TMP/home"
mkdir -p "$HOME"

state(){ bash "$ROOT/skills/project-memory-init/scripts/project-memory-state.sh" "$1" "$REPO"; }

[ "$(state status)" = "unconfigured" ]
state decline
[ "$(state status)" = "declined" ]
state enable
[ "$(state status)" = "enabled" ]
state reset
[ "$(state status)" = "unconfigured" ]
[ -z "$(git -C "$REPO" config --global --get shipframe.memory.setup 2>/dev/null || true)" ]

if bash "$ROOT/skills/project-memory-init/scripts/project-memory-state.sh" status "$TMP" >/dev/null 2>&1; then
  echo "Expected non-repository state lookup to fail" >&2
  exit 1
fi

echo "project-memory state tests passed"
