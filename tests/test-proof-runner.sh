#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skill="$repo_root/skills/proof-runner/SKILL.md"

[[ -f "$skill" ]]

grep -q '^name: proof-runner$' "$skill"
grep -q 'Default to dry-run' "$skill"
grep -q 'Verify:' "$skill"
grep -q 'exits with status `0`' "$skill"
grep -q 'missing `Verify:` as unverifiable' "$skill"
grep -q 'Needs separate approval' "$skill"

fixture="$(mktemp)"
trap 'rm -f "$fixture"' EXIT
cat > "$fixture" <<'MD'
- [ ] Successful local check
  Verify: `true`
- [ ] Failing local check
  Verify: `false`
- [ ] Missing command
MD

python3 - "$fixture" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding='utf-8')
items = []
current = None
for line in text.splitlines():
    match = re.match(r'^[-*] \[[ xX]\] (.+)$', line)
    if match:
        current = {'title': match.group(1), 'verify': None}
        items.append(current)
        continue
    verify = re.search(r'Verify:\s*`([^`]+)`', line)
    if verify and current:
        current['verify'] = verify.group(1)

assert len(items) == 3
assert items[0]['verify'] == 'true'
assert items[1]['verify'] == 'false'
assert items[2]['verify'] is None

statuses = []
for item in items:
    if item['verify'] is None:
        statuses.append('unverifiable')
    elif item['verify'] == 'true':
        statuses.append('passed')
    else:
        statuses.append('failed')

assert statuses == ['passed', 'failed', 'unverifiable']
PY

echo "test-proof-runner ok"
