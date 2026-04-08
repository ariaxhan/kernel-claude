# OSS Context Management Techniques — Source Code Analysis

**Date:** 2026-04-07
**Scope:** GitAgent, Claude-Mem, Git Context Controller
**Method:** Direct source code review via GitHub API

---

## 1. GitAgent (open-gitagent/gitagent)

**What it is:** A framework-agnostic standard for defining AI agents as git repositories. Not a memory tool per se — it's a *specification* for agent portability with memory as a first-class component.

### Memory Architecture

GitAgent defines a **layered memory system** via `memory/memory.yaml`:

```yaml
layers:
  - name: working        # Hot layer — active session state
    path: MEMORY.md
    max_lines: 200       # Hard cap prevents unbounded growth
    format: markdown
  - name: archive        # Cold layer — historical snapshots
    path: archive/
    format: yaml
    rotation: monthly    # Time-based rotation
update_triggers:
  - on_session_end
  - on_explicit_save
archive_policy:
  max_entries: 1000
  compress_after: 90d
  retention_period: 7y
```

**Key technique: Two-layer memory with hard line caps.**
- `MEMORY.md` is the hot layer (max 200 lines). This is the agent's working memory — always loaded.
- `archive/` is the cold layer with monthly rotation and compression after 90 days.
- Update triggers are declarative: `on_session_end`, `on_explicit_save`, `on_milestone`, `periodic`.

### Runtime Memory Structure

The specification defines `memory/runtime/` for live agent state:
- `dailylog.md` — Daily execution log
- `key-decisions.md` — Decision record
- `context.md` — Current working context

These are **git-tracked** (not gitignored), meaning memory is version-controlled and diffable.

### Lifecycle Hooks

```yaml
hooks:
  on_session_start:    # Load compliance context
  pre_tool_use:        # Audit trail
  post_tool_use:       # Validate output, PII check
  pre_response:        # Communications compliance
  post_response:       # Audit logging
  on_error:            # Escalation
  on_session_end:      # Seal audit log
```

Each hook has `timeout`, `compliance` flag, and `fail_open` (whether to proceed on hook failure).

### What kernel-claude doesn't do that GitAgent does

1. **Declarative memory layers with rotation policies.** Kernel's AgentDB is a single SQLite file with no archival/rotation.
2. **Hard line caps on working memory (200 lines).** Kernel has no enforced cap on what gets loaded.
3. **Monthly archive rotation with compression.** AgentDB grows unbounded.
4. **Git-tracked runtime state.** Kernel's `_meta/agentdb/agent.db` is binary and not meaningfully diffable.
5. **Schema-validated memory configuration.** GitAgent has `memory.schema.json` — kernel has no formal schema.

---

## 2. Claude-Mem (thedotmack/claude-mem)

**What it is:** A Claude Code plugin (v6.5.0) providing persistent memory across sessions via lifecycle hooks, a background worker service, and SQLite + ChromaDB storage.

### Architecture: The Pipeline

```
Hook (stdin) -> Database -> Worker Service -> Claude Agent SDK -> Database -> Next Session
```

**6 lifecycle hooks** (mapped to Claude Code hook events):
1. **SessionStart (context)** — Starts Bun worker, injects context from previous sessions
2. **UserPromptSubmit (session-init)** — Creates session in DB, saves raw user prompt for FTS5
3. **PostToolUse (observation)** — Captures every tool execution, sends to worker for AI compression
4. **PreToolUse/Read (file-context)** — Adds file context when reading
5. **Stop (summarize)** — Generates final session summary (120s timeout, queues + polls)
6. **SessionEnd (session-complete)** — Marks session complete

### Observation Capture (PostToolUse)

Every tool use is captured and sent to the worker:
```typescript
// From observation.ts
body: JSON.stringify({
  contentSessionId: sessionId,
  platformSource,
  tool_name: toolName,
  tool_input: toolInput,
  tool_response: toolResponse,
  cwd
})
```

The worker then uses the **Claude Agent SDK** to compress raw tool data into structured observations:

```xml
<observation>
  <type>[ bugfix | feature | exploration | ... ]</type>
  <title>Short descriptive title</title>
  <subtitle>One-line detail</subtitle>
  <facts>
    <fact>Concrete fact extracted</fact>
  </facts>
  <narrative>What happened and why it matters</narrative>
  <concepts>
    <concept>Semantic tag for retrieval</concept>
  </concepts>
  <files_read><file>path</file></files_read>
  <files_modified><file>path</file></files_modified>
</observation>
```

**Key insight:** The "compression" is AI-mediated summarization, not algorithmic compression. Raw tool I/O (potentially thousands of tokens) is distilled into a structured observation (~50-200 tokens). The `discovery_tokens` field tracks original size for economics reporting.

### Token Economics

```typescript
// From TokenCalculator.ts
const obsSize = (obs.title?.length || 0) +
                (obs.subtitle?.length || 0) +
                (obs.narrative?.length || 0) +
                JSON.stringify(obs.facts || []).length;
return Math.ceil(obsSize / CHARS_PER_TOKEN_ESTIMATE);
```

They track **read tokens** (compressed) vs **discovery tokens** (original) and report savings percentage. This enables the <$0.01/session claim — the context injection is small but the knowledge preserved is large.

### Context Injection (SessionStart)

```typescript
// From ContextBuilder.ts — orchestrates context generation
// 1. Load config
// 2. Query observations (filtered by type + concept)
// 3. Query session summaries
// 4. Build timeline (interleaved observations + summaries)
// 5. Render progressive layers
```

The context builder queries SQLite with **type filtering** (only certain observation types) and **concept filtering** (semantic tags), then renders a timeline with configurable observation counts.

### 3-Layer Progressive Disclosure for Search

```
search → timeline → get_observations
```
- Layer 1: Index only (~50-100 tokens/result)
- Layer 2: Chronological context around results
- Layer 3: Full details (~500-1000 tokens/result)

**10x token savings** by filtering before fetching.

### Summarization Flow (Stop Hook)

```typescript
// Queue summarize -> poll until complete (up to 110s)
// Worker processes via Claude Agent SDK
// Extracts: request, investigated, learned, completed, next_steps
```

The summary is a structured object with explicit `learned` and `next_steps` fields — not free-form text.

### What kernel-claude doesn't do that Claude-Mem does

1. **Automatic tool use observation.** Every PostToolUse is captured and compressed. Kernel only records what agents explicitly write to AgentDB.
2. **AI-mediated compression.** Raw tool I/O -> structured observations via Claude Agent SDK. Kernel has no compression pipeline.
3. **Token economics tracking.** Discovery tokens vs read tokens with savings %. Kernel tracks no token economics.
4. **Progressive disclosure search.** 3-layer retrieval (index -> timeline -> detail). Kernel's AgentDB is all-or-nothing queries.
5. **Background worker service.** Bun-managed HTTP API on port 37777 with SSE. Kernel has no background services.
6. **Concept-based retrieval.** Observations tagged with semantic concepts for filtered queries. AgentDB has no semantic tagging.
7. **Structured session summaries.** `request/investigated/learned/completed/next_steps`. Kernel's session-end writes free-form JSON.

---

## 3. Git Context Controller (faugustdev/git-context-controller)

**What it is:** A lean, git-backed context management system. Stores ~50 tokens per entry (hash + intent + optional decision note) instead of verbose markdown. Full context reconstructed on demand via `git show`. Published as arXiv paper.

### Core Data Structure: index.yaml

```yaml
version: 2
mode: git
config:
  proactive_commits: true
  worktree_ttl: 24h
  bridge_to_aiyoucli: auto

current_branch: main

timeline:
  - id: C001
    hash: 85c8539          # Pointer to git truth
    intent: "release prep"  # Why (human-readable)
    note: "descartamos semantic-release por overhead"  # Optional: decisions git can't capture
    branch: main
    date: "2026-02-25T21:40:00Z"

worktrees: []
decisions: []
```

**Key principle:** `hash` is the pointer to git truth. `intent` is why. `note` is only for decisions git can't capture (rejected alternatives, trade-offs).

### The 5 Scripts

**gcc_commit.sh** — Real git commit + lean index entry:
```bash
git add -u                        # Stage tracked changes
git commit -m "$INTENT_RAW"       # Real commit
HASH=$(git rev-parse --short HEAD)
# Append to index.yaml: { id, hash, intent, note, branch, date }
```

**gcc_context.sh** — Reconstruct context from hashes:
- `--summary`: One-line per entry from index.yaml (~0 extra tokens, zero git calls)
- `--last N`: Last N entries with `git show` reconstruction (~200 tokens/entry)
- `--hash <hash>`: Full diff for specific commit (variable)
- `--decisions`: Only entries with notes (decisions/trade-offs)
- `--full`: Everything

**gcc_bridge.sh** — Feed to vector memory (aiyoucli):
```bash
aiyoucli memory store \
  --key "gcc:$hash" \
  --value "$value" \
  --namespace "gcc" \
  --tags "commit,$branch" \
  --metadata "$metadata"
```
Silent no-op if aiyoucli unavailable. Fire-and-forget pattern.

**gcc_cleanup.sh** — TTL-based worktree cleanup + index pruning:
- Parses TTL from config (24h default)
- Checks for uncommitted changes before removing
- `--prune-index N` keeps last N entries (awk-based in-place edit)

**gcc_init.sh** — Auto-detects git/standalone, creates index.yaml.

### How It Achieves Context Efficiency

The 50-token-per-entry claim is real. Each timeline entry is:
```
id (4 chars) + hash (7 chars) + intent (~30 chars) + branch (~6 chars) + date (24 chars) = ~71 chars ≈ 18-25 tokens
```

Context reconstruction is **on-demand and graduated**:
- Quick orientation: `--summary` = ~0 extra cost
- Session recovery: `--last 5` = ~1000 tokens
- Deep dive: `--hash` = whatever the diff costs
- Decision review: `--decisions` = only annotated entries

### Worktree Isolation for Experimentation

GCC uses real git worktrees for branching experiments:
```bash
git worktree add ../gcc-wt-<name> -b <name>
# Register in index.yaml with TTL
# Agent works in worktree directory
# Merge back or cleanup on TTL expiry
```

This gives real filesystem isolation without branch switching in the main working tree.

### aiyoucli Bridge

Optional vector memory integration. Every commit can be auto-synced to a vector store with namespace `gcc` and tags for branch. Enables semantic search across commit history ("when did I do something similar?").

### What kernel-claude doesn't do that GCC does

1. **Git-as-truth with lean index.** GCC stores ~50 tokens per entry, reconstructs from git on demand. Kernel duplicates information in AgentDB.
2. **Graduated context reconstruction.** Summary -> last N -> specific hash -> decisions. Kernel has no graduated retrieval.
3. **Decision capture separate from commits.** The `note` field captures *rejected alternatives* and *trade-offs* — things git messages don't capture. Kernel's learnings are unstructured.
4. **TTL-based worktree management.** Automatic cleanup of expired experimental branches. Kernel has no worktree lifecycle management.
5. **Vector memory bridge.** Optional sync to external vector store for semantic search. Kernel has no vector search integration.
6. **Proactive commit suggestions.** Config flag `proactive_commits: true` triggers commit suggestions after milestones. Kernel doesn't prompt for commits.
7. **Index pruning.** `--prune-index N` keeps index bounded. AgentDB has no pruning.

---

## Cross-Project Synthesis

### Convergent Patterns (All 3 Projects)

1. **Tiered/graduated retrieval.** All three avoid loading everything. GitAgent: working vs archive layers. Claude-Mem: 3-layer progressive disclosure. GCC: summary -> last N -> hash -> full. This is the most validated pattern across projects.

2. **Structured over free-form.** All impose structure on memory: GitAgent uses schemas, Claude-Mem uses typed XML observations, GCC uses YAML timeline entries. None store raw text dumps.

3. **Bounded growth.** GitAgent: 200-line cap + archive rotation. Claude-Mem: configurable observation counts per context injection. GCC: index pruning. All prevent unbounded memory accumulation.

4. **Git as infrastructure.** GitAgent treats the repo as the agent. GCC uses git commits as the source of truth. Claude-Mem tracks per-project memories. Git is the universal substrate.

5. **Graceful degradation.** Claude-Mem returns empty context on worker failure. GCC silently skips bridge if aiyoucli missing. All prefer silent fallback over blocking.

### Unique Techniques Worth Adopting

| Technique | Source | Kernel Gap | Adoption Effort |
|-----------|--------|------------|-----------------|
| AI-mediated observation compression | Claude-Mem | No automatic capture or compression | High (needs background service) |
| Graduated context retrieval (5 levels) | GCC | All-or-nothing AgentDB queries | Medium (add query modes to agentdb) |
| Decision capture (rejected alternatives) | GCC | Learnings don't distinguish decisions from patterns | Low (add `decision` type to learn) |
| Token economics tracking | Claude-Mem | No discovery vs read token metrics | Medium (add to agentdb telemetry) |
| Index pruning / TTL cleanup | GCC | AgentDB grows unbounded | Low (add prune command) |
| 200-line working memory cap | GitAgent | No enforced cap on loaded context | Low (enforce in read-start) |
| Concept-based semantic tagging | Claude-Mem | No semantic tags on learnings | Medium (add tags to learn schema) |
| Vector memory bridge | GCC | No vector search | High (needs external service) |

---

## Hypotheses for Kernel

### H070 — Graduated AgentDB retrieval reduces context tokens by 60%+

**Statement:** Adding `--summary`, `--last N`, `--decisions` modes to `agentdb read-start` (inspired by GCC's 5-level context retrieval) will reduce context injection tokens by 60%+ while maintaining session continuity quality.

**Pass criteria:** Measure tokens loaded at session start before/after. Summary mode should use <100 tokens. Last-5 mode should use <500 tokens. Full mode is current behavior (baseline).

**Fail criteria:** Summary mode misses critical context in >20% of sessions (measured by needing to re-query).

### H071 — Decision capture improves cross-session reasoning

**Statement:** Adding a `decision` type to `agentdb learn` that captures `{chose, rejected, reason}` (inspired by GCC's `note` field for rejected alternatives) will reduce repeated exploration of already-rejected approaches.

**Pass criteria:** In 10 sessions with decision capture, zero instances of re-exploring a previously rejected approach. Decisions queryable via `agentdb query`.

**Fail criteria:** Overhead of capturing decisions exceeds 30 seconds per session, or decisions are never consulted.

### H072 — Working memory cap prevents context bloat

**Statement:** Enforcing a cap (200 items or 2000 tokens) on what `agentdb read-start` loads (inspired by GitAgent's 200-line MEMORY.md cap) will force better information hygiene without losing critical context.

**Pass criteria:** Sessions start faster (measurable). No increase in "context not found" errors. Agents naturally prune low-value learnings.

**Fail criteria:** Cap causes loss of critical context in >10% of sessions.

### H073 — Automatic PostToolUse observation is too expensive for kernel

**Statement:** Claude-Mem's approach of AI-compressing every tool use is powerful but too expensive for kernel's cost model. Kernel should instead capture observations selectively (only on errors, only on file writes, only on explicit checkpoint).

**Pass criteria:** Selective capture covers 80%+ of useful observations at <20% of the cost of capturing everything.

**Fail criteria:** Selective capture misses critical observations that would have prevented re-work.

### H074 — Token economics dashboard increases cost awareness

**Statement:** Tracking discovery_tokens (original size) vs read_tokens (compressed/loaded) for context, as Claude-Mem does, will reveal optimization opportunities and justify compression investments.

**Pass criteria:** Dashboard shows measurable savings after 10 sessions. Team uses metrics to make decisions about what to compress.

**Fail criteria:** Metrics add overhead but nobody looks at them.

### H075 — AgentDB pruning prevents performance degradation

**Statement:** Adding automatic pruning to AgentDB (keep last N learnings, archive old sessions) will prevent query performance degradation over time, inspired by GCC's `--prune-index N`.

**Pass criteria:** After 100+ sessions, `agentdb read-start` completes in <200ms. Before pruning, measure current latency as baseline.

**Fail criteria:** Pruning removes information that is later needed (false pruning).

---

## Implementation Priority

**Do first (low effort, high value):**
1. H071 — Decision capture (`agentdb learn decision`)
2. H075 — AgentDB pruning (`agentdb prune --keep 50`)
3. H072 — Working memory cap on read-start

**Do second (medium effort, high value):**
4. H070 — Graduated retrieval modes
5. H074 — Token economics tracking

**Evaluate carefully (high effort, uncertain value):**
6. H073 — Selective observation capture (needs hooks infrastructure)

---

*Sources: open-gitagent/gitagent (spec v0.1.0), thedotmack/claude-mem (v6.5.0), faugustdev/git-context-controller (v2, arXiv:2508.00031)*
