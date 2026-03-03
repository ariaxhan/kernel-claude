# /design --variant=verdant

Growth/vegetation aesthetic. Green glow on deep dark. Living data, seasonal rhythms.

---

<verdant_aesthetic>
**Metaphor:** Greenhouse for data. Growth, health, seasons. Biotechnology meets financial clarity.

## Typography

**Three font families with purpose:**
- System sans (body): Clean, readable, professional
- Monospace (data/numbers): JetBrains Mono, SF Mono—technical precision, bold weights (600)
- Serif (narrative): Georgia—storytelling blocks, context, warmth

Letter-spacing: 0.04em on brand text, 0.08em on uppercase section headers. Numbers always monospace.

## Color

**Background depth** (green-shifted blacks):
- deep: #060b06 (absolute)
- base: #0a0f0a (primary)
- surface: #111a11 (cards)
- elevated: #162016 (hover)
- hover: #1a2a1a (active)

**Green spectrum** (primary brand):
- dim: #1a3a1a (background accents)
- muted: #2d5a2d (scrollbar, subtle)
- mid: #3a8a3a (interactive)
- bright: #4ade80 (primary, glows)
- vivid: #22ff66 (intense highlights)

**Season-specific accents:**
- Spring: #4ade80 (green, renewal)
- Summer: #fbbf24 (golden amber, peak)
- Autumn: #f97316 (orange, harvest)
- Winter: #60a5fa (blue, dormancy)

**Semantic status:**
- Positive: #4ade80, Negative: #f87171, Warning: #fbbf24, Info: #60a5fa

**Borders:** rgba(74,222,128,0.08-0.30)—green-tinted, not white.

## Motion

Easing: `cubic-bezier(0.4, 0, 0.2, 1)` (organic).

**Durations:**
- fast: 150ms (hover)
- base: 250ms (transitions)
- slow: 400ms (progress fills)

**Glow effects:**
```css
--glow-subtle: 0 0 8px rgba(34,255,102,0.08);
--glow-soft: 0 0 12px rgba(34,255,102,0.15);
--glow-medium: 0 0 20px rgba(34,255,102,0.25);
--glow-intense: 0 0 30px rgba(34,255,102,0.4);
```

Cards gain glow on hover. Progress bars use slow transitions for satisfying fills.

## Backgrounds

Dark terminal-like base. Green glow creates life/energy against darkness.

**SVG visualizations:**
- Gaussian blur filters (stdDeviation 1.5-3) for glowing elements
- Stroke-dasharray for animated progress rings
- Gradients with opacity decay

**Narrative blocks:**
- Left border 3px, color-coded by season
- Subtle tinted background (4% season color)
- Serif font for storytelling feel

## Components

**Cards:**
- bg-surface, border-subtle (green-tinted)
- Padding: 24px, radius: 12px
- Hover: border elevates, optional glow

**Badges:**
- `color-mix(in srgb, badge-color 12%, transparent)` backgrounds
- Matching border, semantic coloring

**Navigation:**
- Vertical sidebar, left border accent for active
- Mobile: horizontal tab bar, bottom border accent

**Progress rings:**
- SVG circles with stroke-dashoffset
- Color shifts by value: dim <0.3, bright 0.3-0.6, vivid >0.6
- Glow point at leading edge

**Metric cards:**
- Large monospace values (24px, weight 600)
- Trend indicators: ▲/▼ with semantic color
- Hover glow enhancement

## Anti-Patterns

- Blue/purple accents (stay in green family)
- Pure gray backgrounds (use green-shifted darks)
- Sans-serif for narrative text (use serif)
- Flat progress indicators (add glow)
- Ignoring seasonal context
</verdant_aesthetic>

---

## Tokens

```css
:root {
  --bg-deep: #060b06; --bg-base: #0a0f0a; --bg-surface: #111a11;
  --bg-elevated: #162016; --bg-hover: #1a2a1a;
  --green-dim: #1a3a1a; --green-muted: #2d5a2d; --green-mid: #3a8a3a;
  --green-bright: #4ade80; --green-vivid: #22ff66;
  --text-primary: #d4e4d4; --text-secondary: #8aaa8a; --text-dim: #5a7a5a;
  --border-subtle: rgba(74,222,128,0.08);
  --border-visible: rgba(74,222,128,0.15);
  --ease-organic: cubic-bezier(0.4, 0, 0.2, 1);
}
```
