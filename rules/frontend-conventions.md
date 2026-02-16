---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.css"
  - "**/*.scss"
  - "**/*.vue"
  - "**/*.svelte"
  - "**/*.html"
---

# Frontend Conventions

**KERNEL-specific frontend guidance. Extends design-philosophy.md.**

---

## Before Writing Frontend Code

### 1. Understand the Project Context

```
BEFORE touching CSS or components:
→ What framework is this project using?
→ What styling solution is already in place?
→ What design tokens/variables exist?
→ What's the existing component pattern?

MATCH THE PROJECT. Don't introduce new patterns.
```

### 2. Understand the User Flow

```
BEFORE designing a feature:
→ What is the user trying to accomplish?
→ What's the shortest path to that goal?
→ What state changes will they see?
→ What errors might they encounter?

DESIGN FOR THE FLOW. Not for the component.
```

---

## Styling Conventions

### System Fonts First

Unless the project has a specific font choice, use system fonts:

```css
/* Preferred stack */
font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;

/* Monospace */
font-family: ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Consolas, monospace;
```

If the project uses a custom font, use it. **Never default to Inter or Geist** (AI aesthetic signatures).

### Typography as Personality

Typography is the hero of brand personality, not just readability.

```
GUIDELINES:
- Custom type pairing nobody else uses > safe defaults
- Character over uniformity (rigid sans-serif everywhere = AI slop)
- Hierarchy through size/weight/spacing, not decoration
- Consider type that changes personality across contexts
  (formal in contracts, playful in onboarding)
```

### Color Strategy

```
PALETTE RULES:
- Most UI is neutral (grays, blacks, whites)
- 1 primary color for interactive elements
- 1-2 semantic colors (success, error, warning)
- Color communicates meaning, not decoration
- ONE signature color increases brand recognition 80%

AVOID (AI SIGNATURES):
- Purple-to-blue gradients (THE AI tell)
- Exact Tailwind default colors (#3B82F6, #6366F1, etc.)
- Rainbow palettes with no hierarchy

DARK MODE:
- Not inverted light mode
- Designed from scratch for dark contexts
- Reduce contrast slightly (not pure white on pure black)
```

### Spacing System

Use consistent spacing scales. If the project has a system, use it. If not:

```css
/* 4px base unit */
--space-1: 4px;   /* tight */
--space-2: 8px;   /* default */
--space-3: 12px;  /* comfortable */
--space-4: 16px;  /* section */
--space-6: 24px;  /* large */
--space-8: 32px;  /* major */
```

Don't invent spacing values. Use the scale.

**Spacing as signature:** Just as music has a beat, interfaces can have a distinctive spacing "pulse" that becomes part of brand recognition. Consider:
- **Regular rhythms:** Same spacing between elements (calm, predictable)
- **Progressive rhythms:** One characteristic changes as it repeats (evolving, narrative)
- **Asymmetric layouts:** Intentional imbalance that serves content

---

## Component Patterns

### Interactive Elements

```
BUTTONS:
- Clear affordance (looks clickable)
- Hover/focus/active states
- Disabled state is obviously disabled
- Loading state if action is async

INPUTS:
- Clear boundaries
- Focus state is obvious
- Error state shows inline
- Labels are always visible (not placeholder-only)

LINKS:
- Visually distinct from text
- Hover state
- Visited state (when relevant)
```

### Feedback Patterns

```
PREFER:
- Inline feedback (near the action)
- State changes in place
- Undo over confirm
- Progressive disclosure

AVOID:
- Toasts for routine actions
- Modals for non-critical confirmations
- Alerts that interrupt flow
- Success messages that state the obvious
```

### Loading States

```
UNDER 200ms: Show nothing (feels instant)
200ms-1s: Subtle indicator (spinner, opacity change)
OVER 1s: Meaningful loading state (skeleton, progress)

NEVER:
- Skeleton loaders for fast operations
- Full-page spinners for partial loads
- Loading states that flash (feels janky)
```

---

## CSS Techniques (Encouraged)

### Layout

```css
/* CSS Grid for 2D layouts */
display: grid;
grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));

/* Flexbox for 1D alignment */
display: flex;
align-items: center;
gap: var(--space-2);

/* Container queries for component-level responsiveness */
@container (min-width: 400px) { ... }
```

### Interaction

```css
/* Smooth but fast transitions */
transition: opacity 150ms ease, transform 150ms ease;

/* Micro-interactions that confirm */
button:active { transform: scale(0.98); }

/* Focus-visible for keyboard users */
:focus-visible { outline: 2px solid var(--focus-color); }
```

### Visual Depth

```css
/* Subtle shadows for elevation */
box-shadow: 0 1px 2px rgba(0,0,0,0.1);

/* Backdrop blur for overlays */
backdrop-filter: blur(8px);

/* Gradients for dimensional surfaces, not decoration */
background: linear-gradient(to bottom, var(--surface), var(--surface-raised));
```

### Modern CSS

```css
/* :has() for parent selection */
.card:has(.error) { border-color: var(--error); }

/* Logical properties for internationalization */
margin-inline-start: var(--space-2);

/* Color-mix for dynamic colors */
background: color-mix(in srgb, var(--primary) 10%, transparent);
```

---

## Framework-Specific Notes

### React

```
- Prefer CSS modules or styled-components over inline styles
- Use CSS for animation unless orchestration is complex
- Memo/useMemo for expensive renders, not premature optimization
- Fragment over unnecessary wrapper divs
```

### Tailwind (If Project Uses It)

```
- Use the design system (colors, spacing) not arbitrary values
- Extract repeated patterns to components, not @apply
- Avoid class soup - if it's unreadable, refactor
- Dark mode: dark: prefix, not separate classes
```

### Svelte

```
- Scoped styles are powerful - use them
- Transitions built-in - use them tastefully
- Reactive statements for derived values
```

### Vue

```
- Scoped styles with <style scoped>
- v-bind in CSS for dynamic values
- Transition components for enter/leave
```

---

## Performance Checklist

```
□ No layout shifts (reserve space for dynamic content)
□ Images have dimensions or aspect-ratio
□ Fonts are preloaded or system fonts
□ Animations use transform/opacity (GPU-accelerated)
□ No expensive selectors in hot paths
□ CSS is scoped (no global pollution)
□ Bundle size is monitored
```

---

## Code Review Lens

When reviewing frontend code, check:

1. **Does it match project conventions?** (Not introducing new patterns)
2. **Is the styling systematic?** (Using tokens, not magic numbers)
3. **Are interactions discoverable?** (Affordances clear)
4. **Is it accessible?** (Keyboard, screen reader, contrast)
5. **Is it fast?** (No unnecessary re-renders, efficient CSS)
6. **Could it be simpler?** (Complexity earns its place)
7. **Is there a signature element?** (Something unmistakably this product)
8. **Does it look like AI slop?** (shadcn + Tailwind defaults + Lucide unmodified)

---

## Uniqueness Guidelines

### The "Remove the Logo" Test

If you removed the logo, would users still recognize this as your product? If not, find your signature.

### Restraint Plus One

```
1. Establish clean, consistent system (spacing, typography, grid)
2. Choose ONE defining signature element:
   - Signature color used with precision
   - Signature interaction (keyboard-first, specific gesture)
   - Signature animation style (bouncy, smooth, snappy)
   - Signature voice in copy
3. Make that ONE thing unmistakable
```

### Avoiding AI Slop

**If you see these together, it's AI-generated:**
- React + Tailwind + shadcn/ui + Lucide (unmodified)
- Inter or Geist font
- Purple/blue gradient
- Three-column icon features
- "Seamless" / "Transform" / "Cutting-edge" copy

**The fix:** Don't remove these tools--**customize them until they're unrecognizable**.

### Signature Interactions

```
DEFINITION: A microinteraction that:
1. Solves a problem or adds genuine delight
2. Delivers brand promise recognizably
3. Is consistent across time and touchpoints
4. Doesn't obstruct the user's goal
```

**Finding your signature:**
- Map every user interaction in the flow
- Identify which ONE moment deserves to be unmistakably yours
- Invest in making that moment perfect

### Voice in Copy

**Define four dimensions:**
1. Formal <-> Casual
2. Serious <-> Funny
3. Respectful <-> Irreverent
4. Matter-of-fact <-> Enthusiastic

**Apply consistently, adapt to context:**
- **Error states:** Reassuring, helpful, precise (not humorous)
- **Empty states:** Encouraging, warm
- **Success states:** Genuine celebration
- **Loading states:** Personality-appropriate

**Example empty states:**
- "No entries yet... but you're here. That's the first step."
- "You're all caught up. Enjoy the calm."

### Animation Personality

**Motion reflects brand:**
- **Tech/speed focus:** Snappy, 100-200ms, ease-out (Linear)
- **Premium/luxury:** Slow, graceful, 300-500ms (Apple)
- **Playful/fun:** Bouncy springs, 15-30% bounce

**Apple's spring parameters:**
- Bounce 0: Smooth, general-purpose
- Bounce ~15%: Brisk, not very bouncy
- Bounce ~30%: Noticeable bounciness, physical
- Bounce >40%: May feel exaggerated

---

## AI-Native Interface Patterns

When building AI-powered features:

### Layout Patterns

```
DON'T: Chat bubble in bottom-right corner (support chatbot pattern)
DO: Spatial layouts that separate conversation from artifact
   - Left panel for AI collaboration
   - Right panel for output/preview
   - Inline AI where user is working (Notion pattern)
```

### Streaming

```
ALWAYS stream AI responses (builds trust, reduces perceived latency)
SHOW partial results as they generate
USE for: conversational responses, code generation, long-form content
DON'T stream: structured data (JSON), factual lookups, background processing
```

### Confidence Visualization

```
Green: High confidence (standard, verified)
Yellow: Medium confidence (review suggested)
Red: Low confidence / unusual (flagged for human)

Hover to reveal reasoning ("Why AI is uncertain: Limited training data")
```

### Error Handling

```
SPECIFIC: Not "Something went wrong" but "I couldn't find recent data. Try rephrasing."
ACTIONABLE: What user should do next
RECOVERABLE: Easy undo, manual override options
```

---

*See `design-philosophy.md` for the broader aesthetic. This file is about implementation that achieves uniqueness.*
