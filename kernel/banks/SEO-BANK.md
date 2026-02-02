# AI-SEO Bank

## Philosophy
Optimize for citation, not ranking. AI systems evaluate at the passage level, not the page level. Every section must stand alone as a citable answer. Authority beats volume. Third-party mentions outweigh backlinks. Structure for extraction. Anti-patterns are as important as patterns --- knowing what NOT to do prevents the most common failures. Traditional SEO is the foundation layer, but it is incomplete without explicit AI citation optimization.

## Process Skeleton
1. **Audit** → Assess current AI-readiness (technical, content, authority, measurement)
2. **Structure** → Optimize content architecture for AI extraction at passage level
3. **Authority** → Build third-party presence and E-E-A-T trust signals
4. **Technical** → Ensure SSR, schema, crawler access, performance targets
5. **Measure** → Track AI-native metrics (citation frequency, BVS, SOV, sentiment)
6. **Maintain** → 90-day refresh cycle, semantic freshness, continuous monitoring

---

## Slots (Designed to Fill)

### AI Readiness Audit Checklist (8 phases)
[TO EVOLVE: Add site-specific audit findings and benchmarks]

**Phase 1: Baseline Assessment**
- [ ] Search brand in ChatGPT, Perplexity, Gemini --- are you cited?
- [ ] Test 20-50 relevant prompts, track Brand Visibility Score
- [ ] Identify which pages are cited vs ignored
- [ ] Check AI referral traffic in GA4 (custom dimensions)
- [ ] Review server logs for AI crawler activity (GPTBot, ClaudeBot, PerplexityBot)

**Phase 2: Technical AI Readiness**
- [ ] JavaScript rendering audit --- content visible in raw HTML without JS?
- [ ] SSR or prerendering in place for all content pages?
- [ ] robots.txt allows citation crawlers (ChatGPT-User, PerplexityBot)?
- [ ] TTFB under 200ms?
- [ ] Core Web Vitals: LCP < 2.5s, CLS < 0.1, INP < 200ms?
- [ ] Indexed on Bing? (Critical: ChatGPT and Perplexity pull from Bing)

**Phase 3: Content Architecture**
- [ ] Direct answers in first 100-150 words?
- [ ] Each major section answers a question independently?
- [ ] At least one table or list per 500 words?
- [ ] Logical H1-H6 heading hierarchy?
- [ ] Content in ~800-token extractable blocks?
- [ ] FAQ sections with conversational Q&A?

**Phase 4: Structured Data**
- [ ] JSON-LD schema server-side rendered (not JS-injected)?
- [ ] Schema passes Google Rich Results Test?
- [ ] Entity disambiguation with @id and sameAs?
- [ ] Priority types: Article, FAQPage, HowTo, Organization, Person?

**Phase 5: E-E-A-T Signals**
- [ ] Author pages with credentials, certifications, LinkedIn?
- [ ] About page with comprehensive trust signals?
- [ ] Expert review noted visibly on content?
- [ ] Original research or first-party data present?
- [ ] Claims supported with citations to authoritative sources?

**Phase 6: Third-Party Presence**
- [ ] Reddit: genuine expertise contributions in relevant subreddits?
- [ ] YouTube: tutorials, demos, expert content?
- [ ] Review platforms: active on G2, Trustpilot, industry-specific sites?
- [ ] Industry publications: quoted in analyst reports?
- [ ] Organization schema sameAs links to all profiles?

**Phase 7: Content Freshness**
- [ ] Last updated dates visible and parseable?
- [ ] High-priority pages refreshed every 90 days?
- [ ] Updates are substantive (new data, case studies), not cosmetic?

**Phase 8: Multimodal Readiness**
- [ ] Alt text with semantic meaning (not keyword labels)?
- [ ] Image quality high (no heavy compression)?
- [ ] Video transcripts available?
- [ ] VideoObject schema implemented?

---

### Content Architecture Patterns (What Works)
[TO EVOLVE: Add content patterns that earn citations in THIS site's domain]

**Answer-First Structure:**
```
H2: [Question as heading]
[Direct answer in first 100-150 words]
[Supporting evidence: statistics, citations, examples]
[Edge cases, caveats, alternatives]
[Related questions]
```
Content with direct answers is 40% more likely to be cited (Princeton GEO study).

**Passage-Level Optimization:**
- Break content into ~800-token blocks (optimal for embedding efficiency)
- Each block must answer a specific question independently
- Bold key terms and definitions immediately after headings
- One table or list per 500 words minimum

**Information Gain:**
- Unique angles the AI cannot find elsewhere
- Original data, proprietary research, first-person experience
- Expert interviews with quoted analysis
- If 10 articles say the same thing, differentiate or don't publish

**Entity Optimization:**
- Define entities clearly on first mention
- Use schema.org markup to disambiguate
- Maintain consistent entity references
- Link entities to authoritative knowledge bases

**GEO Methods That Work (Princeton study data):**
| Method | Visibility Impact | Best Domain |
|--------|------------------|-------------|
| Statistics Addition | +25.4% | Law & Government |
| Citation/Sources | Up to +40% | All domains |
| Expert Quotes | +22.3% | People & Society, History |
| Fluency Optimization | Significant | All domains |
| Authoritative Tone | Moderate | Technical content |
| Unique/Original Data | High | All domains |
| Fluency + Statistics | +5.5% over single methods | All domains |

---

### Content Anti-Patterns (What Doesn't Work)
[TO EVOLVE: Add content failures observed in THIS site's analytics]

**Tier 1: Actively Harmful (Stop Immediately)**

| Anti-Pattern | Evidence | Why It Hurts |
|---|---|---|
| Keyword stuffing | Princeton: -10% visibility | LLMs read semantics, not frequency; degrades readability |
| Off-topic content at scale | HubSpot: -75% traffic loss | Google evaluates collectively; garbage drags down expert content |
| Mass unedited AI content | Google scaled content abuse | Detected as synthetic similarity; penalized collectively |
| Volume-optimized calendars | Domain authority dilution | Depth and authority beat breadth for citation |

**Tier 2: Wasted Effort (Low/No ROI)**

| Anti-Pattern | Evidence | Why It Fails |
|---|---|---|
| CTR manipulation | Zero signal pathway | LLMs don't observe click behavior |
| Meta tag manipulation for AI | AI crawlers ignore them | Crawlers parse body content, not metadata tricks |
| llms.txt for citations | SE Ranking 300K study: no effect | No LLM lab honors it; Google has no plans to support |
| Link building schemes for AI | 0.218 correlation | Mentions (0.664) matter 3x more than backlinks |
| Optimizing for one AI model | 86% of top sources platform-unique | Each model trusts different signals |

**Tier 3: Common Misconceptions**

| Misconception | Reality |
|---|---|
| Schema guarantees AI citation | Helps at margins; not a silver bullet; some LLMs ignore it |
| More pages = more AI visibility | Depth and topical authority beat breadth |
| Backlinks = AI authority | Brand mentions and third-party discussion matter more |
| Traditional metrics measure AI success | Rankings, traffic, CTR all mislead about AI performance |
| AI SEO is a separate discipline | It's content strategy with different measurement |
| Listicles without substance | AI can generate these itself; no reason to cite yours |
| Duplicate/near-duplicate content | AI can't determine which is authoritative; may skip all |
| Overly sales-focused content | AI filters for informational quality, not sales pitches |
| Surface-level answers only | Content must address second-order questions to stay cited |
| Copying competitor AI content | Google detects synthetic similarity; homogeneous content cluster = no citation preference |

---

### Technical SEO Checklist
[TO EVOLVE: Add technical findings specific to THIS site's stack]

**Critical: AI Crawlers Cannot Execute JavaScript**
- GPTBot (OpenAI): no JS rendering
- ClaudeBot (Anthropic): text-based parsing only
- PerplexityBot: HTML snapshots only, no JS execution
- Googlebot: the exception (renders JS)

**Test:** Disable JavaScript in browser. If content disappears, AI crawlers can't see it.

**SSR Solutions (priority order):**
1. Server-Side Rendering: Next.js, SvelteKit, Nuxt
2. Static Site Generation: Astro, Hugo, Gatsby
3. Pre-rendering for bots: Prerender.io
4. HTML-first: critical content accessible without JS

**robots.txt Strategy:**
```
# Allow citation-generating crawlers
User-agent: ChatGPT-User
Allow: /

User-agent: PerplexityBot
Allow: /

# Strategically control training bots
User-agent: GPTBot
Allow: /blog/
Allow: /docs/
Disallow: /internal/

User-agent: ClaudeBot
Allow: /blog/
Allow: /docs/
Disallow: /internal/
```

**Performance Targets:**
| Metric | Target | Why |
|--------|--------|-----|
| TTFB | < 200ms | LLM retrieval has tight latency budgets |
| LCP | < 2.5s | Core Web Vitals signal quality |
| CLS | < 0.1 | Stability signal |
| INP | < 200ms | Responsiveness signal |

**Schema Priority Types:**
| Type | AI Impact |
|------|-----------|
| Article | E-E-A-T reinforcement |
| FAQPage | Direct AI Overview/PAA feed |
| HowTo | Easy extraction and citation |
| Organization | Brand entity recognition |
| Person | Author authority signals |
| Product | LLM product recommendation |
| LocalBusiness | Local AI visibility |
| Speakable | Voice/AI assistant readiness |
| VideoObject | Multimodal understanding |

**Schema Rules:**
1. Server-side render ALL schema (never JS-injected)
2. Use @id for entity disambiguation
3. Connect entities with sameAs to trusted profiles
4. Validate with Google Rich Results Test
5. Schema must match actual visible content

---

### Third-Party Presence Strategy
[TO EVOLVE: Add platform-specific findings for THIS brand/niche]

**Why This Matters:**
- 85% of brand citations come from third-party pages, not owned domains
- Brands on 4+ non-affiliated platforms are 2.8x more likely to appear in ChatGPT
- Brand mentions correlation: 0.664 vs backlinks: 0.218

**Platform Priority:**

| Platform | AI Citation Rate | Strategy |
|----------|-----------------|----------|
| Reddit | 14-38% of LLM responses | Genuine expertise in relevant subreddits (not promotion) |
| YouTube | Top-3 across all LLMs | Tutorials, demonstrations, expert commentary |
| Wikipedia | 47.9% of ChatGPT citations | Accurate presence if relevant; follow notability guidelines |
| G2/Review Sites | +2% AI citations per 10% review increase | Active review solicitation and response |
| Industry Publications | High authority signal | Contribute analysis, respond to journalist inquiries (HARO, Qwoted) |
| LinkedIn | Growing signal | Thought leadership articles from named experts |

**Model-Specific Trust Sources:**
| Model | Primary Trust Source | Optimization Focus |
|-------|---------------------|-------------------|
| ChatGPT | Third-party directories (48.73%) | Yelp, TripAdvisor, G2, Capterra |
| Gemini | Brand-owned websites (52.15%) | Structured, factual brand content, schema |
| Perplexity | Industry-specific niche sources (24%) | Expert reviews, specialized knowledge |
| Claude | Expert-level authority | Factual honesty; doesn't auto-favor popular brands |

**Anti-Pattern:** Ignoring third-party presence while only optimizing your own site. This is the single largest strategic blind spot in AI-SEO.

---

### Measurement Framework
[TO EVOLVE: Add benchmark data and tracking cadence for THIS site]

**AI-Native Metrics (replace traditional where applicable):**

| Metric | Definition | Cadence |
|--------|-----------|---------|
| Citation Frequency | How often cited in AI responses | Weekly |
| Brand Visibility Score (BVS) | % of relevant prompts where brand appears | Weekly (250-500 prompt sample) |
| AI Share of Voice (SOV) | Your citations vs competitors | Monthly |
| Sentiment Analysis | Accuracy and tone of AI mentions | Monthly |
| LLM Conversion Rate | Conversions from AI discovery | Continuous |

**Tracking Methodology:**
1. Define 250-500 high-intent queries as population proxy
2. Run queries weekly across ChatGPT, Perplexity, Gemini, Google AI Overviews
3. Track citation presence, positioning, sentiment
4. Monitor two-step discovery: AI mention → branded Google search → site visit

**GA4 Setup:**
- Custom dimensions for LLM referral sources
- Track: `chat.openai.com`, `perplexity.ai`, `copilot.microsoft.com`
- Monitor branded homepage traffic correlated with LLM presence

**Tools (2026):**
- Enterprise: Semrush AI Visibility Toolkit, BrightEdge
- Specialized: OtterlyAI, LLMrefs, Peec AI, Nightwatch, Profound
- Budget: Manual prompt testing + GA4 custom dimensions

**Anti-Pattern:** Using only traditional metrics (rankings, traffic, CTR). These actively mislead about AI performance. Rankings can improve while AI visibility decreases.

---

### Content Refresh Strategy
[TO EVOLVE: Add refresh findings and decay patterns for THIS site]

**The 90-Day Rule:**
- Content updated within 90 days performs best across all AI platforms
- Pages not updated quarterly see citation drops of 40-60%
- 70%+ of ChatGPT-cited pages updated within 12 months
- AI-cited content is 25.7% fresher than organic Google results

**Content Decay Timeline:**
| Period | What Happens |
|--------|-------------|
| Weeks 1-4 | Newly published/refreshed content cited frequently |
| Weeks 5-12 | Citation frequency begins declining |
| Weeks 13-26 | AI starts citing competitors' fresher content |
| 26+ weeks | Significant citation loss without substantive refresh |

**Refresh Requirements (substantive, not cosmetic):**
- Add new data, statistics, case studies
- Include recent developments and expert perspectives
- Update examples and references
- Visible "last updated" metadata (AI systems parse this)

**Anti-Pattern:** Cosmetic refreshes (changing dates, rewording sentences, adding minor sections). AI systems distinguish meaningful updates from surface changes. Semantic recency matters, not just date recency.

---

### E-E-A-T Signal Optimization
[TO EVOLVE: Add E-E-A-T findings specific to THIS brand's niche]

**Experience:** First-hand knowledge signals
- Original photos, test results, case studies
- "What We Tested" / "What We Found" sections
- Language patterns showing direct involvement

**Expertise:** Demonstrable knowledge
- Correct use of technical terms with definitions
- In-depth explanations beyond the obvious
- Understanding of "why" not just "what"

**Authoritativeness:** External recognition
- Media coverage (strongest authority signal)
- Cited by credible third-party sources
- Industry awards, certifications
- Consistent topical publishing in niche

**Trustworthiness:** Transparency signals
- Detailed About page, author bios, contact info
- HTTPS, accurate information, clear sourcing
- Visible credentials and review processes

**Anti-Pattern:** Fabricating E-E-A-T signals. Once detected, permanently erodes brand trust with both search engines and AI models. Build genuine authority.

---

### Platform-Specific Optimization
[TO EVOLVE: Add platform findings as AI search landscape changes]

**Key Market Data (January 2026):**
| Platform | Market Share | Weekly Users | Avg Citations/Response |
|----------|-------------|-------------|----------------------|
| ChatGPT | 64.5-68% | 800M | 10.42 |
| Google Gemini | 18-21.5% | N/A | 9.26 |
| Perplexity | ~2% (15.1% AI referral traffic) | N/A | 5.01 |
| Google AI Overviews | 55%+ of searches | N/A | Varies |

**Critical Context:**
- Google still sends 345x more traffic than all AI chatbots combined
- AI referral traffic = ~1% of publisher traffic (growing fast)
- LLM visitors convert at 4.4x the rate of organic visitors
- Traditional search volume forecast to drop 25% by end of 2026

**Anti-Pattern:** Abandoning traditional SEO for AI-only optimization. Most AI retrieval systems pull from traditional search indexes. Traditional SEO IS the foundation of AI visibility.

---

## Failure Handling

### Content Not Getting Cited
1. Check technical basics first (SSR, crawler access, Bing indexation)
2. Verify content structure (answer-first, standalone sections)
3. Audit E-E-A-T signals (author pages, citations, expert review)
4. Check third-party presence (Reddit, YouTube, review sites)
5. Compare against competitors who ARE getting cited
6. Check freshness (within 90-day window?)

### Losing Existing Citations
1. Check for content staleness (> 90 days without substantive update)
2. Verify no technical regression (SSR broken, crawlers blocked)
3. Look for competitor freshness advantage
4. Check if AI platform algorithm changed (common)
5. Review model-specific differences (may still be cited on some platforms)

### Anti-Pattern Remediation Priority
1. Fix technical blockers first (SSR, crawler access)
2. Remove actively harmful patterns (keyword stuffing, off-topic content)
3. Add missing signals (schema, author pages, citations in content)
4. Build third-party presence (longest lead time)
5. Establish measurement (can't improve what you can't measure)

---

## Quick Reference: DO vs DON'T

| DO | DON'T |
|----|-------|
| Answer-first content structure | Keyword stuff for density |
| ~800-token extractable passages | Content walls without structure |
| Include statistics, citations, expert quotes | Generic listicles AI can self-generate |
| Server-side render everything | Client-side only rendering |
| Build presence on 4+ third-party platforms | Only optimize your own website |
| Refresh content every 90 days | Cosmetic date changes |
| Track AI citation metrics | Rely only on traditional rankings |
| Optimize for multiple AI models | Optimize for ChatGPT only |
| Produce original research and data | Copy competitor content |
| Maintain topical authority depth | Chase off-topic volume |
| Use semantic HTML and proper headings | Hide content behind JS or popups |
| Allow citation crawlers in robots.txt | Block all AI crawlers |
| Build genuine E-E-A-T signals | Fabricate authority signals |
| Validate schema against visible content | Add schema that contradicts page content |

---

## Template Notice
This bank is scaffolding. Fill slots as you optimize sites for AI search in this domain.
Move stable AI-SEO patterns to `.claude/rules/patterns.md` when they repeat.
Respect caps; if full, replace least valuable or promote to rules.
