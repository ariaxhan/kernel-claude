# Tear Down: PR 145 — yaml-skill-unification manifest runtime
reviewed: 2026-07-10
tier: 3
scope: orchestration/manifest/kernel-manifest, hooks/scripts/guard-context.sh, schemas/*.json, _meta/handoffs/yaml-skill-unification-2026-07-10.yaml, tests/run-tests.sh

## Verification of the 20-finding review (empirical, against working tree)

### Confirmed — release-blocking
- **F0 (new): the hardening fixes are NOT committed.** 332 lines of uncommitted diff on
  kernel-manifest, guard-context.sh, run-tests.sh. PR 145 as pushed contains none of the
  fixes the session summary claims. Evidence: `git diff --stat HEAD` = 332 insertions.
- **F9 duplicate keys / parser lottery: CONFIRMED, live on this machine.** pyyaml is not
  installed here; the runtime silently uses the ruby psych bridge, which last-wins duplicate
  keys (`a: 1\na: 2` → `{"a":2}`). A manifest can display `mode: sealed` and parse as
  `advisory`. The canonical format's meaning depends on machine config.
- **F10 cwd-relative paths: CONFIRMED, worse than claimed.** Running `divergence` from
  `skills/` reports both pinned artifacts as *missing* → hard divergence from a subdirectory,
  CLEAN from repo root. Same manifest, two verdicts. All paths (selectors, artifacts,
  ACTIVE_POINTER, ledger, latest dirs) resolve against `os.getcwd()`.
- **F18 latest = mtime: CONFIRMED.** A byte-identical copy in another scanned dir wins
  `latest` immediately. No validation, no `identity.created`, no lineage, no branch check.
- **F13 budgets unvalidated: CONFIRMED.** `target_tokens: -500, max_tokens: -1` → VALID,
  exit 0. Schema has no minimum, no target≤max constraint. `max_tokens: 0` means "no max"
  via truthiness.
- **F6 invalidation rules are prose: CONFIRMED by code.** `cmd_divergence` prints
  human-readable lines and exits 1; no structured events, no phase recalculation. Trigger
  strings ("branch diverged", "artifact hash mismatch: X") are matched by model judgment.
- **F8 preflight = arbitrary shell: CONFIRMED by schema + manifest.** `runtime.preflight[].cmd`
  is an unconstrained string the resuming agent is instructed to execute. A manifest is an
  executable script crossing a session trust boundary.
- **F14/F15 receipt integrity: CONFIRMED by code.** No content hashes anywhere in the
  receipt; bounded-mode ledger logs EVERY post-activation read (no allowlist of compiled
  bundle paths) with hardcoded reason "unstated"; deactivate copies entries verbatim.
- **F19 checkpoints pin nothing: CONFIRMED by schema.** provenance = branch/commit/dirty
  only; `current_outputs` are bare strings; two different dirty trees both satisfy
  `dirty: true`.

### Confirmed — important, not necessarily blocking
- **F11 selector precedence silent** (git_diff > lines > heading > grep; extras ignored).
- **F12 hollow resolution: CONFIRMED empirically.** `lines: "30-10"` → `resolved: true,
  estimated_tokens: 0`. Success = `content is not None`, not "produced intended content".
- **F16 token accounting overclaims** (only ./CLAUDE.md + ./.claude/CLAUDE.md counted —
  and the real chain includes user-level + parent-dir files; receipt narration should say so).
- **F17 skill pins decorative** (`skill_tokens` uses name only; version/sha256 never checked).

### Refuted / already fixed (in the uncommitted working tree)
- **F7 stale flagship handoff: REFUTED locally.** Pinned schema sha 4e264e… MATCHES the
  file on disk; `divergence` from repo root = CLEAN (commit ADVANCED is allowed; dirty is
  WARN-only). The reviewer likely compared against a different blob. Their suggested test
  (run validate+divergence against final head in CI) is still worth adding.
- **F20 lifecycle cleanup: mostly fixed.** `deactivate` now dies before removing state when
  projection fails. Residual: a failed projection after a successful ledger merge leaves the
  ledger in place → re-running deactivate re-merges duplicate entries.
- Unknown-key rejection works (`entry_phasee` → INVALID). Required-selector fail-closed
  (exit 4) works. Both uncommitted.

## Big 5
input_validation: fail (budgets, selector combinations, preflight cmd strings)
edge_cases: fail (reversed ranges, cwd sensitivity, mtime hijack, empty-resolve)
error_handling: partial (fail-closed improved; malformed grep regex still uncaught)
duplication: pass
complexity: pass (534-line runtime, readable)

## Format ruling: drop the YAML parse chain — canonical JSON, YAML as render only

The manifests are machine-written (by handoff/checkpoint skills) and machine-read (by
kernel-manifest + hooks). Nobody hand-authors them. That removes the only argument for YAML
as the canonical layer. Meanwhile YAML is actively costing:
- parser lottery (pyyaml → ruby psych → exit 2) — the protocol's meaning depends on machine
  config, and on THIS machine the fallback path is the live path
- duplicate-key last-wins in both parsers
- scalar typing traps (all-digit shas parse as ints — already an AgentDB gotcha)
- a hand-rolled YAML emitter in kernel-manifest (emit_yaml/scalar ≈ 40 lines of liability)

JSON canonical fixes all four with zero dependencies: python stdlib `json` is always
present (kill the ruby bridge), `object_pairs_hook` rejects duplicate keys in ~3 lines,
no scalar coercion, `json.dumps(sort_keys=True)` gives byte-stable canonicalization for the
receipt/artifact hashing F14 needs. The repo already trusts this pattern (agent.db.json
mirror). Keep `.yaml` (or .md) as generated, non-authoritative renders if wanted.

## Verdict: REVISE
The migration (commands→skills) is coherent and can merge. The manifest runtime is a
yaml-authored prompt protocol presented as a machine-enforced one: enforcement-critical
transitions (invalidation, preflight, receipts) still run on model compliance. Do not ship
8.0 with the current claim. Either harden (below) or narrow the claim in CLAUDE.md/schemas
to "advisory state format, agent-interpreted" and ship the migration alone.

## Action items (ordered)
1. Commit + push the existing 332-line fix diff — PR 145 currently has none of it.
2. Canonical JSON: kernel-manifest parses JSON only (duplicate-key rejecting), drop ruby
   bridge + emit_yaml; manifests get .json; yaml/md become renders. (kills F9)
3. Anchor all paths to `git rev-parse --show-toplevel` once at startup. (kills F10)
4. Structured divergence: `--json` emitting typed events + machine-applied
   invalidation_rules (`when.event` + `path_glob` → recalculated phase statuses). (kills F6)
5. Typed preflight checks (current_branch/path_exists/argv allowlist), no raw shell
   strings in canonical state. (kills F8)
6. `latest`: validate candidates, order by identity.created, require branch match, prefer
   checkpoint lineage; ambiguity = report, not pick. (kills F18)
7. Budgets: minimum 1, target ≤ max, max required for sealed/bounded. (kills F13)
8. Receipts: manifest_sha256 + bundle_sha256 + per-selector resolved sha; compile writes a
   normalized allowlist into the pointer; ledger records only off-allowlist reads. (F14/F15)
9. Selector outcomes: resolved|empty|invalid|missing enum; exactly-one-source +
   at-most-one-refinement validation. (F11/F12)
10. Checkpoints: hash current_outputs or capture `git diff | sha256`. (F19)
11. Enforcement-owner annotation per schema field (x-kernel-enforced-by:
    divergence|compiler|hook|agent) so prose-enforced fields are visible.
12. CI test: validate + divergence of every committed manifest against checkout HEAD (F7's
    useful residue).
