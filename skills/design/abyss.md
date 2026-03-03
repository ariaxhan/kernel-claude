# /design --variant=abyss

Deep-sea bioluminescent aesthetic. Objects emit their own light against void darkness.

---

<abyss_aesthetic>
**Metaphor:** Data archaeology in deep-water environment. Light from within, not external illumination.

## Typography

Fonts: JetBrains Mono (data/labels), paired with light-weight sans (300-400 for headings). All headings use font-weight 400—elegant, not aggressive. Monospace for timestamps, IDs, technical labels. Warm bone-toned text (#e4e0d6), never pure white.

## Color

**Void depth palette** (5 levels, progressive lightening):
- void-0 through void-5: #080b10 → #0a0e14 → #0d1219 → #111820 → #161e28 → #1c2632
- Never pure black. Blue-shifted darks create sophistication.

**Bioluminescent accents** (each with semantic meaning):
- Cyan #5ccfe6 (primary interactions, sonar returns)
- Teal #41b5a0 (success, health, growth)
- Amber #e6a959 (warnings, warmth, specimen labels)
- Coral #e85a5a (danger, toxicity, alerts)
- Violet #9d7cd8 (system, mystique, deep trench)

**Surfaces:** All rgba(255,255,255,0.02-0.08). Translucent white, not solid colors. Creates layered depth.

## Motion

Default easing: `cubic-bezier(0.4, 0, 0.2, 1)` (ease-water, organic flow).

**Breathing animations** (slow, life-like):
- `breathe`: opacity 0.4→0.6, scale 1→1.02, 4s infinite
- `pulse-glow`: box-shadow intensity oscillation, 2s infinite

**Feedback:**
- `sonar-ping`: scale 0.8→2.5, opacity fade, 1s (alerts)
- `fade-in-up`: opacity + translateY(10px), 500ms (content reveal)

State-based animation: elements breathe when healthy, flicker when stressed, go static when dissociated.

## Backgrounds

Multi-layer radial gradients at low opacity (0.02-0.03):
```css
background:
  radial-gradient(ellipse at 20% 80%, rgba(92,207,230,0.03)),
  radial-gradient(ellipse at 80% 20%, rgba(157,124,216,0.03)),
  var(--void-0);
```

Custom scrollbars matching void palette. Selection highlight in cyan tint.

## Components

**Cards:** surface-1 background, 1px border-subtle, darken + border-brighten on hover.
**Messages:** Asymmetric margins (user right-aligned, assistant left-aligned), colored left-border indicates type.
**Health orbs:** Radial gradient core, glow-lg shadow, pulse-ring animation, color encodes state.
**Semantic sliders:** Thumb color matches scale meaning (coral for toxicity, teal for nutrient).

## Anti-Patterns

- Pure black or pure white anywhere
- Harsh neon (use softer bioluminescent glows)
- Static elements (everything should subtly breathe)
- Flat single-color surfaces
- External lighting aesthetic (light comes from objects)
</abyss_aesthetic>

---

## Tokens (Copy-Paste Ready)

```css
:root {
  --void-0: #080b10; --void-1: #0a0e14; --void-2: #0d1219;
  --void-3: #111820; --void-4: #161e28; --void-5: #1c2632;
  --glow-cyan: #5ccfe6; --glow-teal: #41b5a0; --glow-amber: #e6a959;
  --glow-coral: #e85a5a; --glow-violet: #9d7cd8;
  --text-primary: #e4e0d6; --text-secondary: #a09a8c;
  --text-muted: #6b6560; --text-ghost: #454240;
  --ease-water: cubic-bezier(0.4, 0, 0.2, 1);
}
```
