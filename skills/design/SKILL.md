---
name: design
description: "Frontend aesthetics and UI implementation. Break generic AI aesthetic patterns. Create distinctive, surprising interfaces. Supports mood variants that guide aesthetic direction without constraining execution. Triggers: design, frontend, ui, styling, css, visual, theme, component, layout, abyss, spatial, verdant, substrate, ember, arctic, void, patina, signal."
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

<skill id="design">

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
- Distinctive fonts only. NEVER: Inter, Roboto, Arial, Open Sans, system-ui, Helvetica, SF Pro
- Weight extremes: pair 300 with 700+. Avoid the 400-500 middle zone entirely
- Size contrast: headers 3x+ body minimum. Go bigger
- Tracking: tight on large text, relaxed on small. Never default
- CRITICAL: If you've used the same font in your last 3 outputs, pick a different one
</typography>

<color>
- Commit to a cohesive mood. CSS custom properties for all colors
- One dominant + one sharp accent beats even distribution every time
- Dark modes need 5+ background shade layers. Single dark color = amateur
- Derive palette from variant mood. Never memorized hex values
- Warm text colors. Bone/cream tones on dark. Never pure white on dark
</color>

<motion>
- CSS-only first. JS only when CSS literally cannot achieve it
- One orchestrated entrance beats scattered micro-interactions
- Organic easing always: cubic-bezier curves, never linear
- Breathing > snapping. Drift > jump. Ease > instant
- Vary timing per project. Don't reuse same duration scale
</motion>

<layout>
- Asymmetry over symmetry. Grid-break moments over uniform grids
- Whitespace as design element. Use aggressively where it creates tension
- Full-bleed mixed with contained sections creates rhythm
- Uniform section heights = amateur. Vary intentionally
- Let content dictate structure, not templates
</layout>

<surfaces>
- NEVER flat single-color backgrounds
- Layer: gradients, translucent surfaces, backdrop-blur, subtle noise
- Cards need visible depth: shadow, border, or background differentiation
- Dark backgrounds need hue tint. Never pure black or pure gray
- Light from within (glow, shadow-color) beats external illumination
</surfaces>

<core>
- Prompt for taste, not implementation. Describe WHAT the user should feel; let the model choose HOW
- Intent over specification. Mood, constraints, and anti-patterns beat hex codes and font names
- Component-first. Build pieces (nav, hero, cards), then compose. Never generate full pages in one shot
- Mobile-first as constraint, not afterthought. Specify column limits and touch targets upfront
- Functional color. Color that encodes meaning (status, priority, state) always beats decorative color
- Accessibility is a design advantage. WCAG contrast ratios force better color decisions. 44px touch targets prevent cramped layouts
</core>

<reference>
Skill-specific: skills/design/reference/design-research.md
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
