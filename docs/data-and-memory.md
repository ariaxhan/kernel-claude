# What KERNEL writes, and how recall works

KERNEL keeps durable data in the selected Vaults, found in this order: valid
`KERNEL_VAULTS`, `~/Documents/Vaults`, `~/Vaults`, then `~/Downloads/Vaults`.

- `_meta/agentdb/agent.db`: project memory, contracts, checkpoints, verdicts, and telemetry.
- `_meta/handoffs/`, `_meta/checkpoints/`, `_meta/retrospectives/`, and receipts: JSON state
  artifacts.
- `_meta/agents/`, `_meta/logs/`, and small session-status files: runtime records.
- `.claude/kernel/` and `.local/bin/agentdb`: links created only by explicit setup; startup
  only repairs recognized old numbered KERNEL links.

## Semantic recall (8.3.0, optional)

By default `agentdb recall` is FTS5 keyword search. Run `agentdb embed-init` once to add
local semantic search: it creates a venv beside the DB, installs `fastembed` (ONNX
all-MiniLM-L6-v2, ~50MB, no torch, fully on-machine, nothing leaves your computer), embeds
your learnings, and prints an `AGENTDB_EMBED_PYTHON` export to make it permanent. Recall then
fuses keyword bm25 with cosine similarity (reciprocal-rank fusion) and surfaces learnings
whose wording differs from your query. On a real 47-learning corpus this lifted recall@5 from
0.75 to 0.85 with no regressions. Install nothing and recall stays exactly as before:
semantic search is strictly additive and opt-in. The embedding vectors are derived data, so
they are excluded from the tracked JSON mirror and rebuilt with `agentdb embed-sync` on a
fresh clone. Measure retrieval quality yourself with
`orchestration/agentdb/eval/run_eval.py` against a gold set.

## Lean session start (8.4.0)

Because recall is task-driven, the SessionStart context is lean: a learning count, an
`agentdb recall` pointer, and the top few highest-hit failures, about 950 tokens, down from
~3,700 when startup dumped ~50 task-blind learnings every session. The agent recalls what its
task needs instead of receiving everything up front. Recall with concrete nouns: feature plus
subsystem or library, plus discovered files and symbols, plus the exact error or desired
outcome. Run it again after discovery, when scope or hypothesis changes, or when a new
failure appears. Run `agentdb read-start` explicitly (no flag) only when you want the full
weighted memory dump.

## Learning graph and promotion (8.5.1)

With embeddings present, `agentdb graph build` connects related learnings (semantic cosine
plus `[[links]]`) into a `learning_edges` table; `agentdb graph neighbors <id>` shows a
learning's related lessons. `agentdb promote` clusters recurring failures and surfaces
candidate doctrine themes for review; it never auto-writes doctrine. The edges are derived
data, excluded from the JSON mirror and rebuilt by `graph build`, like the embeddings.

## Hooks and external tools

KERNEL hooks can inspect repository state, run configured checks, and write these records.
Claude Code runs the full declared lifecycle. Codex runs supported synchronous hook events,
including the write guards and SessionStart context; it skips asynchronous command hooks and
has no plugin SessionEnd event, so end-of-session recording in Codex must be invoked
explicitly with `$kernel:handoff`. Some workflows can use GitHub when the project profile
enables it. KERNEL does not promise that all processing stays local when you invoke a
workflow that uses external tools. Review host permissions and the repository's own
instructions before granting access.

KERNEL 8.0.2 declares its six advisory hooks as synchronous so Codex executes them instead of
skipping them. They remain non-blocking in outcome: an internal logging or validation failure
returns success and cannot reject the tool operation. The critical secret, configuration,
command, and context guards remain separate blocking gates.

When the active project root exactly matches the Vaults root and the shared continuity engine
plus an executable Claude or Codex adapter are present, that Vaults service owns compaction
checkpoints and restore injection. KERNEL's PreCompact and PostCompact paths cleanly no-op
there; SessionStart still supplies AgentDB and governance without adding a second restore.
Nested repositories retain KERNEL's deterministic generic fallback. Merely finding continuity
files above the active project does not disable KERNEL.
