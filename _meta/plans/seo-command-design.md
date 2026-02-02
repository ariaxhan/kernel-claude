# Design Plan: /seo Command + AI-SEO Bank

**Date:** 2026-01-30
**Status:** Implementation
**Research:** `_meta/docs/ai-seo-research.md`, `_meta/docs/ai-seo-antipatterns.md`, `_meta/docs/ai-seo-sources.md`

---

## Goal

Add a new `/seo` command and `SEO-BANK.md` to KERNEL that provides AI-age SEO optimization methodology. Focus on AI citation optimization (GEO/AEO/LLMEO), not traditional keyword-based SEO. Include comprehensive anti-patterns.

## Done-When

- [ ] `kernel/banks/SEO-BANK.md` created following existing bank format
- [ ] `commands/seo.md` created following existing command format
- [ ] `.claude/rules/methodology.md` updated with SEO trigger
- [ ] `CLAUDE.md` updated with new counts (15 commands, 11 banks)
- [ ] `.claude-plugin/plugin.json` updated (version bump, description)
- [ ] All files follow existing patterns exactly

## Design Decisions

### Bank Design: SEO-BANK.md

**Structure follows existing bank pattern:**
- Philosophy section (citation > ranking, passage-level, authority > volume)
- Process Skeleton (6 phases: Audit → Structure → Authority → Technical → Measure → Maintain)
- Slots with [TO EVOLVE] markers
- Anti-patterns section (critical differentiator - what NOT to do)
- Checklists and templates

**Key differentiator from other banks:**
- Dual structure: DO + DON'T for every category
- Heavily data-backed (Princeton GEO study citations, specific metrics)
- Platform-specific guidance (ChatGPT vs Gemini vs Perplexity)
- Technical requirements (SSR, schema, robots.txt)

### Command Design: seo.md

**Modes (following /design pattern):**
- `/seo audit` - Full AI-readiness audit (8 phases)
- `/seo optimize` - Content optimization for AI citation
- `/seo technical` - Technical SEO for AI crawlers
- `/seo authority` - Third-party presence strategy
- `/seo measure` - AI visibility metrics setup
- `/seo refresh` - Content freshness audit

**Tools allowed:** Read, Write, Edit, Glob, Grep, Bash, Task, WebFetch, WebSearch

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `kernel/banks/SEO-BANK.md` | CREATE | New methodology bank |
| `commands/seo.md` | CREATE | New command |
| `.claude/rules/methodology.md` | MODIFY | Add SEO trigger section |
| `CLAUDE.md` | MODIFY | Update counts |
| `.claude-plugin/plugin.json` | MODIFY | Version bump |

## Research Summary

### What Works (from Princeton GEO + industry data)
- Statistics addition: +25.4% visibility
- Citation/source addition: up to 40% boost
- Expert quotes: +22.3%
- Answer-first structure: 40% more likely cited
- ~800-token passage blocks optimal
- 90-day content refresh cycle
- Schema markup: 2.5x higher AI answer appearance
- Third-party presence: 85% of brand citations from 3rd party

### What Doesn't Work (anti-patterns)
- Keyword stuffing: -10% visibility (actively harmful)
- Off-topic content at scale: HubSpot lost 75% traffic
- Client-side rendering only: invisible to AI crawlers
- llms.txt: no proven citation impact (300K domain study)
- CTR manipulation: zero signal pathway to LLMs
- Link building schemes: 0.218 correlation vs 0.664 for mentions
- Optimizing for single AI model: 86% of top sources platform-unique

### Platform Differences
- ChatGPT: trusts third-party directories (Yelp, TripAdvisor)
- Gemini: trusts brand-owned websites (52.15%)
- Perplexity: trusts niche expert sources
- Claude: expert-level authority, doesn't auto-favor popular brands
