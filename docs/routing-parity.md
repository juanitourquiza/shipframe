# Routing parity contract

`routing.json` is the canonical intent-to-workflow contract. The README, Codex workflow, and Claude/OpenCode orchestrator may use host-native agent names, but their ordered steps must normalize to the same contract.

## Schema

- `schemaVersion` identifies the routing metadata contract.
- `aliases` maps canonical skill steps to equivalent native agent names; it does not imply a different sequence.
- `host_variants` records an intentional host-specific orchestrator path when one native agent wraps multiple canonical skills. `expands_to` declares the canonical workflow that the wrapper promises to cover, and the parity test compares it to the intent route.
- `qa_gate.tokens` are alternate names for one logical QA step. The parenthetical eligibility condition remains part of the contract and is checked separately.
- `→` means ordered steps; `·` means alternatives, not a mandatory chain.

When adding or changing an intent, update its canonical route, any documented host variant, the Codex workflow and README tables, and the orchestrator route. Keep meaningful conditions (such as QA eligibility and “if fixes are requested”) intact.

## Verification

Run `node tests/test-routing-parity.js` after every routing edit and `python3 scripts/check-contracts.py` to validate schema metadata and agent/skill targets. The test checks order, aliases, QA-gate collapse, host variants, conditions, and document parity; it does not prove that a CLI actually executed a subagent.
