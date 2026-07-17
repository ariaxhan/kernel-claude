---
name: frontend
description: "Context-led frontend design and UI implementation. Derives art direction from the product, audience, brand, content, and existing design system; prevents generic AI defaults without imposing a Kernel house style. Triggers: frontend, ui, styling, css, visual, theme, component, layout, responsive, accessibility, design system, aesthetic, abyss, spatial, verdant, substrate, ember, arctic, void, patina, signal."
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
kernel:
  kind: methodology
  version: 2
  side_effects: none
  confirmation: none
---

<skill id="frontend">

<purpose>
Make interfaces feel intentional because their visual choices fit the actual product.
Distinctiveness is not a pile of effects. It is a coherent point of view with fewer
unexamined defaults.
</purpose>

<context-fit>
Before styling, recover the evidence already present in the task and repository:

1. Product: what the interface does and which action matters most.
2. Audience and use context: device, environment, familiarity, urgency, accessibility needs.
3. Brand: existing tokens, logo, type, imagery, voice, screenshots, and reference qualities.
4. Content: real density, length, hierarchy, empty/error/loading states, and localization risk.
5. Technical constraints: current stack, component library, performance budget, supported browsers.

Preserve and extend the existing design system when one exists. Do not replace a coherent
brand because a variant or personal preference is louder. If the evidence is incomplete,
make the smallest reversible assumption and state it; ask only when the answer changes the
product direction.
</context-fit>

<art-direction>
Write a tiny direction before implementation:

- desired feeling in 2-3 plain words;
- one dominant visual idea;
- typography, color, layout, imagery, and motion choices tied to evidence;
- 2-3 defaults to avoid for this specific project.

No choice is universally premium. A system font can be correct for speed or platform
familiarity. Symmetry can communicate calm. Flat color can be the strongest choice. Huge
type, gradients, glass, noise, asymmetry, and animation are tools—not proof of taste.
</art-direction>

<variants>
Optional lenses: abyss, spatial, verdant, substrate, ember, arctic, void, patina, signal.
Load `variants/{name}.md` when the user names one or when exploration genuinely benefits.
Variants describe mood, never mandatory components, fonts, palettes, effects, or layouts.
</variants>

<hard-bars>
- Hierarchy: the primary action and reading order are obvious without explanation.
- Responsive: content fits and remains usable at the project breakpoints; touch targets are
  at least 44px where touch is expected.
- Accessible: semantic structure, keyboard operation, visible focus, useful labels/alt text,
  AA contrast, reduced-motion support, and no meaning encoded by color alone.
- Content-real: test realistic long/short copy plus empty, error, loading, and disabled states
  when the interface has them.
- Performance: avoid decorative weight that delays the main content; size images, subset or
  avoid webfonts, and use JavaScript only for behavior that needs it.
- System-fit: reuse the repository's components, tokens, naming, and state patterns unless the
  task explicitly includes changing the system.
</hard-bars>

<implementation>
Use the smallest structure the product needs. Reusable components should follow the existing
stack; a one-off static section does not need a component framework. Centralize repeated
visual decisions in tokens. Prefer CSS for presentation, semantic HTML for structure, and
progressive enhancement for interaction.

Motion must explain change, guide attention, or provide feedback. If it does none of those,
remove it. Decorative texture, depth, and unusual composition need the same justification.
</implementation>

<anti-convergence>
Generic output usually comes from an unexamined default, not from a forbidden ingredient.
Before finishing, name the most dominant visual decision and ask:

1. What evidence caused this choice?
2. Is it inherited from the product, or copied from recent model habits?
3. Would removing it make the interface clearer or more specific?

Common warning signs—not automatic bans—include purple gradient startup pages, identical
rounded cards, default component-library styling, ornamental dashboards, centered-everything
layouts, decorative blobs, fake testimonials, and a fashionable font with no brand reason.
Change a warning sign when it is unexamined; keep it when the context earns it.
</anti-convergence>

<verification>
Do visual QA on rendered output, not source alone. Inspect screenshots at the task's target
sizes (for a general web page, start with 375, 768, and 1440 widths), then exercise keyboard,
focus, hover/touch, overflow, and reduced motion. Fix the largest hierarchy or usability
problem first and re-check. Never claim visual completion without seeing the rendered result.
</verification>

<reference>
Read `skills/frontend/reference/design-research.md` when deeper rationale is useful.
</reference>

<on_complete>
Report the art direction, evidence behind the dominant choices, sizes/states visually checked,
and any accessibility or performance bar not verified.
</on_complete>

</skill>
