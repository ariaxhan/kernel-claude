# /design --variant=substrate

Cognitive glass aesthetic. Neural layers, translucent depth. High-tech but human.

---

<substrate_aesthetic>
**Metaphor:** Thoughts floating in cognitive space. Information as glass panels. Glowing accents as neural connections. Breathing motion as living system.

## Typography

**Three distinct families:**
- Display: Space Grotesk (headlines, 300 weight, -0.02em tracking)
- Sans: system-ui, SF Pro (body, clean)
- Mono: JetBrains Mono, Fira Code (data/metadata, 0.05-0.1em tracking, uppercase)

**Type classes:**
- `.text-display`: Space Grotesk, light, tight tracking
- `.text-data`: monospace, 0.75rem, wide tracking, uppercase
- `.text-meta`: monospace, 0.6875rem, ultra-wide tracking

**Size pattern:**
- Hero: `clamp(4rem, 12vw, 8rem)` with leading-[0.9]
- Weights: 300 (extralight) for large text, 400 for body

## Color

**Four cognitive accent colors** (each with meaning):
- Cognition #00d9ff (active thinking, cyan)
- Emergence #8b5cf6 (connections, violet)
- Memory #fbbf24 (persistence, amber)
- Data #3b82f6 (flow, blue)

**Substrate layers** (deep to surface):
- void: #0a0814 (absolute, purple-tinted black)
- deep: #0d1b2a (navy)
- mid: #1b263b (lighter navy)
- surface: #2d3e50 (gray-blue)

**Per-color variants:**
- DEFAULT, dim (80%), glow (40%), subtle (20%)
- Example: `cognition-dim`, `cognition-glow`, `cognition-subtle`

**Glass layers:**
- glass-white: rgba(255,255,255,0.03)
- glass-border: rgba(255,255,255,0.08)
- glass-hover: rgba(255,255,255,0.12)
- glass-bg: rgba(13,27,42,0.6)

## Motion

Framer Motion preferred. CSS fallbacks available.

**Entrance patterns:**
```js
initial={{ opacity: 0, y: 40, scale: 0.95 }}
animate={{ opacity: 1, y: 0, scale: 1 }}
transition={{ duration: 0.8, delay: 0.3, ease: [0.4, 0, 0.2, 1] }}
```

**Stagger:** `delay: 0.6 + index * 0.1`

**Ambient animations:**
- `breathe`: opacity 0.6→1, scale 1→1.02, 3s infinite
- `drift`: translate corners with rotation, 20s infinite
- `pulseGlow`: box-shadow pulse, 2.5s infinite
- `float`: translateY oscillation with rotateX, 6s

**Particle systems:**
- `particleFlow`: translateY 100vh→-100vh, opacity fade, 8s
- `networkPulse`: SVG stroke opacity/width, 3s
- `ripple`: expanding circle from center, 2s

**Easing:**
- smooth: `cubic-bezier(0.4, 0, 0.2, 1)`
- bounce-soft: `cubic-bezier(0.34, 1.56, 0.64, 1)`

## Backgrounds

**Glass morphism panels:**
```css
.glass-panel {
  background: rgba(13,27,42,0.6);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255,255,255,0.08);
  box-shadow: 0 4px 30px rgba(0,0,0,0.3),
              inset 0 1px 0 rgba(255,255,255,0.05);
}
```

**Canvas animated backgrounds** for performance (gradient + particle layers).

**Fixed depth layers:** z-index -30 to -5 for substrate, z-10+ for content.

## Shadows & Glows

**Glass shadows:**
- glass: `0 4px 30px rgba(0,0,0,0.3), inset 0 1px 0 rgba(255,255,255,0.05)`
- glass-hover: `0 8px 40px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.08)`

**Cognitive glows:**
- cognition: `0 0 30px rgba(0,217,255,0.3), 0 0 60px rgba(0,217,255,0.1)`
- emergence: `0 0 30px rgba(139,92,246,0.3), 0 0 60px rgba(139,92,246,0.1)`
- memory: `0 0 30px rgba(251,191,36,0.3), 0 0 60px rgba(251,191,36,0.1)`
- data: `0 0 30px rgba(59,130,246,0.3), 0 0 60px rgba(59,130,246,0.1)`

## Layout

**Asymmetric grids:**
- `grid-cols-[1.2fr_1fr]` with gap-16 to gap-24
- Content max: 1200px, prose max: 65ch
- Full-height hero: `min-h-screen`

**Spacing:**
- Horizontal: px-6 lg:px-12
- Vertical sections: py-12 to py-24
- Generous gaps: 10, 12, 16, 24

## Components

**Glass panels:** Translucent bg, backdrop-blur, subtle border, inset highlight.
**Stat cards:** Large extralight values, monospace, staggered entrance.
**Status dots:** Pulsing w-2 h-2, staggered delays, glow shadow.
**Gradient text:** `background-clip: text` with cognitive color gradients.
**Dividers:** Gradient from accent/50 to transparent.

## Anti-Patterns

- Solid opaque backgrounds (use translucency)
- Pure black (#000) or white (#fff)
- Single accent color (use four cognitive colors)
- Static layouts (add breathing, drifting motion)
- Heavy text weights (stay extralight-light)
- Ignoring backdrop-blur (essential for glass effect)
</substrate_aesthetic>

---

## Tokens

```css
:root {
  --substrate-void: #0a0814; --substrate-deep: #0d1b2a;
  --substrate-mid: #1b263b; --substrate-surface: #2d3e50;
  --cognition: #00d9ff; --emergence: #8b5cf6;
  --memory: #fbbf24; --data: #3b82f6;
  --glass-white: rgba(255,255,255,0.03);
  --glass-border: rgba(255,255,255,0.08);
  --glass-bg: rgba(13,27,42,0.6);
}
```
