---
type: plan
status: active
created: 2026-08-06
updated: 2026-08-06
contract: CR-20260805235233-29894-26025
---

# Context usage meter

## Contract

- **Goal:** show exact last-known Codex context occupancy on every `UserPromptSubmit`.
- **Constraints:** upstream only; no plugin-cache edits; metadata allowlist; no secrets or content;
  tests authored before code by a different model; no dependency or external mutation.
- **Inputs:** `$CODEX_THREAD_ID`; structural token/compaction events in that thread's rollout.
- **Outputs:** one bounded status line for hooks and one JSON status for diagnostics.
- **Done when:** wrong-thread, stale, truncated, archive-rotation, transition, threshold, cumulative,
  subset-double-counting, and secret-canary fixtures pass; seeded defects turn the suite red; both
  generated host adapters wire the hook; a fresh nested Codex task displays a correct live value.

## Approaches considered

1. Add parsing to `route-request.sh`: few files, but couples routing to sensitive telemetry and
   makes both failure domains harder to test. Rejected.
2. Standalone shell plus `jq`: small, but adds a hook-time binary dependency and encourages broad
   deserialization of content-bearing JSONL. Rejected.
3. Standalone Python-stdlib meter plus its own hook entry: about 150 lines, no new dependency,
   metadata-only interface, independent timeout and tests. **Chosen.** Python must remain 3.9-safe.

## Operational bands

- `<50%`: green.
- `50-59.99%`: checkpoint.
- `60-69.99%`: finish the bounded slice and cross a fresh semantic boundary.
- `>=70%`: emergency persistence; do not load another large evidence batch.

These are reasoning-continuity controls, not predictions of a native threshold. Observed native
compactions were 89.74% and 91.76%.
