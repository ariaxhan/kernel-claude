---
name: design
description: Frontend aesthetics - break distributional convergence, create distinctive interfaces
triggers:
  - design
  - frontend
  - ui
  - styling
  - css
  - visual
---

# /design

Load variation: `/design --variant=abyss|spatial|verdant|substrate`

---

<frontend_aesthetics>
You tend to converge toward generic, "on distribution" outputs. In frontend design, this creates what users call the "AI slop" aesthetic. Avoid this: make creative, distinctive frontends that surprise and delight.

## Focus Areas

**Typography:** Choose fonts that are beautiful, unique, and interesting. Avoid generic fonts like Inter, Roboto, Arial, system-ui. Opt for distinctive choices: JetBrains Mono, Space Grotesk, IBM Plex, Bricolage Grotesque. Use weight extremes (300 vs 700, not 400 vs 500). Size jumps of 3x+.

**Color & Theme:** Commit to a cohesive aesthetic. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes. Dark modes with layered depth (5+ background shades). Draw from IDE themes and cultural aesthetics for inspiration.

**Motion:** Use animations for effects and micro-interactions. Prioritize CSS-only solutions. Focus on high-impact moments: one well-orchestrated page load with staggered reveals creates more delight than scattered micro-interactions. Default easing: `cubic-bezier(0.4, 0, 0.2, 1)` (organic, not linear).

**Backgrounds:** Create atmosphere and depth rather than defaulting to solid colors. Layer CSS gradients, use geometric patterns, or add contextual effects. Translucent surfaces with backdrop-blur. Subtle radial gradients at corners (2-3% opacity).

## Anti-Patterns (Never)

- Inter, Roboto, Open Sans, system fonts
- Purple gradients on white backgrounds
- Neon cyan/pink/purple AI aesthetic
- Flat, single-color backgrounds
- Uniform sections (no visual variety)
- Heavy font weights everywhere
- Jarring transitions (use organic easing)

## Principles

```
restraint > noise        (every element serves meaning)
semantic > decorative    (colors encode data/state)
organic > mechanical     (breathing, not snapping)
depth > flat             (layered backgrounds)
warm > sterile           (bone tones, not pure white)
```

## Variations

| Variant | Aesthetic | Best For |
|---------|-----------|----------|
| abyss | Deep-sea bioluminescent, void depths | Data-dense dashboards |
| spatial | 3D datascape, living geometry | WebGL, Three.js, immersive |
| verdant | Growth/vegetation, green glow | Financial, health, progress |
| substrate | Cognitive glass, neural layers | Portfolios, cerebral sites |

Interpret creatively and make unexpected choices. Vary between themes, fonts, aesthetics. Even with this guidance, you may converge to new local maxima (Space Grotesk, for example). Avoid this: think outside the box for each generation.
</frontend_aesthetics>

---

## ●:ON_START

```bash
agentdb read-start
```

## ●:ON_END

```bash
agentdb write-end '{"skill":"design","variant":"X","patterns":["Y"]}'
```
