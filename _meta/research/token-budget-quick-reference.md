# Token Budget Quick Reference

## Current State

| Metric | Value | Status |
|--------|-------|--------|
| Context Window | 1M tokens | ✅ Unlimited for practical use |
| Bundle Overhead (all files) | 32,650 tokens | 3.3% of capacity |
| Per-session typical | <200K tokens | Negligible context rot |
| Safety margin | 50-100K tokens | Compaction triggers |

## Rules

**Guardrails (not hard limits):**
- CLAUDE.md: ≤300 lines (~1.95K tokens)
- Commands: ≤250 lines (~1.6K tokens each)
- Agents: ≤300 lines (~1.95K tokens each)
- Skills: ≤350 lines (~2.3K tokens each)

**Loading discipline:**
1. Commands load by task type (never all)
2. Skills load on-demand (except `quality`)
3. Agents load when spawned (except researcher+surgeon pair)
4. Compaction checkpoint at 250K tokens

## Key Insight

Context rot is a **performance gradient, not a cliff**. At 1M tokens available and 33K used, you're operating in "negligible degradation" zone. The real constraint is architectural discipline (curated loading), not token quantity.

## Anthropic Validated Patterns

✅ Structured context ordering (session-start.sh)
✅ Granular feature loading (commands/agents/skills)
✅ Session state management (AgentDB + git)
✅ Compaction checkpoints (handoff command)
✅ Token awareness (limits enforce design)

## When to Increase Limits

- If a component's natural composition requires >250 lines for clarity
- If refactoring creates unavoidable duplication
- Never: to "use more space just because it's there"

## When to Trigger Compaction

- Session exceeds 250K tokens
- Conversation history >50 turns with repeated context
- Before handing off to next session
- Every 2 hours of sustained work

---

**Reference:** /Users/ariaxhan/Downloads/Vaults/CodingVault/kernel-claude/_meta/research/token-budget-research.md

