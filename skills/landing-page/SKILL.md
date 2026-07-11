---
name: landing-page
description: "Guided landing page generator. Interview → scaffold → enforce → deploy. Static HTML/CSS optimized for Cloudflare Pages. All architectural decisions are hypotheses until proven by /kernel:experiment."
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebSearch, WebFetch
disable-model-invocation: true
kernel:
  kind: operator
  version: 1
  side_effects: deploys
  confirmation: on_side_effect
---

<skill id="landing-page">

<purpose>
Generate a properly architected static landing page from a guided interview.
Optimized for: non-technical users, zero build steps, Cloudflare Pages deployment.

The output is a static site with:
  - ALL content in a single editable file (content.js)
  - ALL design tokens in a single CSS file (tokens.css)
  - Semantic HTML with proper accessibility
  - Dark mode support
  - Full SEO scaffold
  - One-command deployment: `wrangler deploy`

Every rule below is a HYPOTHESIS. Run /kernel:experiment to prove or disprove.
</purpose>

<skill_load>
always: skills/quality/SKILL.md, skills/frontend/SKILL.md
on_domain:
  frontend: skills/frontend/SKILL.md
reference: _meta/research/ai-landing-page-failures-2026.md
</skill_load>

<on_start>
```bash
agentdb read-start
agentdb emit command "landing-page-start" "" '{}'
```
</on_start>

<!-- ============================================ -->
<!-- PHASE 0: INIT — Bootstrap Project Repo       -->
<!-- ============================================ -->

<phase id="init" name="INIT — Bootstrap Project (before anything else)">
  Mirror the /kernel:init pattern: don't just dump raw files, set up a proper project.

  <requirements>Git, Node (for wrangler), curl</requirements>

  <steps>

  ## Step 1: Locate or create project directory

  Three modes, auto-detected:

  **Mode A — In-place (CWD is the target):**
  If `$(basename $PWD)` matches the project name OR the CWD is empty / contains only
  hidden files, initialize in place. This is the common case when the user runs
  `mkdir ourlastframe && cd ourlastframe && /kernel:landing-page`.

  **Mode B — Create subdir (CWD is parent):**
  Create `$PWD/${PROJECT}/`, cd into it.

  **Mode C — Refuse (CWD has unrelated content):**
  If CWD is non-empty and name doesn't match, refuse and tell user to either cd to parent
  or choose mode A explicitly.

  ```bash
  PROJECT="${project_name_slugified}"   # from interview Phase 1 answer
  CWD_BASE="$(basename "$PWD")"
  # Count non-hidden entries
  VISIBLE_COUNT=$(ls -1 2>/dev/null | wc -l | tr -d ' ')

  if [ "$CWD_BASE" = "$PROJECT" ] || [ "$VISIBLE_COUNT" = "0" ]; then
    # Mode A: in-place
    TARGET="$PWD"
    echo "INIT MODE: in-place at $TARGET"
  elif [ ! -e "$PWD/$PROJECT" ]; then
    # Mode B: create subdir
    TARGET="$PWD/$PROJECT"
    mkdir -p "$TARGET"
    cd "$TARGET"
    echo "INIT MODE: created $TARGET"
  else
    # Mode C: refuse
    echo "ERROR: Cannot init. CWD has unrelated content and $PWD/$PROJECT exists."
    echo "Either: (1) cd to empty parent dir, or (2) cd into ${PROJECT}/ to init in-place."
    exit 1
  fi

  mkdir -p styles assets
  ```

  ## Step 2: Initialize git (idempotent)

  ```bash
  # Skip if already a git repo (in-place mode may land in one)
  if [ ! -d .git ]; then
    git init -b main
  else
    echo "Git repo already present, skipping init."
  fi
  cat > .gitignore <<'EOF'
  # Cloudflare
  .wrangler/
  .dev.vars

  # Node (only if user later adds build tooling)
  node_modules/

  # OS
  .DS_Store
  Thumbs.db

  # Editor
  .vscode/
  .idea/
  *.swp

  # Logs
  *.log
  npm-debug.log*
  EOF
  ```

  ## Step 3: Create README

  ```bash
  cat > README.md <<EOF
  # ${PROJECT}

  ${tagline}

  ## Edit content
  Open \`content.js\` — every string on the site is there.

  ## Edit design
  Open \`styles/tokens.css\` — every color, font, spacing value is there.

  ## Preview locally
  Open \`index.html\` in a browser. Works without a server.

  ## Deploy
  \`\`\`bash
  npx wrangler login     # first time only
  npx wrangler pages deploy . --project-name=${PROJECT}
  \`\`\`
  EOF
  ```

  ## Step 4: Wrangler check (non-blocking)

  ```bash
  if ! command -v npx >/dev/null 2>&1; then
    echo "WARNING: npx not found. Install Node.js for deployment."
  elif ! npx --no-install wrangler --version >/dev/null 2>&1; then
    echo "NOTE: wrangler will be auto-fetched on first deploy via npx."
  fi
  ```

  ## Step 5: AgentDB tracking

  ```bash
  agentdb emit command "landing-page-init" "" \
    "{\"project\":\"${PROJECT}\",\"path\":\"${TARGET}\"}"
  ```

  ## Step 6: Initial commit (only if we have something new to commit)

  ```bash
  git add .gitignore README.md 2>/dev/null || true
  if ! git diff --cached --quiet; then
    git commit -m "chore: init ${PROJECT} landing page scaffold"
  else
    echo "Nothing new to commit for scaffold."
  fi
  ```

  </steps>

  <hypothesis id="H-LP-INIT">
    CLAIM: A proper repo scaffold (git init + .gitignore + README + AgentDB tracking)
    produces better long-term maintenance than a raw file dump. Users will actually
    version-control the site and deploy from git.
    CONFIDENCE: 0.7 (standard pattern, untested in this context)
  </hypothesis>

  <rule id="INIT_BEFORE_GENERATE">
    Phase 0 runs BEFORE Phase 1 interview confirmation triggers generation.
    Phases 2-6 write into the initialized repo. Phase 7 audit runs git diff.
    Phase 8 handoff includes git status + remote suggestion.
  </rule>
</phase>

<!-- ============================================ -->
<!-- PHASE 1: INTERVIEW                           -->
<!-- ============================================ -->

<phase id="interview" name="INTERVIEW — Gather Requirements">
  Collect the minimum information needed to generate a complete site.
  Ask in ONE prompt, not drip-fed questions.

  <questions>
  Required:
    1. Project name (used for directory, wrangler config, page title)
    2. One-line tagline / hero headline
    3. What does this product/service do? (2-3 sentences max)
    4. Brand colors: primary + accent (hex codes, or describe and we pick)
    5. Which sections? (offer checklist, let them pick):
       [ ] Hero with CTA
       [ ] Features (grid or alternating)
       [ ] Pricing (tiers)
       [ ] Testimonials
       [ ] FAQ
       [ ] About / Team
       [ ] Contact / CTA form
       [ ] Legal (privacy, terms)
       [ ] Footer with links

  Optional (sensible defaults if skipped):
    6. Domain name (default: {project-name}.pages.dev)
    7. Font preference (default: curated pair — see H-LP-FONTS)
    8. Dark mode? (default: yes — see H-LP-DARKMODE)
    9. App store links / external CTAs?
  </questions>

  <hypothesis id="H-LP-INTERVIEW">
    CLAIM: A single-prompt interview (all questions at once) produces better results than
    multi-step wizard-style questioning.
    EVIDENCE: None yet. Test via /kernel:experiment with both approaches.
    CONFIDENCE: 0.5
  </hypothesis>

  After collecting answers, confirm understanding:
  ```
  CONFIRM:
  - Project: {name}
  - Sections: {list}
  - Colors: primary {hex}, accent {hex}
  - Deploy: Cloudflare Pages → {domain}
  Generating. Interrupt if wrong.
  ```
</phase>

<!-- ============================================ -->
<!-- PHASE 2: SCAFFOLD                            -->
<!-- ============================================ -->

<phase id="scaffold" name="SCAFFOLD — Generate Project Structure">

  <hypothesis id="H-LP-STRUCTURE">
    CLAIM: This file structure produces the fewest AI generation errors and is most
    maintainable by non-technical editors.
    CONFIDENCE: 0.6 (based on modelmind-site success, untested at scale)
  </hypothesis>

  Generate this exact structure:
  ```
  {project-name}/
  ├── index.html                    # Main page — references content.js + tokens.css
  ├── content.js                    # ALL text, labels, links, image paths — single source
  ├── styles/
  │   ├── tokens.css                # ALL design tokens (colors, spacing, radii, fonts, breakpoints)
  │   └── main.css                  # Component styles — references tokens via var()
  ├── assets/
  │   ├── favicon.svg               # Generated from project name initial
  │   └── og-image.html             # OG image template (screenshot to create og-image.png)
  ├── [page].html                   # Additional pages (about, privacy, terms) if selected
  ├── wrangler.toml                 # Cloudflare Pages config
  ├── _headers                      # Security + cache headers
  ├── _redirects                    # www → apex redirect
  ├── robots.txt                    # SEO
  └── sitemap.xml                   # SEO
  ```

  <rule id="NO_BUILD">
    HYPOTHESIS H-LP-NOBUILD: Zero build tools produces more reliable sites than any framework.
    No npm. No package.json. No webpack/vite/next. Edit HTML → deploy.
    Tailwind loaded via CDN script tag.
    CONFIDENCE: 0.7 (modelmind-site has zero build failures over 3+ months)
  </rule>

</phase>

<!-- ============================================ -->
<!-- PHASE 3: CONTENT FILE                        -->
<!-- ============================================ -->

<phase id="content" name="CONTENT — Generate Unified Content File">

  <hypothesis id="H-LP-CONTENT-SINGLE">
    CLAIM: A single content.js file is better than multiple content files for sites with ≤10 pages.
    Rationale: Non-technical editors only need to open one file. No import chains to understand.
    Counter: Could become unwieldy at scale. Threshold unknown.
    CONFIDENCE: 0.5
  </hypothesis>

  Generate `content.js` with this exact pattern:

  ```javascript
  /**
   * ============================================
   * SITE CONTENT — Edit this file to change all text on the site.
   * No need to touch HTML files. Just change values here and refresh.
   * ============================================
   */

  const SITE = {
    name: "{project-name}",
    tagline: "{tagline}",
    description: "{description}",
    url: "https://{domain}",
    ogImage: "assets/og-image.png",
  };

  const NAV = {
    links: [
      { label: "Features", href: "#features" },
      { label: "Pricing", href: "#pricing" },
      // ...
    ],
    cta: { label: "Get Started", href: "#cta" },
  };

  const HERO = {
    headline: "{headline}",
    subheadline: "{subheadline}",
    cta: { label: "{cta_text}", href: "{cta_href}" },
    secondaryCta: { label: "Learn More", href: "#features" },  // optional
  };

  const FEATURES = {
    headline: "Why {project-name}",
    items: [
      {
        icon: "lightbulb",           // Material Symbol name
        title: "Feature One",
        description: "What this feature does for the user.",
      },
      // ... more features
    ],
  };

  const PRICING = {
    headline: "Simple Pricing",
    tiers: [
      {
        name: "Free",
        price: "$0",
        period: "/month",
        features: ["Feature A", "Feature B"],
        cta: { label: "Start Free", href: "#" },
        highlighted: false,
      },
      // ... more tiers
    ],
  };

  const TESTIMONIALS = {
    headline: "What People Say",
    items: [
      { quote: "...", author: "Name", role: "Title, Company" },
    ],
  };

  const FAQ = {
    headline: "Frequently Asked Questions",
    items: [
      { question: "...", answer: "..." },
    ],
  };

  const FOOTER = {
    copyright: "© {year} {project-name}. All rights reserved.",
    links: [
      { label: "Privacy", href: "privacy.html" },
      { label: "Terms", href: "terms.html" },
    ],
    socials: [
      // { platform: "twitter", href: "https://..." },
    ],
  };
  ```

  <enforcement>
  ZERO hardcoded text in HTML files. Every user-visible string comes from content.js.
  The HTML uses `data-content` attributes or script-based hydration to pull from content.js.

  Pattern in HTML:
  ```html
  <script src="content.js"></script>
  <script>
    // Hydrate content from SITE, HERO, FEATURES, etc.
    document.querySelector('[data-content="hero-headline"]').textContent = HERO.headline;
    // ... or use a minimal hydration loop (see H-LP-HYDRATION)
  </script>
  ```
  </enforcement>

  <hypothesis id="H-LP-HYDRATION">
    CLAIM: A 20-line hydration script using data-content attributes is simpler and less
    error-prone than manual querySelector calls for each element.
    CONFIDENCE: 0.5

    Proposed hydration pattern:
    ```javascript
    document.querySelectorAll('[data-content]').forEach(el => {
      const path = el.dataset.content.split('.');
      let value = window;
      for (const key of path) value = value?.[key];
      if (value) el.textContent = value;
    });
    ```
    Then HTML uses: <h1 data-content="HERO.headline"></h1>
  </hypothesis>
</phase>

<!-- ============================================ -->
<!-- PHASE 4: DESIGN TOKENS                       -->
<!-- ============================================ -->

<phase id="tokens" name="TOKENS — Generate Design Token System">

  <hypothesis id="H-LP-TOKENS">
    CLAIM: A 3-tier token system (primitives → semantics → components) produces more
    consistent sites than flat variable lists.
    CONFIDENCE: 0.6 (modelmind-site uses 2-tier successfully)
  </hypothesis>

  Generate `styles/tokens.css`:

  ```css
  /* ============================================
   * DESIGN TOKENS — Edit this file to change all visual properties.
   * Colors, fonts, spacing, radii — everything lives here.
   * ============================================ */

  :root {
    /* === PRIMITIVE TOKENS (raw values — rarely reference directly) === */

    /* Brand palette */
    --color-brand-500: {primary_hex};
    --color-brand-600: {primary_darker};      /* auto-calculated */
    --color-brand-400: {primary_lighter};     /* auto-calculated */
    --color-brand-50:  {primary_tint};        /* auto-calculated */

    --color-accent-500: {accent_hex};
    --color-accent-600: {accent_darker};
    --color-accent-50:  {accent_tint};

    /* Neutrals */
    --color-neutral-0:   #FFFFFF;
    --color-neutral-50:  #F9FAFB;
    --color-neutral-100: #F3F4F6;
    --color-neutral-200: #E5E7EB;
    --color-neutral-400: #9CA3AF;
    --color-neutral-600: #4B5563;
    --color-neutral-800: #1F2937;
    --color-neutral-900: #111827;
    --color-neutral-950: #030712;

    /* === SEMANTIC TOKENS (what things mean — reference these) === */

    /* Surfaces */
    --surface:        var(--color-neutral-0);
    --surface-raised: var(--color-neutral-50);
    --surface-sunken: var(--color-neutral-100);

    /* Text */
    --ink:            var(--color-neutral-900);
    --ink-secondary:  var(--color-neutral-600);
    --ink-tertiary:   var(--color-neutral-400);
    --ink-inverse:    var(--color-neutral-0);

    /* Interactive */
    --accent:         var(--color-brand-500);
    --accent-hover:   var(--color-brand-600);
    --accent-soft:    var(--color-brand-50);

    /* Feedback */
    --success:  #16A34A;
    --error:    #DC2626;
    --border:   var(--color-neutral-200);

    /* === TYPOGRAPHY === */
    --font-display: '{display_font}', serif;
    --font-body:    '{body_font}', sans-serif;

    /* === SPACING (4px base) === */
    --space-1:  4px;
    --space-2:  8px;
    --space-3:  12px;
    --space-4:  16px;
    --space-6:  24px;
    --space-8:  32px;
    --space-12: 48px;
    --space-16: 64px;
    --space-24: 96px;

    /* === RADII === */
    --radius-sm:   6px;
    --radius-md:   10px;
    --radius-lg:   16px;
    --radius-full: 9999px;

    /* === LAYOUT === */
    --max-width:     1080px;
    --header-height: 64px;
  }

  /* === DARK MODE === */
  [data-theme="dark"],
  html.dark {
    --surface:        var(--color-neutral-950);
    --surface-raised: var(--color-neutral-900);
    --surface-sunken: #050403;

    --ink:            #E8E0D4;
    --ink-secondary:  #8A8279;
    --ink-tertiary:   #5A554E;
    --ink-inverse:    var(--color-neutral-900);

    --accent:         var(--color-brand-400);
    --accent-hover:   var(--color-brand-500);
    --accent-soft:    rgba(var(--color-brand-500), 0.12);

    --border:         rgba(255, 255, 255, 0.08);
  }
  ```

  <hypothesis id="H-LP-DARKMODE">
    CLAIM: Dark mode should be generated by default (opt-out, not opt-in) because
    it prevents the "dark mode debt" failure where adding it later requires full rewrite.
    CONFIDENCE: 0.6
  </hypothesis>

  <hypothesis id="H-LP-FONTS">
    CLAIM: These curated font pairs produce the best results for landing pages:
      1. Space Grotesk + EB Garamond (proven in modelmind-site)
      2. Inter + Playfair Display (common, reliable)
      3. DM Sans + DM Serif Display (matched pair)
    Default to pair 1 unless user specifies.
    CONFIDENCE: 0.4 (only pair 1 tested in production)
  </hypothesis>

</phase>

<!-- ============================================ -->
<!-- PHASE 5: HTML GENERATION                     -->
<!-- ============================================ -->

<phase id="generate" name="GENERATE — Build HTML Files">

  <hypothesis id="H-LP-SECTION-FILES">
    CLAIM: Each HTML section should be its own includable fragment (~50-150 lines)
    assembled into index.html, rather than one monolithic file.
    Counter-hypothesis: For static sites without a build step, includes add complexity.
    A single well-organized HTML file with clear section comments may be simpler.
    CONFIDENCE: 0.4 (modelmind-site uses monolithic successfully at 588 lines)
  </hypothesis>

  <enforcement id="GENERATION_RULES">
  These are the anti-AI-slop enforcement rules. Each is a hypothesis.

  H-LP-E01: ZERO inline colors.
    Every color reference must use var(--token). Grep for hex/rgb in HTML = failure.
    CONFIDENCE: 0.8 (well-established anti-pattern)

  H-LP-E02: ZERO hardcoded text in HTML.
    Every user-visible string references content.js. Grep for bare English strings = failure.
    CONFIDENCE: 0.6 (untested at scale)

  H-LP-E03: ZERO inline styles for layout.
    All layout via Tailwind utilities or main.css classes. No style="" for positioning.
    Exception: Tailwind CDN config block in head is allowed.
    CONFIDENCE: 0.5

  H-LP-E04: Semantic HTML mandatory.
    header, nav, main, section, article, aside, footer. No div-soup.
    CONFIDENCE: 0.9 (a11y standard)

  H-LP-E05: Accessibility baseline.
    Skip link, aria-labels on icon buttons, alt text on images, 44px min touch targets,
    visible focus styles, sufficient contrast (4.5:1 body, 3:1 large).
    CONFIDENCE: 0.9

  H-LP-E06: SEO scaffold complete.
    meta description, OG tags (title, description, type, url, image, dimensions),
    Twitter card tags, canonical link, theme-color (light + dark), favicon, sitemap, robots.txt.
    CONFIDENCE: 0.8

  H-LP-E07: Mobile-first responsive.
    Base styles = mobile. md: breakpoint = tablet. lg: breakpoint = desktop.
    Clamp typography: clamp(min, preferred, max).
    CONFIDENCE: 0.5 (modelmind-site is desktop-first and works fine)

  H-LP-E08: Component CSS classes are semantic.
    .hero-section, .feature-card, .pricing-tier — not .flex-col-gap-4.
    Tailwind utilities compose INTO semantic classes in main.css.
    CONFIDENCE: 0.5

  H-LP-E09: Max 200 lines per HTML section.
    If a section exceeds 200 lines, it needs decomposition.
    CONFIDENCE: 0.4 (arbitrary threshold)

  H-LP-E10: No AI visual monoculture.
    Reject: Inter font, purple-blue gradients, pill-shaped everything, generic stock photos.
    Use the brand's actual colors and fonts. No "safe" defaults that look like every AI site.
    CONFIDENCE: 0.7 (research shows 91% conversion drop for generic AI aesthetic)
  </enforcement>

  <template id="HTML_SKELETON">
  Generate index.html with this structure:

  ```html
  <!DOCTYPE html>
  <html data-theme="light" lang="en">
  <head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>{SITE.name} | {SITE.tagline}</title>
    <meta name="description" content="{SITE.description}"/>

    <!-- OG Tags -->
    <meta property="og:title" content="{SITE.name} — {SITE.tagline}"/>
    <meta property="og:description" content="{SITE.description}"/>
    <meta property="og:type" content="website"/>
    <meta property="og:url" content="{SITE.url}"/>
    <meta property="og:image" content="{SITE.url}/assets/og-image.png"/>
    <meta property="og:image:width" content="1200"/>
    <meta property="og:image:height" content="630"/>

    <!-- Twitter -->
    <meta name="twitter:card" content="summary_large_image"/>
    <meta name="twitter:title" content="{SITE.name}"/>
    <meta name="twitter:description" content="{SITE.description}"/>
    <meta name="twitter:image" content="{SITE.url}/assets/og-image.png"/>

    <!-- Canonical + Theme -->
    <link rel="canonical" href="{SITE.url}/"/>
    <meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)"/>
    <meta name="theme-color" content="#030712" media="(prefers-color-scheme: dark)"/>
    <link rel="icon" href="assets/favicon.svg" type="image/svg+xml"/>

    <!-- Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com"/>
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family={display_font}:wght@400;500;700&family={body_font}:wght@300;400;500;600&display=swap" rel="stylesheet"/>
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght@400&display=swap" rel="stylesheet"/>

    <!-- Tailwind CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
      tailwind.config = {
        darkMode: "class",
        theme: { extend: {
          fontFamily: {
            display: ['{display_font}', 'serif'],
            body: ['{body_font}', 'sans-serif'],
          },
        }},
      };
    </script>

    <!-- Tokens + Styles -->
    <link rel="stylesheet" href="styles/tokens.css"/>
    <link rel="stylesheet" href="styles/main.css"/>

    <!-- Content -->
    <script src="content.js"></script>
  </head>
  <body class="bg-[var(--surface)] text-[var(--ink)] font-body">
    <!-- Skip link (a11y) -->
    <a href="#main" class="skip-link">Skip to content</a>

    <!-- HEADER -->
    <header class="site-header">...</header>

    <!-- MAIN -->
    <main id="main">
      <!-- HERO -->
      <section id="hero" class="hero-section">...</section>

      <!-- FEATURES (if selected) -->
      <section id="features" class="features-section">...</section>

      <!-- PRICING (if selected) -->
      <section id="pricing" class="pricing-section">...</section>

      <!-- TESTIMONIALS (if selected) -->
      <section id="testimonials" class="testimonials-section">...</section>

      <!-- FAQ (if selected) -->
      <section id="faq" class="faq-section">...</section>

      <!-- CTA -->
      <section id="cta" class="cta-section">...</section>
    </main>

    <!-- FOOTER -->
    <footer class="site-footer">...</footer>

    <!-- Theme toggle + content hydration -->
    <script>
      // Theme initialization (respects localStorage + system preference)
      (function() {
        const saved = localStorage.getItem('theme');
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        const theme = saved || (prefersDark ? 'dark' : 'light');
        document.documentElement.setAttribute('data-theme', theme);
        if (theme === 'dark') document.documentElement.classList.add('dark');
      })();

      function toggleTheme() {
        const html = document.documentElement;
        const isDark = html.getAttribute('data-theme') === 'dark';
        html.setAttribute('data-theme', isDark ? 'light' : 'dark');
        html.classList.toggle('dark', !isDark);
        localStorage.setItem('theme', isDark ? 'light' : 'dark');
      }

      // Content hydration
      document.querySelectorAll('[data-content]').forEach(el => {
        const path = el.dataset.content.split('.');
        let value = window;
        for (const key of path) value = value?.[key];
        if (value != null) {
          if (el.tagName === 'IMG') el.setAttribute('src', value);
          else if (el.tagName === 'A') el.setAttribute('href', value);
          else el.textContent = value;
        }
      });
    </script>
  </body>
  </html>
  ```
  </template>
</phase>

<!-- ============================================ -->
<!-- PHASE 6: DEPLOYMENT SCAFFOLD                 -->
<!-- ============================================ -->

<phase id="deploy" name="DEPLOY — Generate Cloudflare Pages Config">

  Generate these files verbatim (proven patterns from production sites):

  **wrangler.toml:**
  ```toml
  name = "{project-name}"
  compatibility_date = "{today}"

  [site]
  bucket = "."
  ```

  **_headers:**
  ```
  /*
    X-Frame-Options: DENY
    X-Content-Type-Options: nosniff
    Referrer-Policy: strict-origin-when-cross-origin
    Permissions-Policy: camera=(), microphone=(), geolocation=(), interest-cohort=()
    X-XSS-Protection: 1; mode=block
    Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.tailwindcss.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data:; connect-src 'self'
    Strict-Transport-Security: max-age=31536000; includeSubDomains

  /styles/*
    Cache-Control: public, max-age=31536000, immutable

  /assets/*
    Cache-Control: public, max-age=31536000, immutable

  /*.html
    Cache-Control: public, max-age=3600, must-revalidate
  ```

  **_redirects:**
  ```
  https://www.{domain}/* https://{domain}/:splat 301
  ```

  **robots.txt:**
  ```
  User-agent: *
  Allow: /

  Sitemap: https://{domain}/sitemap.xml
  ```

  **sitemap.xml:** (generated from selected pages with today's date)

</phase>

<!-- ============================================ -->
<!-- PHASE 7: POST-GENERATION AUDIT               -->
<!-- ============================================ -->

<phase id="audit" name="AUDIT — Verify Enforcement Rules">

  <hypothesis id="H-LP-AUDIT">
    CLAIM: An automated post-generation audit catches more issues than manual review.
    CONFIDENCE: 0.5 (untested)
  </hypothesis>

  Run these checks on the generated output:

  ```bash
  # H-LP-E01: No hardcoded colors in HTML
  grep -rn '#[0-9a-fA-F]\{3,8\}' *.html | grep -v 'content="' | grep -v 'theme-color' | grep -v 'tailwind.config'
  # Should return ZERO matches (excluding meta tags and config)

  # H-LP-E02: No bare English strings in body (approximate — check manually)
  # Look for text nodes not wrapped in data-content attributes

  # H-LP-E05: Accessibility checks
  grep -l 'skip-link' index.html          # Skip link exists
  grep -c 'aria-label' index.html         # aria-labels present
  grep -c 'alt=' index.html               # alt text on images

  # H-LP-E06: SEO completeness
  grep -c 'og:title' index.html           # >= 1
  grep -c 'twitter:card' index.html       # >= 1
  grep -l 'robots.txt' .                  # Exists
  grep -l 'sitemap.xml' .                 # Exists

  # File structure check
  ls content.js styles/tokens.css styles/main.css _headers _redirects wrangler.toml robots.txt sitemap.xml
  ```

  Report: PASS (all checks clean) or FAIL (list violations).
  Fix any violations before presenting to user.
</phase>

<!-- ============================================ -->
<!-- PHASE 8: HANDOFF                             -->
<!-- ============================================ -->

<phase id="handoff" name="HANDOFF — Present to User">
  Show the user:

  ```
  GENERATED: {project-name}/
  ├── index.html          — Main page (edit sections in HTML, text via content.js)
  ├── content.js          — ALL text content (edit this to change words)
  ├── styles/tokens.css   — ALL colors, fonts, spacing (edit this to change look)
  ├── styles/main.css     — Component styles (rarely need to edit)
  ├── wrangler.toml       — Deploy config
  ├── _headers            — Security headers
  └── ...

  TO EDIT CONTENT: Open content.js, change any text, refresh browser.
  TO EDIT COLORS:  Open styles/tokens.css, change --accent or --surface values, refresh.
  TO ADD A PAGE:   Copy index.html, change content references.
  TO DEPLOY:       npx wrangler pages deploy . --project-name={project}
                   (first time: npx wrangler login)
  TO PREVIEW:      Open index.html in browser (works without a server).
  TO VERSION:      git status / git add . / git commit (repo already initialized)
  TO PUSH REMOTE:  gh repo create {project} --public --source=. --push
  ```

  Git status at handoff:
  ```bash
  git log --oneline
  git status --short
  ```
</phase>

<!-- ============================================ -->
<!-- HYPOTHESES REGISTRY                          -->
<!-- ============================================ -->

<hypotheses>
All architectural decisions in this command are hypotheses.
Run /kernel:experiment against a real site generation to test them.

| ID | Claim | Confidence | Domain |
|----|-------|------------|--------|
| H-LP-INIT | Proper repo scaffold (git + .gitignore + README) > raw files | 0.7 | architecture |
| H-LP-INTERVIEW | Single-prompt interview > multi-step wizard | 0.5 | methodology |
| H-LP-STRUCTURE | This file structure minimizes AI generation errors | 0.6 | architecture |
| H-LP-NOBUILD | Zero build tools > any framework for simple sites | 0.7 | architecture |
| H-LP-CONTENT-SINGLE | Single content.js > multiple files for ≤10 pages | 0.5 | architecture |
| H-LP-HYDRATION | data-content attribute hydration > manual querySelector | 0.5 | methodology |
| H-LP-TOKENS | 3-tier token system > flat variable list | 0.6 | architecture |
| H-LP-DARKMODE | Dark mode by default (opt-out) > opt-in | 0.6 | methodology |
| H-LP-FONTS | Space Grotesk + EB Garamond is best default pair | 0.4 | design |
| H-LP-SECTION-FILES | Monolithic HTML > fragment includes for static sites | 0.4 | architecture |
| H-LP-E01 | Zero inline colors enforcement | 0.8 | quality |
| H-LP-E02 | Zero hardcoded text enforcement | 0.6 | quality |
| H-LP-E03 | Zero inline styles for layout | 0.5 | quality |
| H-LP-E04 | Semantic HTML mandatory | 0.9 | quality |
| H-LP-E05 | Accessibility baseline mandatory | 0.9 | quality |
| H-LP-E06 | Complete SEO scaffold mandatory | 0.8 | quality |
| H-LP-E07 | Mobile-first > desktop-first responsive | 0.5 | design |
| H-LP-E08 | Semantic CSS class names > utility-only | 0.5 | design |
| H-LP-E09 | Max 200 lines per section | 0.4 | quality |
| H-LP-E10 | Anti-AI-monoculture enforcement | 0.7 | design |
| H-LP-AUDIT | Automated audit > manual review | 0.5 | methodology |
</hypotheses>

<!-- ============================================ -->
<!-- HARD STOPS                                   -->
<!-- ============================================ -->

<hard_stops>
  - NEVER generate a package.json or build config unless user explicitly requests React/Vite upgrade
  - NEVER hardcode colors in HTML — tokens.css or Tailwind config only
  - NEVER hardcode text in HTML — content.js only
  - NEVER skip SEO scaffold (meta, OG, sitemap, robots)
  - NEVER skip accessibility baseline (skip link, aria, alt, touch targets)
  - NEVER use Inter font as default (AI monoculture signal)
  - NEVER use purple-blue gradient as default (AI monoculture signal)
  - ALWAYS generate _headers with security headers
  - ALWAYS generate wrangler.toml for CF Pages deployment
</hard_stops>

<on_end>
```bash
agentdb write-end '{"command":"landing-page","project":"{name}","sections":[],"hypotheses_applied":[]}'
agentdb learn pattern "landing-page generation" "generated {project} with {sections}"
```
</on_end>

</skill>
