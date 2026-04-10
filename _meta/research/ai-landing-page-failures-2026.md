# AI Landing Page Failure Modes: Research & Prevention

**Research Date:** 2026-04-10  
**Purpose:** Comprehensive anti-patterns catalog for AI-generated landing pages  
**Status:** For building production command enforcement layer  

---

## SCALE OF THE PROBLEM

- **95.9%** of top 1M homepages contain detectable WCAG violations (WebAIM 2025)
- **94.8%** of pages fail at least one WCAG criterion
- **91% lower** conversion rates for generic "AI slop" sites vs. designed pages
- **1.7x more issues** in AI code vs. human code (CodeRabbit 2025)
- **40-62% security flaws** in AI-generated code (CSA, Veracode)

---

## FAILURE MODES: The 13 Categories

### 1. DESIGN SYSTEM COLLAPSE: Hardcoded Colors & Values

**The Failure:**
- Hex colors inline: `color: "#FF4444"` scattered across CSS
- Magic numbers for spacing: `padding: 16px`, `margin: 24px`, `gap: 40px`
- Raw pixel values for fonts, borders, shadows, radii
- Fabricated token names: `var(--primary-blue-light-secondary)` (doesn't exist)
- Values drift between sessions: day 1 uses `#FF0000`, day 2 uses `#FF1111`
- No dark mode variants — single color value per property

**Why AI Does This:**
- Generates "complete" CSS per prompt without reference layer
- No memory between sessions; starts fresh every time
- Training data contains raw hex/px values; more probable than token lookup
- Token fabrication: plausible-sounding names feel right but don't resolve

**Real Impact:**
- Designers can't change brand color without file-by-file hunt
- Dark mode becomes unmaintainable (duplicate hardcoding)
- Every design system update requires manual propagation
- Inconsistent spacing makes page feel "cheap"
- Design debt explodes with each new page

**Prevention Pattern:**

```css
/* Layer 1: Upstream design system (import or reference) */
:root {
  --ds-color-text-primary: #292A2E;
  --ds-space-100: 0.5rem;
  --ds-space-200: 1rem;
}

/* Layer 2: Project aliases (your overrides, with fallbacks) */
:root {
  --color-text: var(--ds-color-text-primary, #292A2E);
  --space-md: var(--ds-space-200, 1rem);
}

/* Layer 3: Components ONLY reference Layer 2 */
.button { padding: var(--space-md); color: var(--color-text); }
```

**Enforcement in Command:**
- CI audit script detects all hardcoded colors/values
- Generator template includes 3-layer tokens.css
- Project instruction file: "Never reference Layer 1 or raw values"
- Pre-commit hook blocks merges with hardcoded values

**Sources:**
- [Expose your design system to LLMs](https://hvpandya.com/llm-design-systems)
- [Can Large Language Models Design CSS?](https://strikingloo.github.io/llm-css-design)

---

### 2. VISUAL CHAOS: Inconsistent Spacing & Sizing

**The Failure:**
- No consistent rhythm: sections have padding 15px, 24px, 40px (no pattern)
- Arbitrary border-radius: `4px`, `12px`, `20px`, `999px` (no system)
- Line-height all over: `1.2`, `1.5`, `1.8` in same component
- Font sizes: `12px`, `16px`, `18px`, `20px`, `24px` (every size used)
- Gap values between grid items: `8px`, `16px`, `20px`, `32px`
- Visual weight same everywhere: every card identical padding/border

**Why AI Does This:**
- Generates locally optimal values per component (no global view)
- No understanding of design rhythm or scale
- Training data includes inconsistent spacing; averages to chaos
- Each prompt treated independently (no system reference)

**Real Impact:**
- Looks unprofessional even with correct colors/fonts
- Designers can't achieve cohesion (have to rebuild)
- Mobile responsiveness breaks with arbitrary values
- Alignment issues between components

**Prevention Pattern:**

```css
/* Define scale ONCE */
:root {
  --space-xs: 0.25rem;   /* 4px */
  --space-sm: 0.5rem;    /* 8px */
  --space-md: 1rem;      /* 16px */
  --space-lg: 1.5rem;    /* 24px */
  --space-xl: 2rem;      /* 32px */
  
  --radius-sm: 0.25rem;  /* 4px */
  --radius-md: 0.5rem;   /* 8px */
  --radius-lg: 1rem;     /* 16px */
  
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
}

/* Enforce: No arbitrary values in components */
.card { padding: var(--space-md); border-radius: var(--radius-md); }
```

**Enforcement in Command:**
- Template provides pre-built spacing scale (4/8/16/24/32 rule)
- ESLint rule flags any numeric value in CSS/Tailwind
- Generator constraint: "Only use token values, never px/rem"
- Audit script matches all used values against allowed set

**Sources:**
- [Dark Mode Design That Doesn't Look AI](https://dev.to/raxxostudios/dark-mode-design-that-doesnt-look-ai-2cn3)

---

### 3. ACCESSIBILITY VOID: Missing WCAG Compliance

**The Failure:**
- No alt text on images (55.5% of images missing)
- Form labels not associated with inputs
- No semantic HTML: `<div class="button">` instead of `<button>`
- Missing ARIA attributes
- Low contrast text (79% of sites violate WCAG AA)
- No keyboard navigation support
- Links and buttons indistinguishable
- Dialog/modal implemented as divs without role="dialog"
- No heading hierarchy (`<h1>`, `<h2>` skipped)
- Color-only information (red="error", no text)

**Why AI Does This:**
- Accessibility underrepresented in training data
- Happy path dominates examples; edge cases ignored
- No enforced testing for WCAG compliance
- AI doesn't think about screen readers
- "Make it work" doesn't include "make it accessible"

**Real Impact:**
- 4,000+ digital accessibility lawsuits filed in 2025
- Site violates ADA Title II (mandatory WCAG 2.1 AA by 2026 for state/local sites)
- Excludes ~15% of users
- Failed security audit in enterprise
- Reputational damage

**Prevention Pattern:**

```html
<!-- BAD: AI default -->
<div class="button" onclick="submit()">Click Me</div>
<input class="input" />
<img src="hero.jpg" />

<!-- GOOD: Enforced in template -->
<button type="button" aria-label="Submit form">Click Me</button>
<label for="email">Email</label>
<input id="email" type="email" required />
<img src="hero.jpg" alt="Hero section showing product features" />

<nav aria-label="Main navigation">
  <h1>Page Title</h1>
  <h2>Section Title</h2>
</nav>
```

**Enforcement in Command:**
- Template includes semantic HTML scaffold
- axe-core audit in build (fails on critical issues)
- Pre-commit checks: all images have alt text
- Instruction file: "Use semantic elements, never divs for interactive"
- ARIA attributes in component templates
- Contrast checker on build (WCAG AA minimum)

**Sources:**
- [CodeA11y: Making AI Coding Assistants Useful for Accessible Web Development](https://dl.acm.org/doi/10.1145/3706598.3713335)
- [Evaluating Generative AI for HTML Development](https://www.mdpi.com/2227-7080/13/10/445)
- [AI has an accessibility problem](https://blog.logrocket.com/ai-has-an-accessibility-problem/)

---

### 4. DARK MODE DEBT: No Theme Support

**The Failure:**
- Colors hardcoded, no `prefers-color-scheme` support
- Dark mode added via copy-paste: same CSS written again with dark colors
- Text unreadable in dark: `white text on light background` ignored
- All components same visual weight in dark mode (no contrast hierarchy)
- Neon-on-dark overuse: glowing borders, gradient text, animated accents
- No CSS variables for theme switching
- Dark mode as afterthought (not in initial design)

**Why AI Does This:**
- Generates light mode first; dark mode treated as variant (copy-paste)
- No systematic color architecture
- Doesn't think about theme abstraction
- Training data mostly light mode

**Real Impact:**
- Users on dark mode have degraded experience
- Adding true dark mode requires full rewrite
- Brand color unusable at night (unreadable)

**Prevention Pattern:**

```css
:root {
  --bg-primary: #FFFFFF;
  --text-primary: #292A2E;
  --border-color: #E5E7EB;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg-primary: #1A1A1A;
    --text-primary: #F5F5F5;
    --border-color: #404040;
  }
}

/* All components use tokens */
body { background: var(--bg-primary); color: var(--text-primary); }
.card { border: 1px solid var(--border-color); }
```

**Enforcement in Command:**
- Template includes `prefers-color-scheme: dark` media query
- Audit: all color properties use CSS variables (no hardcoded colors)
- Build test: verify contrast in both light and dark modes
- Instruction file: "Dark mode is not optional"

**Sources:**
- [Dark Mode & Theming — Ensuring Accessibility Across Color Schemes](https://www.accesify.io/blog/dark-mode-theming-accessibility-across-color-schemes)
- [Top 3 Dark Mode Issues and How to Fix Them with CSS](https://bitskingdom.com/blog/dark-mode-issues-fix-with-css/)

---

### 5. GOD COMPONENTS: Monolithic Files (500+ Lines)

**The Failure:**
- Entire landing page in one React component
- State, logic, UI, API calls all mixed
- 10+ useState hooks in single file
- 5+ API calls without separation
- Form logic, validation, submission all inline
- Event handlers defined inline
- Conditional rendering nested 3+ levels deep
- No prop interface; everything global
- Hundreds of lines of conditional render JSX

**Why AI Does This:**
- Generates "complete" solutions per prompt
- No architectural thinking (single-file paradigm)
- Copy-pasting easier than extracting
- AI doesn't refactor after generation

**Real Impact:**
- Unmaintainable: changes touch 500 lines
- Untestable: everything coupled
- Unreadable: cognitive load huge
- Duplication: copy-paste patterns repeated
- Refactoring nightmare

**Prevention Pattern:**

```
/* FLAT: Bad (AI default) */
/app
  /Landing.jsx (800 lines)

/* COMPOSED: Good (enforced) */
/app
  /Landing.jsx (80 lines, orchestration only)
  /sections
    /HeroSection.jsx (100 lines)
    /FeaturesSection.jsx (80 lines)
    /PricingSection.jsx (120 lines)
  /components
    /FeatureCard.jsx (40 lines)
    /PricingCard.jsx (50 lines)
  /hooks
    /useContactForm.js (60 lines)
```

**Enforcement in Command:**
- Linter flags files > 300 lines
- ESLint complexity rule: cyclomatic complexity < 10
- Generator template: provides component structure, not monolith
- Instruction file: "Max 30 lines per component, split others"

**Sources:**
- [AI Code Anti-Patterns Research](https://www.monet.design/blog/posts/escape-ai-slop-landing-page-design)

---

### 6. CONTENT HARDCODING: No Content Layer

**The Failure:**
- All text baked into JSX: `<h1>Welcome to Our Product</h1>`
- Images hardcoded: `<img src="/images/feature-1.jpg" />`
- No constants file for labels
- Copy-paste content across pages
- No separation of content from markup
- Impossible to update without code change
- No i18n support (multilingual sites broken)
- CMS integration missing (no data layer)

**Why AI Does This:**
- "Make it work" means visible content
- No prompting for content abstraction
- Quickest generation path is hardcoding
- AI doesn't think about data models

**Real Impact:**
- Non-technical team can't update copy
- Every content change is a deploy
- A/B testing requires code changes
- Translation/i18n requires new version

**Prevention Pattern:**

```javascript
// content.js - EXTRACTED
export const landing = {
  hero: {
    title: "Welcome to Our Product",
    subtitle: "Save time, boost productivity",
    cta: "Get Started"
  },
  features: [
    { title: "Fast", description: "Lightning quick" },
    { title: "Secure", description: "Bank-grade encryption" }
  ]
};

// Landing.jsx - NO HARDCODING
import { landing } from './content.js';

export function Landing() {
  return (
    <>
      <h1>{landing.hero.title}</h1>
      <p>{landing.hero.subtitle}</p>
      {landing.features.map(f => <FeatureCard {...f} />)}
    </>
  );
}
```

**Enforcement in Command:**
- Template provides content.js structure
- Linter flags string literals in JSX (flag hardcoded text)
- Generator constraint: "Extract all content to data file first"
- Instruction file: "Content layer is mandatory"

**Sources:**
- [LLM patterns for building systems](https://eugeneyan.com/writing/llm-patterns/)

---

### 7. SEO ABSENT: Missing Meta Tags & OG Tags

**The Failure:**
- No meta description
- Missing Open Graph tags (og:title, og:description, og:image)
- No Twitter Card tags
- No canonical URL
- Missing robots meta tag
- No JSON-LD structured data
- Heading hierarchy broken (`<h1>` skipped)
- No alt text on images
- No sitemap reference
- Page title not descriptive

**Why AI Does This:**
- SEO not visible in UI (doesn't "work")
- Not in initial prompts
- Training data includes sites without SEO

**Real Impact:**
- Won't rank in search
- Social shares show no preview
- AI retrieval systems can't understand content
- Enterprise won't index (no robots meta)

**Prevention Pattern:**

```html
<head>
  <title>Product Name - Key Benefit | Company</title>
  <meta name="description" content="50-160 character description">
  <meta name="robots" content="index, follow">
  <link rel="canonical" href="https://example.com/page">
  
  <meta property="og:title" content="Title">
  <meta property="og:description" content="Description">
  <meta property="og:image" content="https://example.com/og-image.jpg">
  <meta property="og:url" content="https://example.com/page">
  
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Title">
  <meta name="twitter:description" content="Description">
  
  <script type="application/ld+json">
  {"@context": "schema.org", "@type": "WebPage", ...}
  </script>
</head>
```

**Enforcement in Command:**
- Template includes SEO meta scaffold
- Pre-build check: validates all required meta tags present
- og:image check: confirms image exists
- Instruction file: "Every page must have meta tags"
- JSON-LD schema validator in build

**Sources:**
- [SEO + LLM guide](https://2index.ninja/blog/seo-llm-kak-ispolzovat-chatgpt-gemini-i-claude-dlia-podgotovki-meta-tegov-opisanii-i-struktury-saita)

---

### 8. IMAGE MISHANDLING: No Optimization, Missing Alt Text

**The Failure:**
- Images not lazy-loaded
- No responsive images (no srcset)
- Wrong image formats (JPEG for icons, PNG for photography)
- No image optimization (2MB uncompressed images)
- Missing alt text (55.5% of images)
- Alt text generic: `alt="image"`, `alt="photo"`
- Above-the-fold images loaded eagerly (correct) but not optimized
- No WebP/AVIF support
- LCP (Largest Contentful Paint) slow due to unoptimized images

**Why AI Does This:**
- Image optimization is "infrastructure", not "feature"
- Alt text requires seeing image, understanding context
- AI doesn't optimize by default
- Lazy loading requires understanding viewport

**Real Impact:**
- Page load slow (CLS/LCP failures)
- Accessibility fail (can't see images)
- Mobile users waste data
- SEO penalty (Core Web Vitals)

**Prevention Pattern:**

```jsx
// Template component
function OptimizedImage({ src, alt, title }) {
  return (
    <img
      src={src}
      alt={alt}
      title={title}
      loading={isBelowTheFold ? "lazy" : "eager"}
      srcSet={`${src}?w=400 400w, ${src}?w=800 800w`}
    />
  );
}

// Generator constraint
// - Hero images: loading="eager", no lazy
// - Below-fold: loading="lazy"
// - All images: alt text required (not empty, not generic)
// - Template: use OptimizedImage component
```

**Enforcement in Command:**
- Linter flags `<img>` without alt text or with empty/generic alt
- Pre-build: validate alt text is descriptive (not "image", "photo")
- Image audit: check formats, compression
- Template provides OptimizedImage component
- Instruction file: "All images must use OptimizedImage component"

**Sources:**
- [Image SEO 2025: Optimize for Speed & Visibility](https://wellows.com/blog/image-seo-2025/)
- [Alt Text Best Practices 2025](https://www.allaccessible.org/blog/alt-text-best-practices-2025-ai-generator/)
- [Lazy loading - MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/Performance/Guides/Lazy_loading)

---

### 9. RESPONSIVE CHAOS: Poor Mobile Experience

**The Failure:**
- No mobile breakpoints
- Text unreadable on mobile
- Buttons too small to tap
- Touch targets < 44x44px
- Horizontal scroll on mobile
- Images don't scale to viewport
- Layout breaks at specific sizes
- Padding same on mobile/desktop
- No touch-friendly spacing
- Viewport meta tag missing or wrong

**Why AI Does This:**
- Desktop-first generation (mobile as afterthought)
- No mobile testing feedback
- Breakpoints require thinking about constraints
- Magic numbers don't scale

**Real Impact:**
- 60% of traffic is mobile; site unusable for majority
- High bounce rate
- Mobile search ranking penalty
- Users leave immediately

**Prevention Pattern:**

```css
/* Enforced scale approach */
:root {
  --space-md: 1rem;
  --text-base: 1rem;
  --container-max: 1200px;
}

@media (max-width: 768px) {
  :root {
    --space-md: 0.75rem;
    --text-base: 0.875rem;
  }
}

/* Use scales everywhere */
.section { padding: var(--space-md); }
.text { font-size: var(--text-base); }

/* Enforce semantic breakpoints */
/* sm: 640px, md: 768px, lg: 1024px, xl: 1280px */
```

**Enforcement in Command:**
- Template uses mobile-first breakpoints (Tailwind standard)
- Generator constraint: "Use breakpoints, never media queries with pixels"
- Linter flags hardcoded pixel breakpoints
- Mobile preview in dev server (mandatory)
- Pre-build: check viewport meta tag present and correct

**Sources:**
- [Why Responsive Web Design Still Matters in 2025](https://www.tothenew.com/insights/article/responsive-web-design-2025)
- [The Ultimate Guide to Responsive Web Design in 2025](https://www.dotcominfoway.com/blog/the-ultimate-guide-to-responsive-web-design-in-2025/)

---

### 10. COPY-PASTE DEBT: Duplication Explosion

**The Failure:**
- Same button CSS in 5 files
- Identical form validation logic repeated
- Section markup duplicated for "slightly different" layouts
- Component variants copy-pasted instead of extracted
- No shared utilities
- Grid layouts hardcoded per component
- Spacing logic repeated everywhere

**Why AI Does This:**
- Generates "complete" per-prompt
- No cross-file refactoring incentive
- Each prompt independent
- Faster to generate than extract

**Real Impact:**
- Single color change requires 5+ files
- Code review misses duplication
- 8x larger codebase than needed
- Maintenance nightmare

**Prevention Pattern:**

```
/components (extracted, reused)
  /Button.jsx       → single source
  /Card.jsx         → single source
  /Section.jsx      → layout container
  
/hooks (extracted logic)
  /useForm.js       → single validation

/styles (shared styles)
  /grid.css         → layout scale
  /spacing.css      → space system
```

**Enforcement in Command:**
- jscpd duplication detector in build
- Duplication threshold: < 5%
- Linter flags 3+ similar blocks
- Template emphasizes component extraction
- Generator constraint: "Check for existing component before implementing"

**Sources:**
- [AI Code Anti-Patterns: Duplication Explosion](https://www.monet.design/blog/posts/escape-ai-slop-landing-page-design)

---

### 11. INLINE STYLES MESS: Style/Markup Mixed

**The Failure:**
- CSS-in-JS scattered: `style={{ color: "red", padding: "16px" }}`
- Inline event handlers mixed with markup
- Classes and inline styles both used (inconsistent)
- No separation of concerns
- Style logic untestable
- Responsive styles hardcoded in component
- Tailwind classes mixed with custom CSS

**Why AI Does This:**
- Fastest generation path (inline)
- No setup/config needed
- Appears immediately in UI
- No component library requirement

**Real Impact:**
- Unmaintainable: styles spread across files
- No dark mode support (hardcoded values)
- No design system connection
- Reuse impossible
- Performance: style recalculation on every render

**Prevention Pattern:**

```jsx
/* BAD */
<button style={{ backgroundColor: "blue", padding: "12px" }}>
  Click
</button>

/* GOOD: CSS module or Tailwind */
<button className="btn btn-primary">Click</button>

/* buttons.css or tailwind config */
.btn-primary { background: var(--color-primary); padding: var(--space-md); }
```

**Enforcement in Command:**
- ESLint: flag inline `style` prop
- Template: CSS modules or Tailwind only
- Generator constraint: "Never use style prop"
- Component scaffold: includes CSS module file

**Sources:**
- [My LLM coding workflow going into 2026](https://addyosmani.com/blog/ai-coding-workflow/)

---

### 12. STATE CHAOS: Over-Complicated State Management

**The Failure:**
- Multiple useState for related state
- State scattered across props and context
- No loading/error states
- Optimistic updates missing
- No error boundaries
- State mutations instead of immutability
- Race conditions in async operations
- Memory leaks in effects (missing cleanup)

**Why AI Does This:**
- Happy path only (doesn't think about states)
- State management not explicitly prompted
- Doesn't handle loading/error without instruction
- Training data includes problematic patterns

**Real Impact:**
- Race conditions cause bugs
- UI shows stale data
- Error states unhandled (blank screens)
- Component unmounting leaves dangling effects

**Prevention Pattern:**

```javascript
// Template: proper state shape
const useContactForm = () => {
  const [state, dispatch] = useReducer(formReducer, {
    status: 'idle', // idle | loading | success | error
    data: null,
    error: null
  });
  
  const submit = async (formData) => {
    dispatch({ type: 'SUBMIT' }); // sets loading
    try {
      const res = await api.submit(formData);
      dispatch({ type: 'SUCCESS', payload: res });
    } catch (err) {
      dispatch({ type: 'ERROR', payload: err.message });
    }
  };
  
  return { state, submit };
};
```

**Enforcement in Command:**
- Template provides useReducer pattern
- Generator constraint: "Use useReducer for complex state"
- Instruction file: "Always handle loading, error, success states"
- ESLint: flag useState with > 5 calls in single component

**Sources:**
- [State Management Trends in React 2025](https://makersden.io/blog/react-state-management-in-2025/)
- [Taming the Beast: How AI is Simplifying React State Management Chaos](https://dev.to/naveens16/taming-the-beast-how-ai-is-simplifying-react-state-management-chaos-k04)

---

### 13. VISUAL MONOCULTURE: "AI Slop" Aesthetic

**The Failure:**
- Same design as every other AI site: Inter font, purple/blue gradients, rounded corners everywhere
- Bland, generic typography hierarchy
- Overuse of animations/glows
- Overuse of glass-morphism effects
- Same color palette as default templates
- No visual distinction (everything looks the same)
- No brand personality
- No visual risk-taking

**Why AI Does This:**
- Trained on most common patterns (distributional convergence)
- Defaults to "safe" design
- No instruction for brand differentiation
- Gradient + animation = "modern" to AI

**Real Impact:**
- 91% lower conversion rates vs. designed pages
- No differentiation in market
- Visual exhaustion (users bored)
- Looks like competitor (indistinguishable)

**Prevention Pattern:**

```css
/* Enforce brand-specific design tokens */
:root {
  /* Brand colors (not default purple) */
  --brand-primary: #1a472a; /* forest green, not purple */
  --brand-accent: #d4a574;  /* warm gold, not neon */
  
  /* Brand typography */
  --font-family: 'Hanken Grotesk'; /* not Inter */
  
  /* Brand spacing (unique scale) */
  --rhythm: 1.618; /* golden ratio, not 4-space grid */
}

/* Enforce: Custom design, not template defaults */
```

**Enforcement in Command:**
- Design spec in project instructions (fonts, colors, personality)
- Generator constraint: "Follow brand spec, not default template"
- Pre-merge review: check if design is generic (designer review required)
- Template includes brand customization section

**Sources:**
- [2025 AI Landing Page Pitfall: 5 Strategies to Escape 'AI Slop'](https://www.monet.design/blog/posts/escape-ai-slop-landing-page-design)
- [AI Landing Page Builders in 2026: How to Choose the Right Tool](https://unicornplatform.com/blog/ai-landing-page-builders-in-2026/)

---

## COMMAND ARCHITECTURE: Prevention Layers

### Layer 1: Pre-Generation (Template & Constraints)

```
/template
  /index.html          → includes all meta tags, semantic structure
  /styles/tokens.css   → 3-layer token system
  /styles/global.css   → enforced scale (spacing, typography)
  /styles/dark-mode.css → prefers-color-scheme support
  /layout/             → semantic HTML components (Section, Container, Grid)
  /components/         → atomic components (Button, Card, OptimizedImage)
  /hooks/              → custom hooks (useForm, useAsync)
  /content.js          → extracted content layer
  /.claude             → project instructions (NEVER hardcoded values, etc.)
  /SKIP_LINES.md       → prohibited patterns
```

### Layer 2: Generation Phase

**Prompt Template:**
```
Before implementing:
1. Check template structure — follow it exactly
2. Reference tokens.css — never hardcode colors/spacing
3. Use existing components — never duplicate
4. Extract content — content.js file only
5. Semantic HTML — always use proper elements
6. Accessibility — every interactive element testable
```

### Layer 3: Post-Generation (Automated Audits)

```bash
# Pre-commit checks
✓ Hardcoded values audit (no colors, sizes outside token layer)
✓ Accessibility audit (axe-core, contrast checker)
✓ Mobile viewport check (responsive, no hard pixel sizes)
✓ Meta tags validation (all required tags present)
✓ Image audit (alt text, format, lazy-loading)
✓ Duplication check (< 5% duplicate code)
✓ Component size check (max 300 lines)
✓ Linting (no inline styles, semantic HTML, etc.)
```

### Layer 4: Pre-Ship Quality Gate

```
✓ Lighthouse audit (Performance, Accessibility, SEO, Best Practices)
✓ WCAG AA compliance (axe-core + manual review)
✓ Mobile responsiveness test (viewport, touch targets)
✓ Dark mode verification (colors, contrast)
✓ Image optimization test (sizes, formats)
✓ Design spec comparison (brand adherence, not generic)
```

---

## SOURCES

- [CodeRabbit State of AI Code 2025](https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report)
- [SonarSource AI Code Quality Analysis](https://www.sonarsource.com/resources/reports/)
- [WebAIM Million Report 2025](https://webaim.org/articles/million/)
- [Expose your design system to LLMs](https://hvpandya.com/llm-design-systems)
- [CodeA11y: Making AI Coding Assistants Useful for Accessible Web Development](https://dl.acm.org/doi/10.1145/3706598.3713335)
- [METR Study 2025](https://metr.org)
- [MDPI: Evaluating Generative AI for HTML Development](https://www.mdpi.com/2227-7080/13/10/445)

---

## QUICK REFERENCE: Pre-Generation Checklist

When spawning generator for landing page:

- [ ] Pass tokens.css (3-layer system)
- [ ] Pass component library (Button, Card, Section, OptimizedImage)
- [ ] Pass content.js structure (no hardcoded copy)
- [ ] Pass .claude with project instructions (enforce semantic, constrain choices)
- [ ] Pass accessibility template (semantic HTML scaffold)
- [ ] Pass brand spec (colors, fonts, personality — NOT generic defaults)
- [ ] Pass meta tags template (SEO required)
- [ ] Pass dark mode scaffold (prefers-color-scheme)
- [ ] Pass responsive breakpoints (Tailwind or similar)
- [ ] Pass SKIP_LINES.md (prohibited: inline styles, magic numbers, copy-paste)

