---
description: AI-age SEO optimization - audit, optimize, and measure AI search visibility
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, WebFetch, WebSearch
---

# SEO Mode

Activated for AI-age search optimization. Focuses on citation optimization (GEO/AEO/LLMEO), not traditional keyword-based SEO.

## Startup

1. Read `kernel/banks/SEO-BANK.md` (methodology + anti-patterns)
2. Read `kernel/state.md` for current site context
3. If available, detect site stack (SSR framework, schema setup, CMS)

## Context Gathering

Before any SEO work:

```
[] What is the site/content being optimized?
[] What framework/stack (SSR capability)?
[] What CMS or content workflow exists?
[] What are the target topics/queries?
[] What AI platforms matter most for this audience?
[] Is there existing analytics (GA4, Search Console)?
```

## Modes

### `/seo audit`

Full AI-readiness audit across 8 phases from the bank:

1. **Baseline** - Check if AI engines already cite the content
2. **Technical** - JS rendering, SSR, robots.txt, performance, Bing indexation
3. **Content Architecture** - Answer placement, standalone sections, heading hierarchy
4. **Structured Data** - JSON-LD, schema types, entity disambiguation
5. **E-E-A-T** - Author pages, trust signals, expert review, original research
6. **Third-Party** - Reddit, YouTube, review platforms, industry publications
7. **Freshness** - Update dates, refresh cadence, semantic recency
8. **Multimodal** - Alt text, image quality, video transcripts

Output findings with severity levels and prioritized fix plan.

### `/seo optimize <target>`

Content optimization workflow:

1. **Analyze** - Read target content, assess current structure
2. **Check Anti-Patterns** - Scan for actively harmful patterns from bank
3. **Restructure** - Apply answer-first architecture, ~800-token passages
4. **Enrich** - Add statistics, citations, expert perspectives where missing
5. **Schema** - Implement or fix structured data (server-side)
6. **Validate** - Verify extraction score, heading hierarchy, standalone section value

Output optimized content with change rationale.

### `/seo technical`

Technical audit focused on AI crawler readiness:

```
CHECK:
- JavaScript rendering (disable JS test)
- Server-side rendering status
- robots.txt AI crawler configuration
- TTFB < 200ms
- Core Web Vitals (LCP, CLS, INP)
- Bing indexation status
- Schema server-side rendering
- Content in initial HTML response
- Lazy-loaded text (invisible to crawlers)
- Infinite scroll pagination
```

Output technical findings with implementation fixes.

### `/seo authority`

Third-party presence and E-E-A-T audit:

1. **Brand Search** - Test brand in ChatGPT, Perplexity, Gemini, Google AI Overviews
2. **Third-Party Scan** - Reddit mentions, YouTube presence, review platforms, Wikipedia
3. **E-E-A-T Assessment** - Author pages, credentials, citations, expert signals
4. **Gap Analysis** - Compare against competitors' third-party presence
5. **Strategy** - Prioritized plan for building citation-worthy authority

Output authority report with platform-specific recommendations.

### `/seo measure`

Set up AI visibility tracking:

1. **Define Queries** - Build 250-500 prompt sample for Brand Visibility Score
2. **GA4 Setup** - Custom dimensions for AI referral sources
3. **Tool Recommendations** - Based on budget and needs
4. **Baseline Metrics** - Run initial BVS, citation frequency, SOV measurement
5. **Dashboard** - Tracking template with cadence schedule

Output measurement framework with implementation steps.

### `/seo refresh`

Content freshness audit and update plan:

1. **Identify Stale** - Pages not updated in 90+ days
2. **Prioritize** - By traffic, citation history, and business value
3. **Refresh Plan** - Substantive updates needed per page
4. **Anti-Pattern Check** - Flag cosmetic-only refreshes
5. **Schedule** - Rolling 90-day refresh calendar

Output refresh plan with per-page update requirements.

## Agent Spawning

For comprehensive SEO work, spawn:

| Task | Agent | Model |
|------|-------|-------|
| Technical audit | build-validator | haiku |
| Content analysis | code-reviewer | sonnet |
| Schema validation | type-checker | haiku |
| Authority research | deep-diver | opus |
| Measurement setup | general-purpose | sonnet |

## Anti-Pattern Enforcement

When generating ANY SEO recommendation, automatically check:

```
REJECT IF:
- Recommends keyword density optimization
- Suggests buying links for AI visibility
- Proposes CTR manipulation
- Recommends llms.txt as citation driver
- Optimizes for single AI platform only
- Suggests cosmetic-only content refreshes
- Recommends blocking AI crawlers
- Proposes volume-over-quality content strategy
- Uses client-side-only schema injection
- Ignores third-party presence
```

Suggest evidence-based alternatives from bank.

## Output

```
## SEO: {mode} - {target}

Context:
- Site: {detected}
- Stack: {detected}
- AI Visibility Baseline: {measured or TBD}

Work Completed:
- {description}

Anti-Patterns Found:
- Actively Harmful: {count}
- Wasted Effort: {count}
- Fixed: {count}
- Remaining: {list with rationale}

Recommendations:
- Priority 1 (Technical Blockers): {list}
- Priority 2 (Content Architecture): {list}
- Priority 3 (Authority Building): {list}
- Priority 4 (Measurement): {list}

Metrics to Track:
- Citation Frequency: {baseline}
- Brand Visibility Score: {baseline}
- AI Share of Voice: {baseline}

Next Review: {date, 90 days out}

Files:
- {file}: {change summary}
```

---

*Citation is the new ranking. Passage is the new page. Authority is the new backlink.*
