# Tear Down: KERNEL 8.1.4 Stop hook

reviewed: 2026-07-15T21:45:00Z
tier: 3
scope: 7 source/release files plus installed-payload verification

## Big 5

input_validation: pass — no new external input parser
edge_cases: pass with action — cover absent SessionEnd, manual sweep availability, install, upgrade, and current-session stale registration
error_handling: pass — removal deletes an unbounded failure path
duplication: pass — one canonical manifest remains
complexity: pass — net deletion

## Security

pass — removes automatic network and remote-write behavior from an ambient hook; no secrets or
authentication changes.

## Testing

Existing tests incorrectly require SessionEnd and enumerate it in cross-loader expectations.
Change those assertions before release. Exercise both source manifest parsing and one freshly
installed Codex payload.

## Architecture

Removing the shared lifecycle registration is preferable to loader sniffing inside the script.
The manual sweep primitive may remain, but no ambient hook should own the explicit push boundary.

## Verdict: PROCEED

Proceed with the net-deletion approach. Release is blocked until the old positive SessionEnd tests
are replaced, the full suite passes, and a marketplace-installed 8.1.4 payload completes a real
Codex Stop boundary.

## Action Items

1. Remove SessionEnd registration from `hooks/hooks.json`.
2. Replace positive SessionEnd tests with negative lifecycle-autopush tests.
3. Verify all enumerated docs/fixtures no longer promise automatic end-of-session push.
4. Run the full ship sequence and installed-payload proof.
