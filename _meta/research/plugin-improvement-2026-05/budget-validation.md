---
name: budget-validation
description: Token budget analysis — are the line caps still correct? Three-source reconciliation + verdict.
type: reference
date: 2026-05-28
---

# Token Budget Validation — 2026-05-28

## The Contradiction Being Resolved

Three sources currently give different numbers for the same thing:

| Source | CLAUDE.md cap | Commands cap | Agents cap | Skills cap |
|--------|--------------|--------------|------------|------------|
| `_meta/research/token-budget-quick-reference.md` | 300L | 250L | 300L | 350L |
| `tests/run-tests.sh` | 400L | 1000L | 250L | (none) |
| Vault `CLAUDE.md` (`hooks/budget-check.sh`) | 120L | — | — | 80L |

Note: `hooks/budget-check.sh` does not exist on disk. The 120L/80L numbers referenced in the Vault CLAUDE.md's budget table refer to a hook that was described but never shipped — its numbers are documentation artefacts, not enforced reality.

Actual current file sizes (measured 2026-05-28):

| File | Lines |
|------|-------|
| `CLAUDE.md` | 308 |
| `commands/landing-page.md` | 923 |
| `commands/experiment.md` | 307 |
| `commands/forge.md` | 268 |
| `commands/ingest.md` | 261 |
| Largest agent (`agents/validator.md`) | 222 |
| Largest skill (`skills/build/SKILL.md`) | 340 |

---

## Question A: Is line-count the right metric?

**Short answer: No. Loaded-vs-reference distinction matters far more.**

Line counts are a proxy for tokens, but a poor one. The real question is:

> Does this file load into the context window on every session, or only when explicitly invoked?

This is the distinction the official Claude Code docs (2026) draw clearly:

- **CLAUDE.md** → loaded every session, full file, no eviction.  
  *"Files over 200 lines consume more context and may reduce adherence."* — official docs (code.claude.com/docs/en/memory)
- **Auto memory (MEMORY.md)** → first 200 lines or 25KB cap, hard-enforced by the runtime.
- **Skills (SKILL.md)** → loaded on demand only. Not in context unless invoked.
- **Agents** → loaded only when spawned. Not in context otherwise.
- **Commands** → loaded only when the user invokes the command.

This means commands, skills, and agents operate under a fundamentally different budget constraint than CLAUDE.md files. A 923-line command file (landing-page.md) costs **zero tokens** in sessions where that command is never invoked. A bloated CLAUDE.md costs its full token weight **in every single session**.

**Implication**: enforcing the same line-count ceiling on always-loaded and on-demand-loaded files is a category error.

---

## Question B: What caps make sense per file class, given 1M context?

### Primary constraint: adherence degradation, not token exhaustion

At 308 lines (~2K tokens), CLAUDE.md uses less than 0.5% of the 1M window. Token exhaustion is not the risk. **Instruction adherence** is.

Official Anthropic guidance (2026, code.claude.com/docs/en/best-practices):
> "Bloated CLAUDE.md files cause Claude to ignore your actual instructions."
> "If Claude keeps doing something you don't want despite having a rule against it, the file is probably too long and the rule is getting lost."

Community measurement corroborates this: CLAUDE.md instructions are followed ~70% of the time; hooks enforce at 100%. Files over ~2000 tokens (roughly 300 lines) show meaningful adherence drop.

Research background: Liu et al. "Lost in the Middle" (2023) and Veseli et al. (2025) both confirm positional attention bias — content in the middle of long context receives less attention. When CLAUDE.md grows long, the rules in the middle get systematically ignored regardless of total window size.

### Recommended caps by file class

**Always-loaded files — adherence-constrained:**

| File | Recommended cap | Rationale |
|------|----------------|-----------|
| Root CLAUDE.md | **250L hard** | Official docs say "target under 200 lines." 250 gives modest buffer for this plugin's density. Already at 308 — needs trimming. |
| Vault CLAUDE.md | **200L** | Loaded on every Vault session. Strict. |
| Project CLAUDE.md | **180L** | Narrower scope; should be more focused. |
| User `~/.claude/CLAUDE.md` | **120L** | Personal prefs only; anything more is noise. |
| Rules files (`.claude/rules/*.md`) | **80L each** | Scoped rules; specificity beats length. |

**On-demand files — quality-constrained, not adherence-constrained:**

| File | Recommended cap | Rationale |
|------|----------------|-----------|
| Commands | **500L soft / 1000L hard** | Only loads when invoked. Quality and clarity still matter; 923L for landing-page is acceptable but is the ceiling, not a target. |
| Agents | **300L** | Spawned per-task; no session overhead, but bloat slows orientation. Current max 222L is healthy. |
| Skills (SKILL.md) | **400L** | On-demand. Current 340L max is at the soft limit. |
| Reference docs | **no cap** | Never auto-loaded. Pure knowledge store. |

### The landing-page.md special case

At 923 lines, `commands/landing-page.md` is an outlier. It exceeds every previously stated cap. However:

1. It loads only when `/kernel:landing-page` is invoked — zero cost otherwise.
2. It encodes a multi-phase interview + scaffold + deploy workflow with embedded templates. That content density is legitimate.
3. The test cap was deliberately raised to 1000L to stop the test suite from flagging it.

Verdict: 923 lines is acceptable for this specific file type (command-as-workflow-document). The 1000L hard cap in run-tests.sh is correct for commands. The previous 250L "recommendation" was appropriate when commands were concise procedure lists, not full workflow documents. The category has evolved.

---

## Question C: Are the three enforcement points reconcilable into one source of truth?

Yes, and the reconciliation is straightforward once the always-loaded vs. on-demand distinction is respected.

### What actually enforces today

Only `tests/run-tests.sh` enforces anything at commit/test time:
- CLAUDE.md: 400L hard (test fails above this)
- Commands: 1000L hard
- Agents: 250L hard
- Skills: not tested

The `hooks/budget-check.sh` file **does not exist**. The Vault CLAUDE.md table references caps for a hook that was never built. Those numbers (root 120L, vault 180L, project 250L, SKILL.md 80L) describe the *intent* of that hook, not a reality. They should either be built as a hook or removed from the Vault CLAUDE.md table to avoid confusion.

The `token-budget-quick-reference.md` numbers (300/250/300/350) reflect the research-era recommendations from early 2026, before landing-page.md and experiment.md grew beyond 250L.

### Recommended single source of truth

Collapse everything into `tests/run-tests.sh` (the only enforcer), updated to reflect the always-loaded/on-demand split:

```
CLAUDE.md (always-loaded):        250L hard (currently 400 — too permissive)
Commands (on-demand):             1000L hard (current — correct)
Agents (on-demand):               300L hard (currently 250 — slightly tight)
Skills (on-demand):               400L soft / test warns, doesn't fail
```

Update `token-budget-quick-reference.md` to reflect these new numbers and the loaded-vs-reference rationale.

Remove the Vault CLAUDE.md cap table or mark it `(hook not yet built)` to stop it from being read as an active constraint.

---

## Concrete Recommended Numbers (Final Verdict)

| File class | Load pattern | Constraint driver | Recommended cap | Current test cap | Delta |
|------------|-------------|------------------|----------------|-----------------|-------|
| Root CLAUDE.md | Every session | Adherence degradation | **250L hard** | 400L | Tighten |
| Commands | On invoke | Quality/clarity | **1000L hard** | 1000L | Match |
| Agents | On spawn | Orientation speed | **300L hard** | 250L | Loosen |
| Skills (SKILL.md) | On invoke | Quality/clarity | **400L warn** | none | Add test |
| Vault/Project CLAUDE.md | Every session | Adherence degradation | **180L hard** | none (not tested) | Add test |
| Rules files | Conditional | Adherence | **80L hard** | none | Add test |

CLAUDE.md at 308L exceeds the recommended 250L. Trimming is warranted. The most deletable content is:
- Anti-pattern blocks that duplicate invariants already in I0
- Agent descriptions that duplicate content in `agents/*.md`
- The `<lsp>` section (already in `_meta/reference/lsp-setup.md`)

---

## What Anthropic's Current Docs Say (Primary Sources)

- **Target under 200 lines per CLAUDE.md file.** Longer files reduce adherence. (code.claude.com/docs/en/memory, 2026)
- **"Bloated CLAUDE.md files cause Claude to ignore your actual instructions."** (code.claude.com/docs/en/best-practices, 2026)
- Skills load on demand — use them for domain knowledge that is only relevant sometimes (best-practices, 2026)
- CLAUDE.md instructions followed ~70% of the time; hooks at 100%. (best-practices, 2026, via MindStudio analysis)
- Prompt caching: 90% cost reduction / 85% latency reduction for static context. Cached tokens do not count against ITPM limits for Sonnet 4.6. (docs.anthropic.com/en/docs/build-with-claude/prompt-caching, 2026)
- 1M context GA on Sonnet 4.6 and Opus 4.6, March 2026, at standard pricing with no long-context premium. (Anthropic announcement, March 2026)
- Context rot: performance gradient, not cliff. Degrades noticeably after 50%+ context fill with *undifferentiated* content. Structured, curated context (like plugin files) degrades more slowly. (Context Rot research, 2025; Veseli et al. 2025)

---

## Action Items

1. **Trim CLAUDE.md from 308 to ≤250 lines.** Target: remove anti-pattern duplication, collapse agent description table, move LSP section to reference-only.
2. **Update `tests/run-tests.sh`**: CLAUDE.md cap 400→250, agents 250→300, add skill test (warn at 400L).
3. **Update `token-budget-quick-reference.md`**: replace old numbers, add loaded-vs-reference column.
4. **Remove or mark the Vault CLAUDE.md cap table** as "unenforced intent" until `budget-check.sh` is built.
5. **Do not reduce command caps.** The 1000L hard cap is correct given the on-demand load pattern. landing-page.md at 923L is acceptable.

---

## Sources

- [How Claude remembers your project — Claude Code Docs](https://code.claude.com/docs/en/memory)
- [Best practices for Claude Code — Claude Code Docs](https://code.claude.com/docs/en/best-practices)
- [Effective context engineering for AI agents — Anthropic Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Prompt caching — Anthropic API Docs](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
- [Your CLAUDE.md is eating your token budget — Medium/@kjramsy](https://medium.com/@kjramsy/your-claude-md-is-eating-your-token-budget-heres-how-to-fix-it-b8d6c4d1c986)
- [Lost in the Middle: How Language Models Use Long Contexts — Liu et al., TACL 2024](https://direct.mit.edu/tacl/article/doi/10.1162/tacl_a_00638/119630/)
- [Context Rot — ProductTalk synthesis, 2025](https://www.producttalk.org/context-rot/)
- [Anthropic 1M context GA announcement — March 2026](https://pasqualepillitteri.it/en/news/1451/anthropic-1m-context-beta-retirement-april-30-2026)
- [Writing a good CLAUDE.md — HumanLayer Blog](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
