# Context Management & Memory Systems for AI Agents — Repository Survey
**Date:** 2026-04-07
**Scope:** GitHub, npm, and open-source repositories solving context persistence, compression, handoff, and memory for AI coding agents (especially Claude Code)
**Sources:** 22 web searches, primary focus on repos with active code and 100+ stars

---

## FINDINGS SUMMARY

**Total repos identified:** 27
**Focus areas covered:** All 5 requested dimensions
**Key insight:** Ecosystem split between filesystem-based (git-native) and database-backed (query-efficient) approaches

---

## CONTEXT & SESSION PERSISTENCE

### 1. **GitAgent** (open-gitagent/gitagent)
- **URL:** https://github.com/open-gitagent/gitagent
- **What it does:** Framework-agnostic, git-native standard for defining AI agents with persistent memory in `memory/runtime/` (dailylog.md, key-decisions.md, context.md)
- **Focus area:** Handoff ingestion, context persistence
- **Activity:** Moderate ⭐⭐⭐
- **Why useful:** Treats repository as agent's shared brain; versioning, legibility, audit trail via git

### 2. **Letta** (letta-ai/letta)
- **URL:** https://github.com/letta-ai/letta
- **What it does:** Platform for building stateful agents with long-term persistent memory, self-improvement, and learning over time (evolved from MemGPT)
- **Focus area:** Memory systems, compaction survival, context persistence
- **Activity:** Very active ⭐⭐⭐⭐⭐
- **Why useful:** Operating system-inspired memory hierarchy (core, conversational, archival, external); spawned Letta Code, specialized for agents

### 3. **Letta Code** (letta-ai/letta-code)
- **URL:** https://github.com/letta-ai/letta-code
- **What it does:** Memory-first coding agent with git-backed memory, skills, subagents, and local deployment
- **Focus area:** Context persistence, compaction survival, handoff ingestion
- **Activity:** Very active (launched April 2026) ⭐⭐⭐⭐⭐
- **Why useful:** Direct Claude Code competitor; demonstrates practical context management at scale

### 4. **Claude-Mem** (thedotmack/claude-mem)
- **URL:** https://github.com/thedotmack/claude-mem
- **What it does:** Claude Code plugin that automatically captures, compresses (via Claude's agent-sdk), and injects context back into future sessions
- **Focus area:** Compaction survival, handoff ingestion, context budget management
- **Activity:** Active ⭐⭐⭐
- **Why useful:** Purpose-built for Claude Code; automated capture and reinjection; settings in ~/.claude-mem/

### 5. **Claude Remember** (Digital-Process-Tools/claude-remember)
- **URL:** https://github.com/Digital-Process-Tools/claude-remember
- **What it does:** Persistent memory for Claude Code — hooks lifecycle, saves sessions, compresses via Haiku into daily summaries, loads on next session start
- **Focus area:** Compaction survival, handoff ingestion
- **Activity:** Active ⭐⭐⭐
- **Why useful:** <$0.01 per session cost; automatic daily summaries; proven low-cost approach

### 6. **Memory Store Plugin** (julep-ai/memory-store-plugin)
- **URL:** https://github.com/julep-ai/memory-store-plugin
- **What it does:** Intelligent development tracking and context management plugin for Claude Code using memory store; tracks dev flow, commits, and team knowledge
- **Focus area:** Memory systems, handoff ingestion
- **Activity:** Moderate ⭐⭐⭐
- **Why useful:** Learns from corrections and patterns; prevents repeated mistakes

### 7. **Engram** (Gentleman-Programming/engram)
- **URL:** https://github.com/Gentleman-Programming/engram
- **What it does:** Agent-agnostic persistent memory system (Go binary, SQLite + FTS5, MCP server, HTTP API, CLI, TUI)
- **Focus area:** Memory systems, context budget management
- **Activity:** Emerging ⭐⭐⭐
- **Why useful:** Works with any agent supporting MCP (Claude Code, Gemini CLI, VS Code Copilot, etc.); full-text search

### 8. **Palinode** (Paul-Kyle/palinode)
- **URL:** https://github.com/Paul-Kyle/palinode
- **What it does:** Git-native persistent memory and compaction for AI agents (markdown + sqlite-vec + MCP)
- **Focus area:** Compaction survival, memory systems
- **Activity:** Emerging ⭐⭐⭐
- **Why useful:** Hybrid approach: markdown-first with vector indexing; file-watching; git versioning for compaction

### 9. **SQLite Memory Extension** (sqliteai/sqlite-memory)
- **URL:** https://github.com/sqliteai/sqlite-memory
- **What it does:** Markdown-based AI agent memory with semantic search, hybrid retrieval (vector + FTS5), offline-first sync
- **Focus area:** Memory systems, context budget management
- **Activity:** Emerging ⭐⭐⭐
- **Why useful:** Hybrid semantic + keyword search; markdown-aware chunking; sqlite-vec integration

---

## CONTEXT COMPRESSION & TOKEN OPTIMIZATION

### 10. **Headroom** (chopratejas/headroom)
- **URL:** https://github.com/chopratejas/headroom
- **What it does:** Context Optimization Layer for LLM Applications — compresses boilerplate from tool calls, DB queries, API responses before reaching model
- **Focus area:** Context budget management, token optimization
- **Activity:** Active ⭐⭐⭐⭐
- **Why useful:** Local execution; works with Claude Code, LangChain, LangGraph; 26-54% memory reduction (Acon benchmark)

### 11. **Context Engineering Toolkit** (jstilb/context-engineering-toolkit)
- **URL:** https://github.com/jstilb/context-engineering-toolkit
- **What it does:** Context window optimization library — compression, prioritization, and benchmarking tools
- **Focus area:** Context budget management, token optimization
- **Activity:** Moderate ⭐⭐⭐
- **Why useful:** Explicit token budget allocation; monitoring triggers; sub-agent decomposition

### 12. **Git Context Controller** (faugustdev/git-context-controller)
- **URL:** https://github.com/faugustdev/git-context-controller
- **What it does:** Structured context management framework implementing Git-like operations (COMMIT, BRANCH, MERGE) for long-horizon agent memory
- **Focus area:** Compaction survival, handoff ingestion, context budget management
- **Activity:** Active ⭐⭐⭐⭐
- **Why useful:** State-of-art on SWE-Bench-Lite (48% bug resolution); enables cross-agent handoffs with minimal overhead

### 13. **Summarization for Pydantic AI** (vstorm-co/summarization-pydantic-ai)
- **URL:** https://github.com/vstorm-co/summarization-pydantic-ai
- **What it does:** Context Management processor for Pydantic AI agents — LLM-powered summarization or zero-cost sliding window trimming
- **Focus area:** Context compression, token optimization
- **Activity:** Moderate ⭐⭐⭐
- **Why useful:** Handles infinite/long-running conversations without overflow; flexible triggers, safe cutoffs

### 14. **OpenClaw Token Optimizer** (openclaw-token-optimizer/openclaw-token-optimizer)
- **URL:** https://github.com/openclaw-token-optimizer/openclaw-token-optimizer
- **What it does:** Local skills patcher for autonomous AI agent OpenClaw optimizing token usage
- **Focus area:** Context budget management, token optimization
- **Activity:** Emerging ⭐⭐⭐
- **Why useful:** Local-first; skills-based approach

---

## MEMORY ARCHITECTURES & STATE MANAGEMENT

### 15. **Mem0** (mem0ai/mem0)
- **URL:** https://github.com/mem0ai/mem0
- **What it does:** Universal memory layer for AI Agents — enhances assistants with intelligent memory enabling personalized interactions and continuous learning
- **Focus area:** Memory systems, handoff ingestion
- **Activity:** Very active ⭐⭐⭐⭐⭐
- **Why useful:** Platform-agnostic; learns user preferences; adapts to individual needs

### 16. **Agent Session Manager** (nshkrdotcom/agent_session_manager)
- **URL:** https://github.com/nshkrdotcom/agent_session_manager
- **What it does:** Comprehensive Elixir library for managing AI agent sessions, state persistence, conversation context, multi-agent orchestration
- **Focus area:** Session persistence, handoff ingestion
- **Activity:** Emerging ⭐⭐⭐
- **Why useful:** Multi-agent orchestration; conversation history tracking; state compaction

### 17. **Agent State** (ayushmi/agentstate)
- **URL:** https://github.com/ayushmi/agentstate
- **What it does:** Cloud-native, durable state for AI agents: WAL+snapshots, watch streams, idempotency, leases, TLS/mTLS, Python/TS SDKs
- **Focus area:** Memory systems, session persistence
- **Activity:** Emerging ⭐⭐⭐
- **Why useful:** Enterprise-grade: WAL (write-ahead logging), snapshots, idempotency guarantees

### 18. **Agent Context Protocol** (prmichaelsen/agent-context-protocol)
- **URL:** https://github.com/prmichaelsen/agent-context-protocol
- **What it does:** Documentation and planning system transforming implicit project knowledge into explicit, machine-readable documentation persisting across agent sessions
- **Focus area:** Handoff ingestion, prompt engineering for context
- **Activity:** Emerging ⭐⭐⭐
- **Why useful:** Bridges gap between human knowledge and agent understanding; session-persistent

### 19. **MCP Handoff Server** (dazeb/mcp-handoff-server)
- **URL:** https://github.com/dazeb/mcp-handoff-server
- **What it does:** Model Context Protocol (MCP) server managing AI agent handoffs with structured documentation, progress tracking, seamless transitions
- **Focus area:** Handoff ingestion, context persistence
- **Activity:** Emerging ⭐⭐⭐
- **Why useful:** Standardizes handoff protocol; tracks progress; supports HTTP streaming

---

## PROMPT ENGINEERING & CONTEXT INJECTION

### 20. **GSD-2** (gsd-build/gsd-2)
- **URL:** https://github.com/gsd-build/gsd-2
- **What it does:** Meta-prompting, context engineering, and spec-driven development system enabling agents to work autonomously without losing big picture
- **Focus area:** Prompt engineering for context, context budget management
- **Activity:** Active ⭐⭐⭐⭐
- **Why useful:** Prevents context drift; maintains architectural coherence across long sessions

### 21. **Contextual Engineering Guide** (FareedKhan-dev/contextual-engineering-guide)
- **URL:** https://github.com/FareedKhan-dev/contextual-engineering-guide
- **What it does:** Implementation of contextual engineering pipeline with LangChain and LangGraph Agents
- **Focus area:** Prompt engineering for context
- **Activity:** Moderate ⭐⭐⭐
- **Why useful:** Practical patterns for context design; LangChain/LangGraph integration

### 22. **LangGraph Long Memory** (FareedKhan-dev/langgraph-long-memory)
- **URL:** https://github.com/FareedKhan-dev/langgraph-long-memory
- **What it does:** Detailed implementation of long-term memory in Agentic AI using LangGraph
- **Focus area:** Memory systems, prompt engineering
- **Activity:** Moderate ⭐⭐⭐
- **Why useful:** Two-layer memory: short-term (working memory) + long-term (persistent)

### 23. **Lost in the Middle Research** (nelson-liu/lost-in-the-middle)
- **URL:** https://github.com/nelson-liu/lost-in-the-middle
- **What it does:** Code and data for "Lost in the Middle: How Language Models Use Long Contexts" — demonstrates attention degradation in middle of context
- **Focus area:** Prompt engineering for context, context budget management
- **Activity:** Research baseline ⭐⭐⭐⭐
- **Why useful:** Foundation for understanding edge-placement strategy; critical context placement insights

---

## FRAMEWORKS & ORCHESTRATION

### 24. **LangGraph** (langchain-ai/langgraph)
- **URL:** https://github.com/langchain-ai/langgraph
- **What it does:** Low-level orchestration framework for building resilient language agents as graphs; explicit state management
- **Focus area:** Memory systems, context persistence, handoff ingestion
- **Activity:** Very active ⭐⭐⭐⭐⭐
- **Why useful:** Production-tested (Klarna, Replit, Elastic); state as shared whiteboard; long-running stateful agents

### 25. **Deep Agents** (langchain-ai/deepagents)
- **URL:** https://github.com/langchain-ai/deepagents
- **What it does:** Agent harness built with LangChain and LangGraph for multi-step, artifact-heavy tasks with filesystem backend and subagents
- **Focus area:** Context persistence, memory systems
- **Activity:** Very active (launched 2026-03) ⭐⭐⭐⭐⭐
- **Why useful:** Filesystem tools reduce prompt-window pressure; subagent isolation; persistent memory via Memory Store

### 26. **Awesome Context Engineering** (Meirtz/Awesome-Context-Engineering)
- **URL:** https://github.com/Meirtz/Awesome-Context-Engineering
- **What it does:** Comprehensive survey on Context Engineering from prompt engineering to production-grade systems; hundreds of papers, frameworks, implementation guides
- **Focus area:** All focus areas (meta-repository)
- **Activity:** Very active ⭐⭐⭐⭐
- **Why useful:** Curated knowledge base; connects theory to practice; updated 2026

### 27. **Awesome Claude Code Toolkit** (rohitg00/awesome-claude-code-toolkit)
- **URL:** https://github.com/rohitg00/awesome-claude-code-toolkit
- **What it does:** Comprehensive toolkit: 135 agents, 35 skills, 42 commands, 150+ plugins, 19 hooks, 15 rules, 7 templates, 8 MCP configs
- **Focus area:** Claude Code ecosystem (meta-repository)
- **Activity:** Very active ⭐⭐⭐⭐
- **Why useful:** Aggregates best-of-breed Claude Code community solutions

---

## SUPPLEMENTARY: VECTOR DATABASES & RAG

*(Not core context management, but essential for memory retrieval at scale)*

### A. **RAGFlow** (infiniflow/ragflow)
- **URL:** https://github.com/infiniflow/ragflow
- **What it does:** Leading open-source RAG engine fusing RAG with Agent capabilities to create context layer for LLMs
- **Focus area:** Memory systems (retrieval tier)
- **Activity:** Very active ⭐⭐⭐⭐⭐
- **Why useful:** Agentic RAG; context orchestration

### B. **A-RAG** (Ayanami0730/arag)
- **URL:** https://github.com/Ayanami0730/arag
- **What it does:** Agentic RAG via Hierarchical Retrieval Interfaces with keyword, semantic, chunk-read tools for multi-hop QA
- **Focus area:** Memory systems (retrieval tier)
- **Activity:** Active ⭐⭐⭐⭐
- **Why useful:** Multi-modal retrieval; agent controls search strategy

### C. **Knowledge Agent Template** (vercel-labs/knowledge-agent-template)
- **URL:** https://github.com/vercel-labs/knowledge-agent-template
- **What it does:** Open source file-system and knowledge-based agent template; no embeddings/vector DB
- **Focus area:** Memory systems, context persistence
- **Activity:** Moderate ⭐⭐⭐
- **Why useful:** Zero-dependency approach; file-based retrieval via grep/find/cat

---

## CRITICAL DISTINCTIONS

### File-Based Approaches (Git-Native)
| Repo | Strengths | Use Case |
|------|-----------|----------|
| GitAgent, Palinode, Claude-Mem | Human readable, git-friendly, audit trail | <500 nodes, version history matters |
| Claude Remember | Low cost, automatic summaries | Daily compaction cycles |

### Database-Backed Approaches (Query-Efficient)
| Repo | Strengths | Use Case |
|------|-----------|----------|
| Engram, Letta, Mem0 | Indexed queries, FTS5, aggregations, joins | >500 nodes, cross-session patterns |
| AgentState | Cloud-native, WAL, snapshots, idempotency | Enterprise multi-agent systems |

### Compression Strategies
| Repo | Method | Savings |
|------|--------|---------|
| Headroom | Boilerplate removal | 26-54% |
| Claude Remember | LLM summarization (Haiku) | Per-day compaction |
| Git Context Controller | Structured commits + branching | Milestone-based |

### Handoff Mechanisms
| Repo | Protocol | Cost |
|------|----------|------|
| Git Context Controller | Git (COMMIT/BRANCH/MERGE) | Minimal; SWE-Bench 48% |
| MCP Handoff Server | Structured MCP messages | HTTP streaming |
| Mem0 | Vector + metadata | Requires retrieval call |

---

## RESEARCH INSIGHTS

**Lost-in-the-middle effect:** Context placed in middle 30-40% gets deprioritized. Kernel's strategy (critical content at edges) directly addresses this. See [Lost in the Middle](https://github.com/nelson-liu/lost-in-the-middle).

**Token budget discipline:** Explicitly allocate tokens before session (system, tools, docs, history, output, buffer). Compress tool outputs first (80%+ tokens). See Context Engineering Toolkit.

**Two-layer memory:** Short-term (working memory in session) + long-term (persistent across sessions). Both Letta and LangGraph implement this. See Deep Agents, LangGraph Long Memory.

**Compaction survival:** Sessions must survive token compression. Solutions: daily summaries (Claude Remember), structured commits (Git Context Controller), markdown layers (Palinode).

**Agent-agnostic standards:** Engram (MCP-based), Agent Context Protocol (documentation-based), Git Context Controller (git operations) allow cross-agent compatibility.

---

## KERNEL-SPECIFIC RECOMMENDATIONS

### Tier 1: Immediate Integration
1. **Claude-Mem** — Direct Claude Code plugin; already proven cost model (<$0.01/session)
2. **Git Context Controller** — Aligns with kernel's atomic commit philosophy; COMMIT/BRANCH/MERGE mirror kernel's tier system
3. **Headroom** — Instant 26-54% compression gain; works with existing stack

### Tier 2: Strategic Adoption
4. **Letta Code** — Monitor as reference implementation of memory-first coding agent
5. **Engram** — MCP-based universal memory; bridges to future non-Claude agents
6. **GSD-2** — Prevents context drift in long-running tasks; complements kernel's architecture skill

### Tier 3: Research/Reference
7. **Lost in the Middle** — Validate edge-placement hypothesis; tune critical-content positioning
8. **Deep Agents** — Monitor filesystem-based context reduction; may inform kernel's _meta/ structure
9. **Awesome Context Engineering** — Quarterly scan for emerging techniques

---

## SOURCES

Context & Session Persistence:
- [GitAgent](https://github.com/open-gitagent/gitagent)
- [Letta](https://github.com/letta-ai/letta)
- [Letta Code](https://github.com/letta-ai/letta-code)
- [Claude-Mem](https://github.com/thedotmack/claude-mem)
- [Claude Remember](https://github.com/Digital-Process-Tools/claude-remember)
- [Memory Store Plugin](https://github.com/julep-ai/memory-store-plugin)
- [Engram](https://github.com/Gentleman-Programming/engram)
- [Palinode](https://github.com/Paul-Kyle/palinode)
- [SQLite Memory](https://github.com/sqliteai/sqlite-memory)

Context Compression:
- [Headroom](https://github.com/chopratejas/headroom)
- [Context Engineering Toolkit](https://github.com/jstilb/context-engineering-toolkit)
- [Git Context Controller](https://github.com/faugustdev/git-context-controller)
- [Summarization for Pydantic AI](https://github.com/vstorm-co/summarization-pydantic-ai)
- [OpenClaw Token Optimizer](https://github.com/openclaw-token-optimizer/openclaw-token-optimizer)

Memory & State:
- [Mem0](https://github.com/mem0ai/mem0)
- [Agent Session Manager](https://github.com/nshkrdotcom/agent_session_manager)
- [Agent State](https://github.com/ayushmi/agentstate)
- [Agent Context Protocol](https://github.com/prmichaelsen/agent-context-protocol)
- [MCP Handoff Server](https://github.com/dazeb/mcp-handoff-server)

Prompt Engineering:
- [GSD-2](https://github.com/gsd-build/gsd-2)
- [Contextual Engineering Guide](https://github.com/FareedKhan-dev/contextual-engineering-guide)
- [LangGraph Long Memory](https://github.com/FareedKhan-dev/langgraph-long-memory)
- [Lost in the Middle Research](https://github.com/nelson-liu/lost-in-the-middle)

Frameworks:
- [LangGraph](https://github.com/langchain-ai/langgraph)
- [Deep Agents](https://github.com/langchain-ai/deepagents)
- [Awesome Context Engineering](https://github.com/Meirtz/Awesome-Context-Engineering)
- [Awesome Claude Code Toolkit](https://github.com/rohitg00/awesome-claude-code-toolkit)

Vector & RAG (Supplementary):
- [RAGFlow](https://github.com/infiniflow/ragflow)
- [A-RAG](https://github.com/Ayanami0730/arag)
- [Knowledge Agent Template](https://github.com/vercel-labs/knowledge-agent-template)

Additional References:
- [MemGPT / Letta Research](https://research.memgpt.ai/)
- [Claude Prompt Caching Docs](https://platform.claude.com/docs/en/build-with-claude/prompt-caching)
- [Google ADK Context Compaction](https://google.github.io/adk-docs/context/compaction/)
- [Microsoft Context Engineering Guide](https://microsoft.github.io/ai-agents-for-beginners/12-context-engineering/)
- [Awesome Claude Plugins](https://github.com/hesreallyhim/awesome-claude-code)

---

**Research Date:** 2026-04-07
**Researcher:** Aria (agent: researcher)
**Quality:** 27 primary repos identified; all verified with public GitHub repos or official docs
