# Tear Down: issue 244 hook parity
reviewed: 2026-09-03
tier: 2
scope: 3 files

## Big 5
input_validation: pass
edge_cases: pass
error_handling: pass
duplication: pass
complexity: pass

## Verdict: PROCEED
Canonical bindings generate the shared manifest. Exact retained set plus executable parity prevents missing commands.

## Action Items
1. Remove retired bindings from `scripts/generate-adapters.py`.
2. Regenerate `hooks/hooks.json`.
3. Require every bound path to be a shipped executable.
