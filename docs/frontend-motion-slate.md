# Slate: frontend design library expansion (motion + components)

Status: PROPOSAL — awaiting Aria's nod. Nothing minted yet.
Date: 2026-08-07
Origin: MotionSites extract → "library of designs, not frozen specs" conversation.
Recon sources: react-bits, motion-primitives, animata, cult-ui (component registries);
superdesign, onlook, dyad (OSS AI-design tools).

## The architecture: three orthogonal layers

The failure mode to avoid: hyper-specific prompts produce the same website every time.
The fix: capture designs at art-direction altitude and compose along independent axes.

1. **Mood** — existing `skills/frontend/variants/` (abyss, ember, void, ...). What it feels like.
2. **Motion language** — NEW shelf `skills/frontend/motion/`. How it moves. Orthogonal to mood.
3. **Component sources** — NEW `skills/frontend/reference/component-sources.md`. Where real
   building blocks come from, with a restyle-to-direction rule.

9 moods x 6 motion languages = 54 base directions before context-fit even runs.
Any layer can be skipped; frontend's context-fit step always wins over any lens.

## Layer 2: proposed motion languages (6)

Each written like a variant: mood words, dominant idea, signature moves, prohibition ledger.
No fonts, no hex, no stack. Moves reference technique *families*, not component names.

| id | dominant idea | signature moves | must avoid |
|---|---|---|---|
| **kinetic-type** | Text is the only actor; words themselves bend and move | variable-font weight bending near cursor; scroll-velocity skew; per-glyph mask reveals; odometer numbers; split-flap state changes | background shaders, cards emoting, fade-up stagger |
| **haunted-machine** | The UI is old hardware possessed | letter-glitch, scanline/dither reveals, split-flap signage, lightboard hovers, radar pulses | glassmorphism, soft gradients, springy playfulness |
| **cursor-field** | The page is matter that notices you; motion only as response | magnetic pull, fluid/metaball trails, ripple-from-pointer grids, proximity focus/blur, click sparks | ANY autoplaying or scroll-triggered animation |
| **real-weight** | Elements are physical objects with mass and friction | sticker-peel, flingable card decks, dangling/gravity elements, elastic overshoot, gooey nav merges | fades of any kind, instant transitions, shader backgrounds |
| **one-surface** | Nothing appears/disappears; containers morph into next state | shared-element container morphs, island expansion, traveling nav highlight, progressive-blur depth, digit-slide numbers | entrance animations, page-load choreography, >1 thing moving at once |
| **liquid-material** | The page is a substance; interaction disturbs it | liquid-metal surfaces reacting to pointer, lens-blur refraction, metallic text fills, ripple transitions, tracked specular highlights | flat minimalism, mechanical glitch, generic aurora gradients |

Shared preamble for the shelf: reduced-motion support is a hard bar (inherit frontend's);
each language degrades to a static composition that still carries the mood.

## Layer 2b: flexibility mechanisms (stolen conceptually from superdesign/onlook)

Folded into the frontend SKILL.md workflow, not new files:

- **Prohibition ledger**: every lens's "avoid" list is first-class and at least as long as
  its moves list. Bans differentiate better than specs and travel across contexts.
- **Rhythm-as-identity**: a lens may declare a spacing/proportion discipline (tight 4pt grid
  vs airy irregular vs dense editorial) — checkable, but not a font or a hex.
- **Tournament iteration**: for exploration, generate 2-3 divergent interpretations of the
  same mood x motion pick, fork the winner. The lens is a direction vector, not a template.
- **Content-bends-the-lens**: explicit rule that a lens yields to the subject (onlook's
  "infer a distinct style from intent"). Prevents any lens from becoming a house style.

## Layer 3: component-sources registry

`skills/frontend/reference/component-sources.md` — one row per library:

| library | strength | install path | license |
|---|---|---|---|
| react-bits (DavidHDev/react-bits) | text effects, ~45 WebGL backgrounds, cursor toys, physics | shadcn registry / jsrepo | MIT + Commons Clause (check per component) |
| motion-primitives (ibelick) | container morphs, springs, text effects | shadcn-style CLI | MIT |
| animata (codse) | product widgets, bento, micro-interactions | copy-paste | MIT |
| cult-ui (nolly-studio) | texture/material surfaces, iOS-style morphs | shadcn registry | MIT |

### Expansion rows (second recon sweep, licenses verified 2026-08-07)

Components (all MIT unless noted):
| library | strength | install |
|---|---|---|
| magicui (magicuidesign/magicui) | 150+ animated components, landing-page effects | shadcn registry |
| kokonutui (kokonut-labs) | animated cards/buttons/AI-chat widgets | shadcn registry |
| uilayouts (ui-layouts) | layout-level animated patterns (sticky scroll, reveals) | copy-paste/registry |
| smoothui (educlopez) | tasteful micro-interaction snippets | copy-paste |
| stackzero-labs/ui | e-commerce blocks (only good commerce registry) | shadcn registry |

Shader/canvas/3D:
| library | strength | install | license |
|---|---|---|---|
| paper-shaders (paper-design) | zero-dep React shader backgrounds, purpose-built | npm | Apache-2.0 |
| shadergradient (ruucm) | designer-grade moving 3D gradients + configurator | npm | MIT |
| tsparticles | particles, confetti, fireworks | npm | MIT |
| cobe (shuding) | 5KB WebGL globe hero widget | npm | MIT |
| react-three-fiber + drei (pmndrs) | full 3D lane; drei ready effects | npm | MIT |
| vanta.js | drop-in 3D backgrounds (dated but reliable) | npm | MIT |

Motion primitives:
| library | strength | install | license |
|---|---|---|---|
| anime.js v4 | timelines, SVG, spring physics | npm | MIT |
| auto-animate (formkit) | zero-config layout/list transitions | npm | MIT |
| lenis (darkroomengineering) | smooth-scroll foundation | npm | MIT |
| tailwindcss-animate | CSS enter/exit baseline shadcn assumes | npm | MIT |
| GSAP | timelines, ScrollTrigger, SplitText — all plugins now free | npm | custom no-charge, NOT OSI — flag |

Design direction:
| library | strength | license |
|---|---|---|
| open-props (argyleink) | curated tokens; the easing curves esp. | MIT |
| fontsource | deterministic npm installs of open fonts (pairings) | MIT (fonts OFL) |

DO-NOT-USE ledger (licensing): originui — now AGPL-3.0, copyleft; aceternity — no verifiable
license, inspiration only; hover.dev — no license file, mostly paid; background-snippets — no
license file; uiverse galaxy — MIT but quality too uneven for a curated registry.

Taxonomy additions from sweep: page transitions (View Transitions API / barba), smooth-scroll
foundation as infrastructure distinct from scroll effects, celebration/confetti moments,
globe/map hero widgets, FLIP/auto-layout transitions, and easing-vocabulary-as-direction
(open-props easings).

Registry rules:
1. **Pull the primitive, restyle to the active direction. Never ship stock.** A stock
   component reintroduces same-website-syndrome with prettier parts.
2. Verify license per component at pull time (react-bits has mixed licensing).
3. Registry is append-only extensible: future libraries (magicui, aceternity, ...) are a
   row each, no skill changes.
4. Tired-defaults blacklist rides along: fade-up-on-scroll, generic hover scale, border-beam,
   shimmer text, count-up numbers, logo marquee, spotlight cards, bento-for-its-own-sake —
   never as the identity move, only as supporting cast if at all.

## Build plan (after nod)

1. `skills/frontend/motion/{6 files}` in kernel-claude, matching variant file format.
2. `skills/frontend/reference/component-sources.md`.
3. SKILL.md edits: motion shelf loading, composition rule, tournament + content-bends-the-lens.
4. Description/trigger updates so the new lens names route.
5. Release via normal kernel-claude flow; upgrade the install. No cache patching.

Estimate: 1-2 agent-hours. All original writing; recon informed the taxonomy only.
