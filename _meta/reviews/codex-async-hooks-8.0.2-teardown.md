# Tear Down: Codex async hooks compatibility for 8.0.2

reviewed: 2026-07-11T10:02:00-07:00
tier: 3
contract: CR-20260711092844-32094-8833
scope: 3 required implementation files, release metadata handled by parent contract

## Evidence

- Codex CLI `0.144.1` emits one startup warning for every hook object containing
  `"async": true` and skips that hook entirely.
- Claude Code `2.1.207` accepts the same shared `hooks/hooks.json` format.
- A disposable local marketplace was installed into an isolated `CODEX_HOME` with
  all `async` keys removed. A real interactive Codex startup loaded and trusted all
  13 hooks without any async warning.
- Direct 20-run timings on macOS:
  - `validate-structure.sh`: 0.19 s total (~10 ms/call)
  - `warn-hardcoded.sh`: 0.32 s total (~16 ms/call)
  - `log-write.sh`: 1.06 s total (~53 ms/call, including its current detached emit)
  - `validate-json-schema.sh`: 0.18 s total (~9 ms/call)
  - `capture-error.sh`: 7.12 s total (~356 ms/call; failure path only)
  - synchronous AgentDB hook emit alone: 0.31 s/10 (~31 ms/call)
- The six affected scripts already consume stdin themselves. Adding a dispatch
  wrapper would require buffering and replaying the exact payload and would create
  the child-lifetime/temporary-file race this change is supposed to eliminate.

## Approaches considered

### A. Remove `async` and execute the existing scripts synchronously (recommended)

One shared manifest, no wrapper, no temporary payload, no detached hook process.
The common Write/Edit path adds roughly 100 ms for all advisory checks together.
`capture-error` is slower but runs only after a failed tool. `autopush install` is
normally an immediate no-op because it is opt-in.

Required hardening: remove the inner `&` from `log-write.sh` so the hook really has
one lifetime, and make the AgentDB timing emit explicitly advisory (`|| true`).
Keep each hook script unconditionally exiting zero. Preserve critical synchronous
guards byte-for-byte.

### B. Remove `async` and add a generic detach/background wrapper

Rejected. The wrapper must read all stdin before returning, store or pipe it to a
child, detach file descriptors, survive parent cleanup, clean temporary files, and
still surface warnings. `nohup`, `disown`, or `setsid` availability differs across
macOS/Linux, and success would only prove launch, not completion. It is substantially
more code and directly conflicts with the no-child-race requirement.

### C. Maintain separate Claude and Codex hook manifests

Rejected for 8.0.2. Both clients currently discover the same plugin hook component;
there is no validated client selector in the shared marketplace metadata. Two files
would add a drift-prone release surface without a proven loader path.

## Big 5

input_validation: pass with required dual-loader payload tests
edge_cases: pass with required empty/malformed payload and missing dependency tests
error_handling: pass only if all six advisory paths always exit zero
duplication: pass; no wrapper or duplicate manifest
complexity: pass; deletion plus one background-removal change

## Security and architecture

- Critical synchronous guards (`guard-bash`, `guard-config`, `detect-secrets`,
  `guard-context`) must not change.
- Synchronous advisory checks cannot be allowed to become accidental denial gates.
- Existing payload inconsistency is a latent cross-client bug: `log-write.sh` reads
  `.tool_input.file_path`, while three other scripts prefer only top-level
  `.file_path`. Tests must use one real Claude-shaped fixture and one real
  Codex-shaped fixture and assert non-empty inspected values, not merely exit zero.
- No new dependency is justified.

## Verdict: PROCEED

Proceed with Approach A. This is the smallest design, actually runs every behavior
in Codex, keeps Claude latency bounded, preserves stdin naturally, and eliminates
rather than relocates hook-child cleanup races.

## Exact bounded implementation files

1. `hooks/hooks.json`
   - remove exactly six `async` keys; do not alter critical hook commands/matchers.
2. `hooks/scripts/log-write.sh`
   - update stale async comments; execute timing emit synchronously and tolerate its
     failure; leave the primary actions log append advisory.
3. `tests/run-tests.sh`
   - regression: no `async` key anywhere in shared hook manifest.
   - regression: all six commands remain registered and execute.
   - Claude- and Codex-shaped stdin fixtures assert file/tool/content/error values
     are actually consumed.
   - every advisory script returns zero for valid, empty, malformed, missing-file,
     missing-AgentDB, and unwritable-log scenarios.
   - process check: no descendant remains after `log-write.sh` exits.
   - real disposable Codex marketplace smoke (bounded/optional when binary absent)
     confirms startup output contains no `skipping async hook`.

Release-only metadata/version/docs may be changed by the parent release contract,
not by this implementation lane.

## Failure conditions

1. Any `async` key remains in the shipped shared manifest.
2. Any of the six behaviors is removed or skipped rather than executed.
3. Payload data is empty under either client fixture.
4. An advisory hook exits nonzero, times out, or blocks the tool operation.
5. A child process survives hook exit or a temporary stdin payload is raced/removed.
6. Critical guard definitions change.
7. Normal Write/Edit advisory latency exceeds 250 ms p95 on the release machine, or
   the failure-only hook exceeds its five-second timeout.
8. Actual Codex 0.144.1 startup still prints an async-hook warning.
