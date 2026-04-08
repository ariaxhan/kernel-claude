# Memory Power Law: External Validation Research

**Date:** 2026-04-07
**Purpose:** Validate kernel-claude's empirical findings against published research on memory systems in AI agents, cognitive science, and knowledge management.

---

## Our Findings (kernel-claude, 356 learnings)

| Claim | Evidence |
|-------|----------|
| 7% of memories deliver 80% of value | Top 25/356 learnings = 80.5% of reference hits |
| 14-day decay curve | 91% of hits come from learnings <= 14 days old |
| 70% stored knowledge never used | 247/356 learnings have zero hits (69.4%) |
| Power law distribution | Sharp decay: top items dominate, long tail of zero-use items |

---

## 1. Does a Power Law Match Research on AI Agent Memory?

### Verdict: YES -- strongly expected.

**Pareto/Zipf distributions are universal in information retrieval.** The 80/20 rule (Pareto principle) is one of the most replicated findings across knowledge management, library science, and information systems. A small fraction of stored knowledge consistently accounts for the majority of retrievals.

**Memory access in AI agents follows the same pattern.** SuperLocalMemory V3.3 (arxiv:2604.04514) -- a biologically-inspired agent memory system -- reported **6.7x discriminative power** between frequently-accessed and unused memories over 30 simulated days. Hot memories had mean strength of 11.28 vs. cold memories at 1.69, demonstrating the same power-law concentration we observe.

**Retrieval dominates over storage.** Research on retrieval vs. utilization bottlenecks in LLM agent memory (arxiv:2603.02473) found that retrieval method accounts for a **20-point accuracy swing** (57.1% to 77.2%) while write strategies only contribute 3-8 points. This implies that what matters is not how many memories you store, but which ones surface -- inherently a power-law selection problem.

**Knowledge Access Beats Model Size** (arxiv:2603.23013): An 8B model with memory recovered 69% of a 235B model's performance. Critically, 47% of queries were semantically similar to prior interactions, suggesting a concentrated "working set" of reusable knowledge -- consistent with our 7% delivering 80% finding.

### Sources
- [SuperLocalMemory V3.3: Biologically-Inspired Forgetting](https://arxiv.org/html/2604.04514)
- [Diagnosing Retrieval vs. Utilization Bottlenecks](https://arxiv.org/abs/2603.02473)
- [Knowledge Access Beats Model Size](https://arxiv.org/abs/2603.23013)
- [Memory in the Age of AI Agents: A Survey](https://arxiv.org/abs/2512.13564)

---

## 2. "Lost in the Middle" -- How Much Context Gets Used?

### Verdict: Models severely underutilize context. Position dominates relevance.

**Key findings from Liu et al. (2024, TACL):**
- Performance follows a **U-shaped curve**: information at the beginning and end of context is used; middle content is largely ignored.
- GPT-3.5-Turbo performed **worse** with relevant information in the middle than with no documents at all (below the closed-book baseline of 56.1%).
- This is a structural limitation, not a data quality problem -- even "explicitly long-context models" exhibit it.

**Implication for our findings:** If LLMs underutilize middle-positioned context, then injecting 356 learnings is counterproductive. Only the most prominent (first/last positioned, most frequently referenced) will actually influence behavior. This independently predicts a power-law-like utilization pattern -- a few salient memories dominate while the bulk goes unused.

### Sources
- [Lost in the Middle: How Language Models Use Long Contexts (Paper)](https://arxiv.org/abs/2307.03172)
- [Lost in the Middle (ACL Anthology)](https://aclanthology.org/2024.tacl-1.9/)

---

## 3. Measuring "Knowledge Utilization Rate" in Agent Memory

### Verdict: Emerging field. No standard metric yet, but directional data exists.

**Retrieval precision correlates almost perfectly with accuracy.** The retrieval bottleneck paper (arxiv:2603.02473) found **r=0.98 correlation** between retrieval precision and downstream accuracy. This means: if you measure what gets retrieved (our "hit rate"), you're measuring what matters.

**Mem0 research** demonstrated 26% accuracy improvement and 90% token reduction through selective memory retrieval -- but does not publish what percentage of stored memories get accessed. The metric isn't standardized yet.

**Letta/MemGPT benchmarking** achieved 74% accuracy on LoCoMo with simple filesystem storage but similarly does not report memory access rates or utilization ratios.

**Microsoft PlugMem** proposes measuring "how much useful, decision-relevant information a memory module contributes relative to how much context it consumes" -- the closest formalization to a knowledge utilization rate, but no published numbers yet.

**Our contribution:** The kernel-claude hit rate (30.6% of learnings have >= 1 hit, 69.4% have zero) may be one of the few empirical measurements of knowledge utilization rate in a persistent agent memory system operating in production.

### Sources
- [Mem0 Research: 26% Accuracy Boost](https://mem0.ai/research)
- [Letta Benchmarking AI Agent Memory](https://www.letta.com/blog/benchmarking-ai-agent-memory)
- [PlugMem: Rethinking Memory for AI Agents (Microsoft)](https://www.microsoft.com/en-us/research/blog/from-raw-interaction-to-reusable-knowledge-rethinking-memory-for-ai-agents/)
- [Diagnosing Retrieval vs. Utilization Bottlenecks](https://arxiv.org/abs/2603.02473)

---

## 4. Optimal Retention Policy for Agent Memories

### Verdict: Tiered decay with access-reinforcement. Our 14-day curve aligns with cognitive science.

**Ebbinghaus forgetting curve (1885, replicated 2015):**
- Memory decays exponentially: R = e^(-t/S)
- Without reinforcement: ~50% lost within 1 hour, ~70% within 24 hours, ~75% within a week
- The 4th spaced repetition review optimally occurs at ~14 days -- matching our observed decay inflection point exactly

**FadeMem framework** (cited in agent memory research):
- Two-tier architecture: Long-term Memory Layer (slow decay for high-importance) and Short-term Memory Layer (rapid fade for low-importance)
- Achieved 82.1% critical fact retention vs. 78.4% for append-only systems
- **45% storage reduction** through intelligent forgetting
- Access resets decay clock (spacing effect)

**Recommended tiered retention from practitioner research:**

| Tier | TTL | Content |
|------|-----|---------|
| Permanent | No expiry | Critical facts, hard constraints |
| 30 days | Medium-term | Project context, active patterns |
| 7 days | Short-term | Session-level, tactical decisions |
| 3 days | Ephemeral | One-off interactions, temporary context |

**SuperLocalMemory V3.3 lifecycle states:**

| State | Retention Score | Action |
|-------|----------------|--------|
| Active | R > 0.8 | Full precision, immediate access |
| Warm | 0.5 < R <= 0.8 | Reduced precision |
| Cold | 0.2 < R <= 0.5 | Compressed |
| Archive | 0.05 < R <= 0.2 | Minimal storage |
| Forgotten | R <= 0.05 | Deleted |

**Key insight:** Access frequency dominates decay. Five retrievals extend memory half-life from 1.2 hours to 3.8 hours in SuperLocalMemory. This validates that our "hit count" metric is the right signal for retention decisions.

### Sources
- [Ebbinghaus Forgetting Curve (Wikipedia)](https://en.wikipedia.org/wiki/Forgetting_curve)
- [Replication of Ebbinghaus' Forgetting Curve (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC4492928/)
- [The Agent's Memory Dilemma: Is Forgetting a Bug or a Feature?](https://tao-hpu.medium.com/the-agents-memory-dilemma-is-forgetting-a-bug-or-a-feature-a7e8421793d4)
- [AI Agent Memory Part 2: The Case for Intelligent Forgetting](https://dev.to/sudarshangouda/ai-agent-memory-part-2-the-case-for-intelligent-forgetting-4i48)
- [SuperLocalMemory V3.3](https://arxiv.org/html/2604.04514)

---

## 5. Synthesis: Validation Matrix

| Our Finding | External Support | Confidence |
|-------------|-----------------|------------|
| **7% delivers 80%** | Pareto principle universal; 47% query similarity concentration (arxiv:2603.23013); 6.7x hot/cold discriminative power (SuperLocalMemory) | **HIGH** -- consistent with decades of information retrieval research |
| **14-day decay** | Ebbinghaus curve: 4th spaced repetition review at ~14 days; exponential decay is the canonical model | **HIGH** -- our inflection point matches the established forgetting curve |
| **70% never used** | "Lost in the Middle" shows middle-context ignored; append-only systems show "sustained performance decline"; no direct comparable metric published | **MEDIUM-HIGH** -- directionally validated, but we may have the only empirical measurement at this granularity |
| **Power law working set** | Universal in information retrieval; SuperLocalMemory confirms bimodal hot/cold distribution; retrieval precision r=0.98 with accuracy means small retrieved set dominates | **HIGH** -- this is expected behavior, not anomalous |

---

## 6. Implications for kernel-claude

1. **The 70% zero-hit learnings are not a failure -- they're expected.** Every memory system accumulates a long tail. The question is whether the retrieval mechanism surfaces the right 7%.

2. **14-day TTL is empirically justified.** Both Ebbinghaus and FadeMem research support aggressive decay for unreinforced memories. Consider: permanent tier for >10 hits, 14-day TTL for 1-9 hits, 7-day TTL for 0 hits.

3. **Hit count is the right metric.** The r=0.98 correlation between retrieval precision and downstream accuracy validates that tracking which learnings get referenced is a reliable proxy for value.

4. **Pruning the long tail is safe.** FadeMem achieved better retention (82.1% vs 78.4%) with 45% less storage. Removing zero-hit learnings older than 14 days should improve, not degrade, system performance.

5. **Position matters.** "Lost in the Middle" suggests that HOW learnings are injected into context matters as much as WHICH ones. High-value learnings should be positioned at the beginning or end of context, never buried in the middle.
