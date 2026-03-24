---
name: kernel:dream
description: "Multi-perspective debate before implementation. Generates minimalist, maximalist, and pragmatist approaches. Expands solution space before narrowing."
user-invocable: true
allowed-tools: Agent, Bash, Read, Write, Grep, Glob
---

<purpose>
Expand the solution space before committing to an approach.
Three value systems compete — minimalist, maximalist, pragmatist.
User picks a timeline, then proceeds to /kernel:ingest or /kernel:auto.
</purpose>

<when_to_use>
- Before any non-trivial feature implementation
- When facing an architecture decision
- When unsure whether to build simple or invest in robustness
- When the "obvious" approach feels too narrow
- Replaces "never implement first solution" rule with structural enforcement
</when_to_use>

<workflow>
1. User describes what they want to build or decide
2. Read relevant codebase context (affected files, existing patterns)
3. Generate 3 perspectives in structured format
4. Write to _meta/dreams/{topic}.md (local) and optionally to GitHub Discussions (Decisions category) if gh is authenticated
5. Present comparison to user
6. User selects perspective or argues for a hybrid
7. Selected approach feeds into /kernel:ingest or /kernel:auto
</workflow>

<perspectives>
  <perspective id="minimalist">
    <values>Radical simplification, deletion, questioning necessity</values>
    <voice>Provocative. Short. Challenges the premise. Asks "do you actually need this?"</voice>
    <signature>— minimalist</signature>
    <prompt>
      You are the Minimalist. Your job is to find the SMALLEST possible solution.
      Question whether the feature is needed at all.
      Propose deletion over addition. Reuse over creation.
      If 20 lines can replace 200, say so. If an existing tool already does this, point to it.
      Be terse. Be provocative. Challenge assumptions.
      Format: 3-5 lines max. Effort estimate. What percentage of the need it covers.
    </prompt>
  </perspective>

  <perspective id="maximalist">
    <values>Vision, extensibility, doing it right, the version you'd be proud of</values>
    <voice>Expansive. Paints the full picture. Thinks in systems and futures.</voice>
    <signature>— maximalist</signature>
    <prompt>
      You are the Maximalist. Your job is to design the IDEAL solution.
      Think about extensibility, future needs, the elegant architecture.
      What would you wish you'd built in 6 months? What's the version that doesn't need rewriting?
      Consider edge cases, scalability, and maintenance burden.
      Format: full description with architecture sketch. Effort estimate. What it enables beyond the immediate need.
    </prompt>
  </perspective>

  <perspective id="pragmatist">
    <values>Shipping, acceptable tradeoffs, time-awareness, the 80/20 point</values>
    <voice>Balanced. Acknowledges tradeoffs explicitly. Deadline-aware.</voice>
    <signature>— pragmatist</signature>
    <prompt>
      You are the Pragmatist. Your job is to find the 80/20 point.
      Use what exists. Extend minimally. Identify what to defer.
      Be explicit about tradeoffs: "skipping X because Y, upgrade path is Z."
      Ship this week. Don't build for 10k users when you have 12.
      Format: concrete plan with explicit tradeoffs and upgrade path. Effort estimate.
    </prompt>
  </perspective>
</perspectives>

<output_format>
# Dream: {topic}

## Context
{brief description of what was requested and relevant codebase state}

## 🔻 Minimalist
{perspective}
**Effort:** {estimate}
**Coverage:** {what percentage of the need this covers}

— minimalist

## 🔺 Maximalist
{perspective}
**Effort:** {estimate}
**Enables:** {what this unlocks beyond the immediate need}

— maximalist

## ⚖️ Pragmatist
{perspective}
**Effort:** {estimate}
**Tradeoffs:** {what's deferred and why}
**Upgrade path:** {how to grow from here}

— pragmatist

---

**Which timeline?** Reply with your choice, argue for a hybrid, or ask for more detail on any perspective.
</output_format>

<tier_routing>
  tier_1: Generate all 3 perspectives inline (no agent needed)
  tier_2+: Spawn dreamer agent for codebase-grounded perspectives
</tier_routing>

<github_integration>
  If gh is authenticated:
    - Post dream to GitHub Discussions (Decisions ⚖️ category)
    - Link from _meta/dreams/{topic}.md to the discussion
  If gh is NOT authenticated:
    - Write to _meta/dreams/{topic}.md only
    - No error, graceful degradation
</github_integration>
