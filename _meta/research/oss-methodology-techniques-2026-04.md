# OSS Methodology Techniques — GSD-2 & Headroom

**Date:** 2026-04-07
**Sources:** gsd-build/gsd-2 (commit HEAD), chopratejas/headroom (commit HEAD)
**Purpose:** Extract concrete techniques kernel-claude could adopt

---

## 1. GSD-2 — Meta-Prompting & Anti-Drift System

### 1.1 Anti-Drift Architecture: Append-Only Decision Log

GSD-2's most powerful anti-drift mechanism is its **append-only DECISIONS.md**. Decisions are never edited or deleted; to reverse a decision, you add a new row that supersedes it. The agent reads this file at the start of every planning or research phase.

**Schema:**
```
| # | When | Scope | Decision | Choice | Rationale | Revisable? | Made By |
```

**Why this matters for kernel:** kernel-claude's `_meta/_learnings.md` captures patterns but not *decisions*. There's no structured record of "why did we choose X over Y?" that persists across sessions. The decision log prevents the most dangerous form of drift — loss of "why."

**GSD-2's golden rule:** "Never summarize summaries. Each compression layer regenerates from the one below. The codebase is always the lossless source of truth."

### 1.2 Structured Requirements as a Contract

GSD-2 maintains `REQUIREMENTS.md` with formal requirement tracking:
- Each requirement has: Class, Status (active/validated/deferred/out-of-scope), Source, Primary owning slice, Validation status
- Traceability table maps requirements to implementation slices
- Coverage summary counts: active, mapped, validated, unmapped

**What kernel doesn't do:** kernel's contracts define goals and constraints but don't track requirement *validation* — whether a requirement was actually proven by completed work. GSD-2 distinguishes "mapped" from "validated."

### 1.3 Knowledge System: Three Tables

GSD-2's `KNOWLEDGE.md` uses three structured tables:

| Table | Content | Schema |
|-------|---------|--------|
| **Rules** | Project-specific rules | `# | Scope | Rule | Why | Added` |
| **Patterns** | Discovered conventions | `# | Pattern | Where | Notes` |
| **Lessons Learned** | Post-mortems | `# | What Happened | Root Cause | Fix | Scope` |

Agents read this before every unit. Entries have K/P/L prefixed IDs (K001, P001, L001). The knowledge service parses both freeform and table formats.

**What kernel doesn't do:** kernel's `_learnings.md` is unstructured. GSD-2's separation of rules/patterns/lessons with IDs enables cross-referencing and expiration tracking.

### 1.4 Context Injection System

`context-injector.ts` injects prior step artifacts into step prompts via a declarative `contextFrom` array in the frozen step definition. Each step declares what it produces; dependent steps reference those outputs.

**Key constraints:**
- Max 10,000 chars per artifact (prevents context blowout)
- Path traversal guard (artifacts can't escape run directory)
- Missing artifacts skipped silently (step may not have produced them yet)
- Truncation is logged, never silent

**What kernel doesn't do:** kernel's agent contracts don't declare explicit IO signatures. GSD-2's reactive task graph derives dependencies from task IO intersections — `deriveTaskGraph()` builds a DAG where task B depends on task A when B's inputFiles appear in A's outputFiles.

### 1.5 Layered Context Engineering (Token Budget)

GSD-2 defines explicit token budgets:

| Category | Budget |
|----------|--------|
| System prompt + behavioral instructions | ~15% |
| Manifest | ~5% |
| Task spec + acceptance criteria | ~20% |
| Active code files | ~40% |
| Interface contracts | ~10% |
| Reserve (tool results, errors) | ~10% |

**Four-layer memory architecture:**
- L1 Working Context (8k-25k tokens): current task + 3-5 relevant files
- L2 Session/Episodic: auto-summarized at transitions (summary only)
- L3 Project Semantic: full codebase summaries, dependency graph (pointers only)
- L4 Ground Truth: actual files, git history (zero in prompt)

**Key principle:** "Context is a cache, not a history. Holds exactly what's needed now, everything else evicted."

### 1.6 Ambiguity Classification & Assumption Ledger

Three-layer strategy for handling unclear requirements:

1. **Classification:** Clear (proceed) / Ambiguous-but-decidable (proceed + document) / Genuinely unclear (halt + escalate)
2. **Assumption Ledger:** Every task completion includes assumptions with confidence scores
3. **Contradiction Detection:** Dedicated reasoning pass before execution scans for conflicts

Multi-Hypothesis Planning: When underspecification detected, generate 3 intent hypotheses (Minimalist, Scalable, Feature-Rich). If semantic distance exceeds threshold, hard-halt and present decision matrix.

### 1.7 Phase Boundary Refresh

For long-running projects: rebuild the manifest from scratch at phase boundaries by reading actual codebase + decision log, rather than carrying forward incrementally updated manifest. "The equivalent of defragmenting a hard drive."

### 1.8 Execution Policy Interface

Clean separation of concerns via `ExecutionPolicy`:
- `selectModel()` — choose model tier per unit
- `verify()` — verify unit output, returns continue/retry/pause
- `recover()` — determine recovery action on failure
- `closeout()` — commit, snapshot, artifact capture

### 1.9 Milestone Validation Gates

Structured quality gates with IDs:
- MV01: Success criteria checklist
- MV02: Slice delivery audit
- MV03: Cross-slice integration
- MV04: Requirement coverage

Gates persist to DB with verdicts, enabling historical quality tracking.

---

## 2. Headroom — Context Compression Without LLM Calls

### 2.1 Compression Pipeline Architecture

Three-stage pipeline, applied in order:

1. **CacheAligner** — Normalizes prefix for provider KV cache hits
2. **ContentRouter** — Routes to appropriate compressor per content type
3. **IntelligentContextManager** — Enforces token limits with score-based dropping

**Key design:** Pipeline operates on deep copies; only two full token counts (initial and final); per-transform counts come from each transform's own result to avoid O(N) recounts.

### 2.2 Content Type Detection (Zero-LLM)

`content_detector.py` identifies content type via regex pattern analysis:

| Type | Detection Method | Compressor |
|------|-----------------|------------|
| JSON_ARRAY | `json.loads()` + type check | SmartCrusher |
| SOURCE_CODE | Language-specific regex patterns (Python, JS, TS, Go, Rust, Java) | CodeCompressor (AST-based via tree-sitter) |
| SEARCH_RESULTS | `file:line:` pattern matching (>30% of lines) | SearchCompressor |
| BUILD_OUTPUT | Log level patterns (ERROR, WARN, timestamps, test results) | LogCompressor |
| GIT_DIFF | `diff --git`, `@@` headers | DiffCompressor |
| HTML | DOCTYPE, structural tags | HTMLExtractor |
| PLAIN_TEXT | Fallback | TextCompressor |

Each detector returns confidence score (0.0-1.0). Priority: JSON > Diff > HTML > Search > Build > Code > Text.

### 2.3 SmartCrusher: Statistical JSON Compression

Handles JSON arrays using statistical analysis rather than fixed rules:

**Techniques:**
- **Adaptive K via Kneedle algorithm:** Determines optimal number of items to keep based on data distribution, not hardcoded limits
- **Variance-based change point detection:** Preserves items around detected anomalies (>2 std from mean)
- **Error item preservation:** Items containing 'error', 'exception', 'failed', 'critical' never dropped
- **RelevanceScorer:** ML-powered or BM25-based relevance matching to user query
- **Safety:** First K, last K items always kept; schema-preserving (output contains only items from original array)

**Pattern types handled:** Arrays of dicts (full statistical analysis), arrays of strings (dedup + sampling), arrays of numbers (summary + outlier preservation), mixed-type arrays (grouped by type).

### 2.4 ToolCrusher: Conservative JSON Compression

Simpler fallback for tool outputs:
- Only compresses tool role messages > min_tokens threshold
- Truncates arrays to max_items
- Truncates long strings to max_string_length
- Limits nesting depth to max_depth
- At max depth: `{"__headroom_depth_exceeded": count}`
- Computes hash of original, inserts digest marker for later retrieval

### 2.5 Code Compression via AST (tree-sitter)

`code_compressor.py` uses tree-sitter for syntax-preserving compression:
1. Parse code into AST
2. Extract and preserve: imports, signatures, type annotations, error handlers
3. Rank functions by importance (semantic analysis)
4. Compress function bodies while preserving signatures
5. Reassemble into valid code

**Guarantee:** Output always parses as valid code. Based on LongCodeZip paper (arxiv.org/abs/2510.00446).

### 2.6 Message Importance Scoring

Six-factor weighted scoring for intelligent context management:

| Factor | Signal | Method |
|--------|--------|--------|
| Recency | Position from end | Exponential decay: `e^(-lambda * position)` |
| Semantic similarity | Embedding cosine to recent context | Embedding provider (optional) |
| TOIN importance | Learned field importance | Retrieval rate from cross-user patterns |
| Error indicators | Error field types | TOIN-learned `field_semantics.inferred_type` |
| Forward references | Referenced by later messages | Tool call ID tracking |
| Token density | Information density | `unique_tokens / total_tokens` |

**Design principle:** NO HARDCODED PATTERNS. All importance signals derived from computed metrics, TOIN-learned patterns, or embedding similarity.

### 2.7 TOIN: Tool Output Intelligence Network

Cross-user learning system for compression recommendations:

1. SmartCrusher compresses data, records outcome via telemetry
2. LLM retrieves compressed data, TOIN tracks what was needed
3. TOIN learns: "For tools with structure X, retrieval rate is high when compressing field Y — preserve it"
4. Next time: SmartCrusher asks TOIN for hints before compressing

**Privacy:** No actual data values stored. Tool names are structure hashes. Field names are SHA256[:8] hashes. No user identifiers.

### 2.8 Waste Signal Detection

`parser.py` detects token waste without LLM calls:
- HTML tags/comments: regex-based detection
- Base64 blobs: pattern `[A-Za-z0-9+/]{50,}={0,2}`
- Excessive whitespace: `[ \t]{4,}|\n{3,}`
- Large JSON blocks: `\{[\s\S]{500,}\}`
- RAG markers: `[Document N]`, `[Source:`, `<context>`, etc.

### 2.9 Specialized Compressors

**LogCompressor** (10-50x compression on build output):
- Detects format (pytest, npm, cargo, make, jest, generic)
- Extracts all ERROR/FAIL lines with context
- Extracts first stack trace completely
- Deduplicates repeated warnings
- Summarizes: `[247 INFO lines, 12 WARN lines omitted]`

**DiffCompressor** (3-10x compression):
- Keeps ALL actual changes (+/- lines) and headers
- Reduces context lines to configurable max
- If too many hunks, keeps first N and summarizes rest

**SearchCompressor** (5-10x compression):
- Parses into `{file: [(line, content)]}` structure
- Per file: keeps first match, last match, context-relevant matches
- Deduplicates near-identical lines

**TextCompressor** (fallback):
- Identifies anchor lines (context keywords)
- Keeps first N and last M lines
- Samples from middle based on line importance scoring

### 2.10 Compression Summary

When items are dropped, Headroom generates categorical summaries:
- Not just `[480 items omitted]` but `[480 items omitted: 150 log entries (3 with errors), 200 test results (12 failures)]`
- Categorizes by type/status/kind fields
- Calls out notable items (errors, failures, warnings)
- Helps LLM decide whether to retrieve more

### 2.11 CCR (Compressed Context Retrieval)

Compressed content is stored with hash keys. When the LLM needs dropped content, it can call `headroom_retrieve` with the hash. This makes compression reversible — the LLM can always get back what was dropped.

---

## 3. Gap Analysis: What Kernel Doesn't Do

| Capability | GSD-2 | Headroom | Kernel |
|-----------|-------|----------|--------|
| Append-only decision log | DECISIONS.md | - | Missing |
| Requirement validation tracking | REQUIREMENTS.md with status lifecycle | - | Contracts don't track validation |
| Structured knowledge (rules/patterns/lessons) | KNOWLEDGE.md with K/P/L IDs | - | Unstructured _learnings.md |
| IO-derived task dependency graph | reactive-graph.ts | - | Manual contract dependencies |
| Token budget categories | 6 categories with % allocations | - | No explicit budget system |
| Phase boundary manifest rebuild | Explicit pattern | - | Compaction without rebuild |
| Assumption ledger with confidence | Per-task assumptions.md | - | Missing |
| Content-type-aware compression | - | 7 content types, specialized compressors | No compression system |
| Statistical JSON compression | - | SmartCrusher (Kneedle, change points) | No tool output compression |
| AST-preserving code compression | - | tree-sitter CodeCompressor | No code compression |
| Message importance scoring | - | 6-factor weighted scoring | No scoring |
| Cross-session compression learning | - | TOIN network | AgentDB learns but doesn't feed back into compression |
| Waste signal detection | - | HTML, base64, whitespace, JSON detection | No waste detection |
| Reversible compression (CCR) | - | Store + retrieve via hash | No compression at all |
| Categorical drop summaries | - | "150 log entries (3 with errors)" | No summaries of omitted content |
| Milestone quality gates | MV01-MV04, persisted to DB | - | Adversary verdict (pass/fail), not structured gates |

---

## 4. Hypotheses to Test

### H070 — Append-only decision log reduces cross-session drift
**Statement:** Adding a structured DECISIONS.md (append-only, read at session start) reduces "wrong direction" rework by >30% compared to _learnings.md alone.
**Pass criteria:** Over 10 sessions with decision log, fewer instances of contradicting earlier decisions or repeating settled debates.
**Fail criteria:** Decision log adds overhead without measurably reducing rework. Or log grows too large to be useful within 20 sessions.

### H071 — Content-type-aware tool output compression saves >20% tokens per session
**Statement:** Applying Headroom-style content detection + specialized compression to tool outputs (grep results, build logs, JSON payloads) within kernel-claude's context management reduces token consumption by >20% without degrading task quality.
**Pass criteria:** Measure tokens before/after compression on 10 real sessions. >20% reduction with no increase in tool re-invocation (re-reading the same content).
**Fail criteria:** <10% savings, or task quality degrades (measured by success rate).

### H072 — Structured knowledge tables outperform unstructured learnings
**Statement:** Separating learnings into Rules, Patterns, and Lessons (with IDs) improves retrieval accuracy and reduces stale entries compared to flat _learnings.md.
**Pass criteria:** After 15 sessions, structured format has fewer stale entries and agents cite specific knowledge IDs in their reasoning.
**Fail criteria:** Overhead of maintaining three tables exceeds benefit, or agents don't use the IDs.

### H073 — IO-declared agent contracts enable automatic dependency resolution
**Statement:** Adding explicit `inputs` and `outputs` fields to agent contracts (surgeon, adversary) enables automatic DAG construction and parallel dispatch, replacing manual sequencing.
**Pass criteria:** Tier 3 contracts can auto-derive execution order from IO declarations, matching or improving manually sequenced outcomes.
**Fail criteria:** IO declarations are too ambiguous (file paths don't overlap cleanly) or too rigid (agent needs to touch files not in its declared IO).

### H074 — Token budget categories prevent context window misallocation
**Statement:** Explicitly allocating context window into budget categories (system 15%, task spec 20%, active code 40%, reserve 10%) improves first-attempt success rate by keeping instructions and active code from crowding each other out.
**Pass criteria:** Compare first-attempt success rate: 10 sessions with budgets vs. 10 without. Budget sessions score higher.
**Fail criteria:** Budget enforcement too rigid — agents need dynamic allocation based on task type.

### H075 — Waste signal detection identifies >10% compressible content in typical tool outputs
**Statement:** Regex-based detection of HTML noise, base64 blobs, excessive whitespace, and large JSON blocks in tool outputs identifies >10% of tokens as compressible waste.
**Pass criteria:** Sample 50 tool outputs from real sessions. >10% average waste detected.
**Fail criteria:** Tool outputs are already clean (<5% waste) in kernel's typical use cases.

### H076 — Phase boundary manifest rebuild prevents summary drift
**Statement:** Rebuilding AgentDB session context from scratch at tier boundaries (rather than incremental updates) prevents photocopy-of-photocopy degradation over long sessions.
**Pass criteria:** Compare manifest accuracy (against actual codebase state) at session end: incremental vs. rebuild. Rebuild has fewer factual errors.
**Fail criteria:** Rebuild cost (time + tokens) exceeds benefit, or incremental updates are accurate enough.

---

## 5. Recommended Adoptions (Priority Order)

1. **Decision Log (H070)** — Lowest effort, highest anti-drift value. Add structured DECISIONS.md to _meta/. Tier: trivial.

2. **Structured Knowledge Tables (H072)** — Refactor _learnings.md into three tables with IDs. Tier: trivial.

3. **Waste Signal Detection (H075)** — Regex-only, no dependencies. Add to context-mgmt skill. Tier: 1 (single file).

4. **Content-Type Detection (H071)** — Port Headroom's content_detector.py pattern. Add to compaction flow. Tier: 1-2.

5. **Token Budget System (H074)** — Add category-based allocation to context-mgmt skill. Tier: 2.

6. **IO-Declared Contracts (H073)** — Extend contract schema. Requires changes to surgeon/adversary agents. Tier: 2.

7. **Phase Boundary Rebuild (H076)** — Add to handoff/compaction. Tier: 1.
