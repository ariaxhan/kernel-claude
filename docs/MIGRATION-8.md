# KERNEL 8.0 — the unified skill architecture

KERNEL 8.0 removes the commands layer. Every kernel operation is now a **skill**, and
JSON manifests are the canonical machine-readable representation of resumable state.

## What changed for you: almost nothing

Every invocation you know still works, verbatim:

```
/kernel:ingest    /kernel:forge      /kernel:validate    /kernel:handoff
/kernel:dream     /kernel:diagnose   /kernel:review      /kernel:tearitapart
/kernel:metrics   /kernel:retrospective   /kernel:experiment   /kernel:init
/kernel:help      /kernel:landing-page
```

Claude Code merged custom commands into skills upstream; a plugin skill at
`skills/ingest/SKILL.md` surfaces as `/kernel:ingest` exactly like the old
`commands/ingest.md` did. KERNEL 8.0 completes that merge on our side: one primitive,
no parallel systems, **no aliases needed because the names never changed**.

New in 8.0: `/kernel:checkpoint` — the small resumable manifest (see below).

## What actually changed

### 1. One taxonomy, machine-readable

Every skill carries a kernel-owned frontmatter block:

```yaml
kernel:
  kind: methodology | workflow | state_transition | validator | operator
  version: 1
  side_effects: none | writes_meta | writes_repo | writes_remote | deploys
  confirmation: none | on_side_effect | always
  produces: [kernel.handoff/v1]     # state transitions declare their manifests
  consumes: [kernel.handoff/v1, kernel.checkpoint/v1]
```

Claude Code ignores unknown frontmatter keys; kernel's own test suite validates them.
Side-effecting skills (`forge`, `init`, `experiment`, `landing-page`) carry
`disable-model-invocation: true` — they can never fire ambiently, only when you type them
(test-enforced).

### 2. JSON-first state (the four state operations)

| operation | emits | purpose |
|---|---|---|
| `/kernel:handoff` | `_meta/handoffs/*.json` (`kernel.handoff/v1`) | full session transfer: provenance, decisions, phases, context policy + budget |
| `/kernel:checkpoint` | `_meta/checkpoints/*.json` (`kernel.checkpoint/v1`) | bounded mid-task save: steps done (with evidence), exact resume position |
| `/kernel:ingest` | `_meta/reports/receipt-*.json` (`kernel.context-receipt/v1`) | unified entry; validates + resumes manifests, compiles bounded context |
| `/kernel:retrospective` | `_meta/reports/retrospective-*.json` (`kernel.retrospective-result/v1`) | learning synthesis + machine-readable infrastructure mutation record |

The JSON file is canonical. YAML/markdown renderings are annotated
`RENDERED FROM <json> — NOT AUTHORITATIVE`.

**Legacy markdown handoffs** (`_meta/handoffs/*.md`) are still readable by
`/kernel:ingest` in 8.x, flagged deprecated (no validation, no divergence detection, no
budget). They stop being read in 9.0. Regenerate important ones with `/kernel:handoff`.

### 3. The manifest runtime

`orchestration/manifest/kernel-manifest` (python3; stdlib JSON parsing, duplicate keys rejected
to system ruby; with neither, validation fails LOUDLY — a sealed resume treats that as
blocking):

```
kernel-manifest validate   <file>    # schema check
kernel-manifest latest               # newest manifest (checkpoints + handoffs)
kernel-manifest divergence <file>    # live git state vs manifest provenance
kernel-manifest divergence <file> --json # typed events + recalculated phases
kernel-manifest preflight  <file>    # typed, non-shell resume checks
kernel-manifest compile    <file>    # resolve context selectors -> bundle + receipt
kernel-manifest resume     <file>    # print the re-entry point
kernel-manifest activate   <file>    # arm the context policy (writes hook pointer)
kernel-manifest deactivate           # merge ledger into receipt, disarm
```

**Authority order on resume:** live verified repository state > explicit user
instruction > manifest > chronicle > inferred conversation history. Divergence
(branch/commit/pinned-artifact-hash) flips inherited workflow phases back to `required`
per the manifest's `invalidation_rules`.

### 4. Context policies — manifests feed hooks, hooks feed receipts

```yaml
context:
  policy:
    mode: sealed | bounded | advisory
```

- **sealed** — `context.forbidden` globs are BLOCKED by the `guard-context.sh`
  PreToolUse hook while the manifest is active. For controlled experiments where
  contaminating context invalidates the run. Fails closed: unreadable pointer or missing
  parser = block.
- **bounded** — everything allowed, but loads beyond the manifest are ledgered to
  `_meta/.context-ledger` and merged into the receipt's `loads_beyond_manifest` at
  deactivate. You justify them or they show up unexplained.
- **advisory** — guidance only, no enforcement.

### 5. Context selectors + receipts

Manifests request context by **selector**, not whole files:

```yaml
required:
  - {path: docs/design.md, heading: "## Decisions"}
  - {path: src/db.py, lines: "40-95"}
  - {path: tests/run-tests.sh, grep: "PLUGIN_ROOT/commands", context: 2}
  - {git_diff: "main..HEAD"}
```

`compile` emits a `kernel.context-receipt/v1`: estimated tokens per layer (manifest,
project instructions, skills, selected artifacts), budget status
(`within_budget | target_exceeded | maximum_exceeded`). Estimates are chars/4 —
directional, and the receipt says so.

**Why**: EXP-L21 measured that what a decision needs stays flat (~50-70k tokens) while
an accumulating transcript forces attention over 7-11x that by late session (median
attention efficiency 18.6%, decaying to ~11%). Resumes reconstruct bounded state; they
do not inherit conversations. Deferred to a later release: json-path/symbol
selectors, rerun-verified (EXP-L21b) selector quality, boot-layer slimming.

### 6. The experiment collision, resolved

`commands/experiment.md` (autonomous engine) and `skills/experiment/SKILL.md`
(methodology) merged into ONE `skills/experiment/SKILL.md`: the engine is the body, the
falsifiability gates / lifecycle transitions / anti-patterns are integrated at the
phases that use them. Same `/kernel:experiment` invocation; explicit-only.

## Smoke tests (things unit tests can't prove)

Run these in a live Claude Code session after updating:

1. `/kernel:` <kbd>tab</kbd> — all former commands + `checkpoint` appear as skills.
2. `/kernel:help` — renders the unified reference, no stale "commands" table.
3. `/kernel:handoff` on a real task — emits `.json`, and
   `kernel-manifest validate` passes on it.
4. `/kernel:ingest` in a repo with a manifest — reports "Resuming {manifest}" with a
   receipt line, not a prose re-read of the old session.
5. Edit a SKILL.md mid-session — change takes effect without restart (upstream hot-reload).
6. Say something forge-adjacent WITHOUT typing `/kernel:forge` — it must NOT auto-fire
   (`disable-model-invocation`).

## The tradition boundary (unchanged, now documented)

Kernel and tradition remain separate layers:

- **kernel** defines skills, contracts, manifests, state transitions, validation, and
  bounded runtime assembly. Kernel never requires tradition to function.
- **tradition** (the vault layer) is higher-order execution: commissions, recurrence,
  evaluation, chronicles. Tradition may invoke kernel skills and adopt kernel contracts.

```
tradition run
  → commission                (high-level work mandate)
    → execution contract      (_meta/contracts/, binding)
      → kernel skills         (workflow/state_transition/validator/operator)
        → handoff/checkpoint manifests   (kernel.handoff/v1, kernel.checkpoint/v1)
          → validated runtime actions    (receipts, guard-context enforcement)
```

## For plugin developers

- `plugin.json` no longer has a `"commands"` key; `skills/` auto-discovers.
- New skills follow `docs/skill-template.md` (includes the `kernel:` block).
- Never commit `_meta/.active-manifest.json` or `_meta/.context-ledger` (gitignored
  runtime state).
