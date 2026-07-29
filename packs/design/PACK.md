---
name: design
kind: domain-pack
description: Visual iteration, interface, and art direction. Loaded when the router classifies domain=design.
---

# Design pack

Loaded on demand. Universal rules live in the kernel core and are not repeated here.

## Evidence that matters

The rendered artifact. Re-reading the CSS you just wrote is not verification and
never was. Look at the thing.

Art direction is derived, not chosen from a menu: product, audience, brand,
content, and the existing design system decide it. A house style imposed on a
project that does not want it is a defect.

The existing design system outranks your preference. Match tokens, spacing scale,
and type ramp before inventing new ones.

## Execution patterns

**direct** — one bounded visual change with an obvious target. Make it, look at
it, done.

**gated** — a new surface or component. Establish direction, build, render, and
inspect at the breakpoints that matter.

**trajectory** — the natural shape for visual work, and the one place it is
genuinely earned. Each render changes what the next move should be. Render,
react, adjust, render. Stop when two passes produce no improvement, or when the
target becomes specifiable in advance, at which point it is gated work.

## Verification

Render the artifact and inspect it. For aesthetic judgments, blinded pairwise
comparison against the prior version; the author of a design is the worst judge of
whether it improved.

Interface work: check the layouts that actually ship, confirm no console errors,
and confirm every interactive element is reachable by keyboard.

Screenshots are evidence. Descriptions of screenshots are not.

## Hazards

- **Generic AI aesthetic.** Default fonts, default spacing, default gradient,
  emoji as iconography. This is the single most common failure.
- **Verifying by reading.** The most expensive mistake in this domain.
- **Breakpoint blindness.** Correct at one width, broken at the others.
- **Contrast and motion accessibility** treated as polish rather than correctness.
- **Infinite iteration.** Trajectory without a stopping rule is not craft, it is
  drift. Name the stopping condition when you enter the loop.

## Optional skills

`frontend` (context-led art direction) · `landing-page` (explicit generator)

Testing and commit ceremony does not apply to design judgment. It applies only to
the code that implements a design, under the software pack.
