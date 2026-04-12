# Landing Page Command — Experiment Design

**Status:** Ready to run against a real WordPress site via /kernel:experiment
**Commands under test:** /kernel:landing-page + convert-site (private)
**Total hypotheses:** 30 (20 from landing-page, 10 from convert-site)

---

## Experiment Groups

### GROUP A: From-Scratch Generation (test /kernel:landing-page)

These experiments generate a landing page from scratch and measure output quality.

---

#### Experiment A1: Content Architecture

**Tests:** H-LP-CONTENT-SINGLE, H-LP-HYDRATION, H-LP-E02

**Variation 1 — Single content.js with data-content hydration:**
Generate a 5-section landing page using the content.js + data-content pattern.
Measure: Can a non-technical person (simulate: grep for where to change the hero headline) find and edit the right place in under 30 seconds?

**Variation 2 — Content embedded in HTML with clear comments:**
Generate the same 5-section page with content directly in HTML, marked by `<!-- EDIT: headline -->` comments.
Measure: Same editability test. Also: line count, duplication.

**Variation 3 — Multiple content files (content/hero.js, content/features.js):**
Generate with per-section content files.
Measure: Editability, import complexity, error surface.

**Pass criteria:**
- Editability: target string findable by grep in <2 commands
- No duplication: content appears in exactly 1 place
- Hydration works: page renders correctly in browser with no JS errors

**Verdict determines:** Whether H-LP-CONTENT-SINGLE and H-LP-HYDRATION survive or get killed/mutated.

---

#### Experiment A2: Token System Depth

**Tests:** H-LP-TOKENS, H-LP-E01

**Variation 1 — 3-tier tokens (primitives → semantics → components):**
Generate tokens.css with the full 3-tier system from the command spec.
Measure: How many CSS var() references in HTML? Any hardcoded values leak?

**Variation 2 — 2-tier tokens (semantics only, no primitives):**
Generate tokens.css with semantic names directly mapping to hex values.
E.g., `--surface: #F9FAFB` instead of `--surface: var(--color-neutral-50)`.
Measure: Same metrics. Also: cognitive load to change the primary brand color.

**Variation 3 — Flat variable list (no tiers):**
Generate tokens.css as a flat list of 50+ variables with no grouping.
Measure: Same metrics. Time to find and change "the card background color."

**Pass criteria:**
- Changing brand color requires editing ≤3 lines
- Zero hardcoded hex in HTML (grep check)
- Dark mode toggle works without touching any component styles

---

#### Experiment A3: File Structure

**Tests:** H-LP-STRUCTURE, H-LP-SECTION-FILES, H-LP-NOBUILD

**Variation 1 — Monolithic index.html (command spec default):**
Single HTML file with section comments, content.js, tokens.css, main.css.
Measure: Total file count, line count of largest file, deploy simplicity.

**Variation 2 — Section fragments via HTML imports (experimental):**
header.html, hero.html, features.html assembled via JS fetch().
Measure: Same metrics. Also: does it work without a server? (file:// protocol)

**Variation 3 — Vite + React (framework baseline):**
Same content/design but using React components with Vite.
Measure: Same metrics. Also: npm install time, build time, failure modes.

**Pass criteria:**
- Opens correctly via file:// protocol (no server needed)
- Deploy = single command, <5 seconds
- Largest file ≤600 lines
- Non-technical person can locate and edit content

---

#### Experiment A4: Dark Mode Strategy

**Tests:** H-LP-DARKMODE, H-LP-TOKENS (dark section)

**Variation 1 — CSS custom property override (command spec default):**
`[data-theme="dark"]` overrides all `--` variables. JS toggle + localStorage.
Measure: Flash of wrong theme on load? Transition smoothness? Lines of CSS for dark mode?

**Variation 2 — Tailwind dark: prefix only:**
Use `dark:bg-neutral-900 dark:text-neutral-100` on every element.
Measure: Same metrics. HTML bloat? Missed elements?

**Variation 3 — @media (prefers-color-scheme) only, no toggle:**
System-preference-only dark mode. No manual toggle.
Measure: Same metrics. User satisfaction (can't override)?

**Pass criteria:**
- No flash of wrong theme on page load
- All text readable in both modes (contrast check)
- Toggle state persists across page reload

---

#### Experiment A5: Font Pairing

**Tests:** H-LP-FONTS, H-LP-E10

**Variation 1 — Space Grotesk + EB Garamond (modelmind pairing):**
**Variation 2 — DM Sans + DM Serif Display:**
**Variation 3 — Instrument Sans + Instrument Serif:**
**Variation 4 — System font stack (no Google Fonts):**

Generate identical page content with each font pair.
Measure: Page load time (with/without font CDN), visual distinctiveness
(does it look like "every other AI site"?), font swap flash.

**Pass criteria:**
- Font loads in <500ms on 3G simulation
- Visual identity is distinct (not generic AI aesthetic)
- display=swap prevents invisible text

---

### GROUP B: Site Conversion (test convert-site)

These experiments convert a real WordPress site and measure fidelity.

**Prerequisite:** User provides a WordPress URL to convert.

---

#### Experiment B1: CSS-First vs Screenshot-First

**Tests:** H-CS-CSS-FIRST, H-CS-CSSREF

**Variation 1 — CSS-first (download all CSS, generate reference, then convert):**
Follow the full convert-site Phase 1-2 process.
Measure: Visual fidelity score across 10 dimensions. Time to first acceptable output.

**Variation 2 — Screenshot-first (take screenshots, give to agent, convert):**
Skip CSS download. Give agents only screenshots and raw HTML.
Measure: Same metrics. Count of visual fidelity failures.

**Pass criteria:**
- ≥8/10 visual fidelity dimensions pass on first generation
- Container width matches within 5px
- Button styles match (radius, shadow, font)

---

#### Experiment B2: Template Discovery Impact

**Tests:** H-CS-TEMPLATES

**Variation 1 — Template discovery first (analyze all pages, group, build templates):**
Spend 5 minutes analyzing page structure before writing any code.
Measure: Total code output, duplication, time to convert all pages.

**Variation 2 — Page-by-page conversion (convert each page independently):**
Convert each page as a standalone, no template analysis.
Measure: Same metrics. Code duplication across pages.

**Pass criteria:**
- Template approach produces ≥40% less code
- All pages maintain visual consistency
- Adding a new page in template approach takes <5 minutes

---

#### Experiment B3: Content Extraction Method

**Tests:** H-CS-STRIP, H-CS-AGENT-CONSTRAINTS

**Variation 1 — Full HTML to agent:**
Give agent the complete WordPress HTML (all boilerplate included).
Measure: Output quality, conversion time, errors.

**Variation 2 — Content-only HTML to agent:**
Strip WordPress boilerplate first, give clean HTML.
Measure: Same metrics.

**Variation 3 — Pre-digested content (structured markdown) to agent:**
Extract content into structured format, give agent content + CSS reference.
Measure: Same metrics.

**Pass criteria:**
- Agent produces correct output in ≤2 attempts
- No WordPress-specific classes in output
- Content is 100% preserved (no dropped sections)

---

#### Experiment B4: Static vs React Threshold

**Tests:** H-CS-THRESHOLD

**Variation 1 — Convert a 3-page site to static HTML:**
**Variation 2 — Convert the same 3-page site to React+Vite:**
**Variation 3 — Convert a 10-page site to static HTML:**
**Variation 4 — Convert the same 10-page site to React+Vite:**

Measure for each: generation time, file count, maintainability (add a new page),
deploy complexity, total lines of code.

**Pass criteria:**
- ≤5 pages: static is faster to generate AND easier to maintain
- >5 pages: React+Vite shows measurable maintainability advantage

---

#### Experiment B5: Agent Orchestration for Conversion

**Tests:** H-CS-AGENT-CONSTRAINTS

**Variation 1 — Single agent converts all pages:**
One agent, sequential page conversion.
Measure: Time, quality, context window pressure.

**Variation 2 — Parallel agents (1 per page) with shared component library:**
Build shared components first, then 3-6 parallel agents convert pages.
Measure: Same metrics. Merge conflicts?

**Variation 3 — Parallel agents with CSS reference + 200-line constraint:**
Same as V2 but agents get CSS reference doc and max 200-line output constraint.
Measure: Same metrics. Output quality improvement?

**Pass criteria:**
- Parallel with constraints produces best quality/time ratio
- Zero merge conflicts (agents touch different files)
- Each agent output ≤200 lines

---

### GROUP C: Deployment (test both commands)

#### Experiment C1: Cloudflare Pages Deploy

**Variation 1 — wrangler deploy (direct):**
**Variation 2 — git push to CF Pages (auto-deploy from repo):**

Measure: Deploy time, setup complexity, rollback ease.

---

## Execution Order

When given a WordPress URL:

1. **Run B1** first (CSS-first vs screenshot-first) — this has the highest confidence delta
2. **Run A1** (content architecture) — determines the output format for everything else
3. **Run A2** (token system) — determines how design extraction works
4. **Run B2** (template discovery) — determines conversion workflow
5. **Run A3-A5** in parallel (file structure, dark mode, fonts) — independent
6. **Run B3-B5** in parallel (extraction method, threshold, orchestration) — independent
7. **Run C1** last (deployment) — needs a finished site

Each experiment should take 15-30 minutes. Full suite: ~4-6 hours.

---

## How to Run

```
/kernel:experiment
```

The experiment engine will:
1. Seed these hypotheses from the command files
2. Pick the most uncertain (closest to 0.5 confidence)
3. Design the lightest viable experiment
4. Run it against the provided WordPress URL
5. Record evidence, update confidence
6. Graduate (≥0.8) or kill (<0.2) based on results
7. Loop until all hypotheses have sufficient evidence

After experiments complete:
- Graduated hypotheses → hardened as rules in the commands
- Killed hypotheses → removed or mutated
- The commands evolve based on evidence, not opinion
