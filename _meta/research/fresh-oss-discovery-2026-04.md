---
query: "new claude code plugins, agent orchestration, context management, cross-session learning, AI code quality 2026"
date: "2026-04-07"
ttl: 14
domain: "OSS discovery — new projects not in prior surveys"
sources: 12
---

# Fresh OSS Discovery — April 2026

**Scope:** Projects NOT covered in existing kernel-claude research (community-plugins, plugin-landscape, context-repos surveys). Focus on novel approaches to problems kernel-claude faces.

---

## Tier 1: High Relevance (directly solves kernel problems)

### 1. ARIS (Auto-Research-In-Sleep)
- **URL:** https://github.com/wanshuiyin/Auto-claude-code-research-in-sleep
- **Stars:** 5,750 | **Activity:** Very active (updated 2026-04-08)
- **What:** Lightweight markdown-only skills for autonomous ML research: cross-model review loops, idea discovery, and experiment automation. No framework dependency — works with Claude Code, Codex, OpenClaw, or any LLM agent.
- **Why relevant:** Directly addresses kernel's `/kernel:experiment` and `/kernel:forge` overnight-run patterns. ARIS does autonomous research loops while you sleep — same philosophy as forge's "run overnight, come back to shipped code." Their cross-model review loop is a proven pattern kernel could adopt for adversary validation.
- **Hypothesis:** H-ARIS-001: ARIS's cross-model review loop pattern produces higher-confidence adversary verdicts than single-model review (kernel's current approach).

### 2. Ars Contexta
- **URL:** https://github.com/agenticnotetaking/arscontexta
- **Stars:** 3,067 | **Activity:** Active (updated 2026-04-07)
- **What:** Claude Code plugin that generates individualized knowledge systems from conversation. You describe how you think and work, have a conversation, and get a complete second brain as markdown files you own.
- **Why relevant:** Addresses kernel's cross-session learning problem from a different angle. Instead of AgentDB's structured telemetry approach, Ars Contexta builds a personal knowledge vault from conversational patterns. Could complement AgentDB by generating higher-level synthesis that current `_meta/_learnings.md` captures poorly.
- **Hypothesis:** H-ARSCTX-001: Conversational knowledge extraction (Ars Contexta) captures tacit patterns that structured AgentDB logging misses, improving cross-session continuity.

### 3. claude-octopus (Multi-Model Blind Spot Detection)
- **URL:** https://github.com/nyldn/claude-octopus
- **Stars:** 2,446 | **Activity:** Active (updated 2026-04-08)
- **What:** Routes every coding task through up to 8 AI models simultaneously. Surfaces blind spots before shipping by comparing model outputs.
- **Why relevant:** Kernel's adversary agent uses the same model family (Claude) to review Claude-written code. Octopus's multi-model approach could expose model-family blind spots that same-family adversarial review cannot catch. Directly relevant to kernel's quality gates.
- **Hypothesis:** H-OCTO-001: Multi-model adversarial review catches 20%+ more issues than single-model-family review (kernel's current adversary pattern).

---

## Tier 2: Medium Relevance (novel approach, partial overlap)

### 4. claude-hud (Real-Time Context Dashboard)
- **URL:** https://github.com/jarrodwatts/claude-hud
- **Stars:** 17,509 | **Activity:** Very active (updated 2026-04-08)
- **What:** Plugin that shows real-time context usage, active tools, running agents, and todo progress in a heads-up display.
- **Why relevant:** Kernel's `/kernel:metrics` provides post-hoc telemetry, but has no real-time visibility into context budget during execution. Claude-hud solves the "how much context am I burning right now?" problem that causes compaction surprises. At 17.5K stars, this is the de facto standard for runtime observability.
- **Hypothesis:** H-HUD-001: Real-time context monitoring prevents unnecessary compactions and improves agent efficiency by enabling proactive context management.

### 5. adversarial-spec (Consensus-Driven Spec Refinement)
- **URL:** https://github.com/zscole/adversarial-spec
- **Stars:** 519 | **Activity:** Active (updated 2026-04-05)
- **What:** Plugin that iteratively refines product specifications by debating between multiple LLMs until all models reach consensus.
- **Why relevant:** Kernel's `/kernel:tearitapart` reviews plans before implementation, but uses a single agent. Adversarial-spec's multi-LLM debate-until-consensus approach could strengthen the tearitapart phase. The consensus mechanism is novel — it's not just "get a second opinion" but "debate until agreement."
- **Hypothesis:** H-ADVSPEC-001: Multi-LLM consensus on specs before implementation reduces mid-implementation scope changes by 30%+ compared to single-agent review.

### 6. claude-review-loop (Claude + Codex Cross-Review)
- **URL:** https://github.com/hamelsmu/claude-review-loop
- **Stars:** 638 | **Activity:** Active (updated 2026-04-07)
- **What:** Automated code review loop where Claude writes code and Codex reviews it (or vice versa), iterating until both agree.
- **Why relevant:** Same-family-bias problem as kernel's adversary. This plugin solves it pragmatically by using Claude + Codex as an adversarial pair. Hamel Husain (fast.ai) built it — credible author.
- **Hypothesis:** H-REVLOOP-001: Cross-tool review loops (Claude writes, Codex reviews) catch integration bugs that same-tool review misses.

### 7. cclsp (Non-IDE LSP for Claude Code)
- **URL:** https://github.com/ktnyt/cclsp
- **Stars:** 607 | **Activity:** Active (updated 2026-04-07)
- **What:** Provides full LSP integration for Claude Code without requiring an IDE. Enables goto-definition, find-references, hover, diagnostics directly in the terminal Claude Code experience.
- **Why relevant:** Kernel already has LSP-first philosophy (`<lsp>` section in CLAUDE.md) but relies on whatever LSP tools are available. cclsp makes LSP capabilities reliable and consistent across environments — filling the gap when Claude Code's built-in LSP tools are unavailable.
- **Hypothesis:** H-CCLSP-001: Consistent LSP availability via cclsp reduces grep-based code navigation by 60%+ and improves surgeon agent accuracy.

---

## Tier 3: Interesting but Niche

### 8. correctless (Agent Separation for Code Quality)
- **URL:** https://github.com/joshft/correctless
- **Stars:** 49 | **Activity:** Active (updated 2026-04-07)
- **What:** "The agent that writes the code never reviews it." Spec-driven TDD with strict agent separation, adversarial QA, and dynamic rigor levels.
- **Why relevant:** Kernel already implements this pattern (surgeon writes, adversary reviews), but correctless adds "dynamic rigor" — adjusting review intensity based on code complexity. Could inform kernel's tier classification.
- **Hypothesis:** H-CORRECT-001: Dynamic rigor levels (adjusting adversary scrutiny based on code complexity) improve review efficiency without reducing catch rate.

### 9. claude-forge (oh-my-zsh for Claude Code)
- **URL:** https://github.com/sangrokjung/claude-forge
- **Stars:** 643 | **Activity:** Active (updated 2026-04-08)
- **What:** 11 agents, 36 commands, 15 skills with 6-layer security hooks. Inspired by oh-my-zsh's plugin model — drop-in components.
- **Why relevant:** Kernel is monolithic (single CLAUDE.md + agents directory). Claude-forge's modular approach (individual components that compose) could inform kernel's architecture if it grows beyond current complexity. Their 6-layer security hooks are worth studying.
- **Hypothesis:** H-FORGE-001: Modular plugin architecture (forge-style) enables faster iteration on individual kernel components vs monolithic CLAUDE.md.

### 10. mcgravity (Plan-Execute-Review TUI)
- **URL:** https://github.com/tigranbs/mcgravity
- **Stars:** 91 | **Activity:** Active (updated 2026-04-07)
- **What:** TUI that orchestrates Claude Code, Codex, and Gemini in a plan-execute-review loop. Breaks work into atomic tasks for verification and course-correction.
- **Why relevant:** Multi-tool orchestration at the process level (not plugin level). Interesting complement to kernel's agent orchestration — could coordinate multiple Claude Code instances on different aspects of a problem.
- **Hypothesis:** H-MCGRAV-001: Process-level multi-tool orchestration catches cross-tool integration issues that single-tool agent orchestration misses.

### 11. superpowers-marketplace (obra)
- **URL:** https://github.com/obra/superpowers-marketplace
- **Stars:** 802 | **Activity:** Active (updated 2026-04-07)
- **What:** Curated Claude Code plugin marketplace by obra (Jesse Vincent, prolific open-source maintainer). Quality-filtered plugin discovery.
- **Why relevant:** Curation layer for the plugin ecosystem. If kernel ever publishes plugins, this is the quality marketplace to target. Also useful for discovering vetted plugins.

### 12. plugins-for-claude-natives (Power User Plugins)
- **URL:** https://github.com/team-attention/plugins-for-claude-natives
- **Stars:** 723 | **Activity:** Active (updated 2026-04-07)
- **What:** Claude Code plugins specifically designed for power users — assumes deep familiarity with Claude Code internals.
- **Why relevant:** Target audience overlaps exactly with kernel users. Worth monitoring for novel power-user patterns.

---

## Key Patterns Observed

1. **Multi-model adversarial review is the emerging pattern.** Three independent projects (octopus, review-loop, adversarial-spec) all converge on "don't let the same model family review its own work." Kernel's adversary agent has this blind spot.

2. **Overnight autonomous loops are gaining traction.** ARIS (5.7K stars) proves the "run overnight, come back to results" pattern that kernel's forge command implements. ARIS is framework-agnostic — markdown-only — which is architecturally simpler.

3. **Real-time observability is table stakes.** claude-hud at 17.5K stars means the community considers runtime context monitoring essential, not optional. Kernel's metrics are post-hoc only.

4. **Conversational knowledge extraction complements structured logging.** Ars Contexta's approach (build knowledge from conversation) is orthogonal to AgentDB's approach (structured telemetry). Both have value for cross-session continuity.

5. **LSP-first is validated externally.** cclsp (607 stars) proves demand for reliable LSP in terminal Claude Code, validating kernel's LSP-first philosophy.

---

## Recommended Actions

1. **Evaluate multi-model adversary pattern** — Test octopus or review-loop approach for kernel's adversary agent. Highest potential impact on code quality.
2. **Install claude-hud** — Immediate value for real-time context monitoring during kernel sessions. No integration cost.
3. **Study ARIS patterns** — Their cross-model review loop and autonomous research loop could improve forge command.
4. **Monitor correctless** — Dynamic rigor levels could improve kernel's tier-based review intensity.
