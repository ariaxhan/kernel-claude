---
name: frontend
description: "Frontend aesthetics and UI implementation. Break generic AI aesthetic patterns. Create distinctive, surprising interfaces. Supports mood variants that guide aesthetic direction without constraining execution. Triggers: frontend, ui, styling, css, visual, theme, component, layout, aesthetic, abyss, spatial, verdant, substrate, ember, arctic, void, patina, signal."
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
kernel:
  kind: methodology
  version: 1
  side_effects: none
  confirmation: none
---

<skill id="frontend">

<purpose>
Break distributional convergence. Every generation must feel intentional and distinct.
Generic AI aesthetic ("slop") is the failure mode.
You are good at CSS. You are bad at breaking patterns. This skill fixes the latter.
</purpose>

<invocation>
/design                      → No variant. Choose your own direction. Surprise.
/design --variant={name}     → Load variants/{name}.md for mood guidance.

Variant files define VIBE not implementation.
You choose fonts, colors, spacing, motion.
Never copy same font/palette/layout between generations even within same variant.
</invocation>

<variants>
abyss, spatial, verdant, substrate, ember, arctic, void, patina, signal

Read variants/ directory for full mood definitions.
Each defines sensory direction and emotional target—not specs.
</variants>

<principles type="always-active">

<typography>
1. Distinctive fonts only — NEVER: Inter, Roboto, Arial, Open Sans, system-ui, Helvetica, SF Pro
2. Pair weight extremes (300 + 700+). Avoid 400–500 middle zone entirely.
3. Headers 3x+ body size minimum. Tight tracking on large, relaxed on small.
4. (gate: if same font used in last 3 outputs → pick a different one)
</typography>

<color>
1. CSS custom properties for all colors. One dominant + one sharp accent.
2. Dark modes require 5+ background shade layers. Single dark color = amateur.
3. Warm text on dark: bone/cream tones. Never pure white on dark.
4. (gate: palette derives from variant mood, not memorized hex values)
</color>

<motion>
1. CSS-only first. JS only when CSS literally cannot achieve it.
2. One orchestrated entrance beats scattered micro-interactions.
3. Organic easing always: cubic-bezier curves, never linear. Breathing > snapping.
4. (gate: vary timing per project — no reused duration scale)
</motion>

<layout>
1. Asymmetry over symmetry. Grid-break moments over uniform grids.
2. Whitespace is a design element. Use aggressively to create tension.
3. Full-bleed mixed with contained sections creates rhythm.
4. (gate: uniform section heights = amateur → vary intentionally)
</layout>

<surfaces>
1. NEVER flat single-color backgrounds.
2. Layer: gradients, translucent surfaces, backdrop-blur, subtle noise.
3. Cards need visible depth: shadow, border, or background differentiation.
4. Dark backgrounds need hue tint. Light from within (glow) beats external illumination.
</surfaces>

<core>
1. Prompt for taste, not implementation. Describe WHAT the user should feel; model chooses HOW.
2. Component-first. Build pieces (nav, hero, cards), then compose. Never full pages in one shot.
3. Mobile-first as constraint: specify column limits and 44px touch targets upfront.
4. Functional color (encodes meaning: status, priority, state) beats decorative color.
5. Accessibility = design advantage. WCAG contrast forces better color decisions.
</core>

<reference>
Skill-specific: skills/frontend/reference/design-research.md
</reference>

</principles>

<anti-convergence>
After generating, ask: "Have I seen this exact combination before?"
If yes → change the most dominant visual element immediately.
If variant starts producing similar outputs → interpret it more loosely.
Constraints breed creativity. Variant mood is springboard not cage.
</anti-convergence>

<anti-patterns>
<block>System/generic fonts (Inter, Roboto, Arial, system-ui)</block>
<block>Purple-gradient-on-white (the AI slop signature)</block>
<block>Neon cyan + pink + purple together (vaporwave cliché)</block>
<block>Flat single-color backgrounds</block>
<block>Uniform section heights and widths</block>
<block>Heavy font weights on everything (use weight contrast)</block>
<block>Repeating same aesthetic across generations</block>
<block>Following variant too literally (it's a vibe not a spec)</block>
<block>Centered everything (break the symmetry)</block>
<block>Stock icon libraries without customization</block>
<block>Rounded corners on everything (vary or eliminate)</block>
</anti-patterns>

<on_complete>
agentdb write-end '{"skill":"design","variant":"<if-used>","fonts":["<list-for-tracking>"],"aesthetic":"<2-word-summary>","dominant_color":"<name-not-hex>"}'
</on_complete>

</skill>
