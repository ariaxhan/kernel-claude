---
description: Activate design mode - load philosophy, audit UI, build with intention
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Design Mode

Activated when building or reviewing frontend/UI work.

## Startup

1. Read `.claude/rules/frontend-conventions.md` (implementation patterns + aesthetic)
2. Read `kernel/banks/BUILD-BANK.md` (methodology reference)
3. If available, read `${CLAUDE_PLUGIN_ROOT}/kernel/banks/BUILD-BANK.md` (plugin source)

## Context Gathering

Before any UI work:

```
□ What framework/stack is this project using?
□ What styling solution exists?
□ What design tokens/variables are defined?
□ What's the existing visual language?
```

If new project:
- Establish minimal token set (colors, spacing, typography)
- Document in project-appropriate location

## Modes

### `/design audit`

Scan existing frontend code for anti-patterns:

```
CHECK:
- Inter font usage
- Emoji in UI
- Excessive border-radius
- Shadow stacking
- Gradient abuse
- Color palette sprawl
- Skeleton loader overuse
- Toast notification abuse
```

Report findings with file locations and fix suggestions.

### `/design build <feature>`

Full design workflow:

1. **Understand** - What does this feature do? Who uses it?
2. **Structure** - Information hierarchy, layout, states
3. **Implement** - HTML → Layout → Typography → Color → Interaction
4. **Refine** - Remove cruft, simplify, test

Output working UI with accessibility and performance checks.

### `/design review`

Review existing UI against philosophy:

```
CHECKLIST:
□ Function dictates form (tailored to this project)
□ Seamless over impressive (just works)
□ Sophistication is restraint (advanced but tasteful)
□ No anti-patterns detected
□ Accessibility minimums met
□ Performance acceptable
```

Provide specific feedback with rationale.

### `/design tokens`

Generate or audit design tokens:

```
COLORS:
- --background, --surface, --text
- --primary, --secondary
- --success, --error, --warning

SPACING:
- --space-1 through --space-8

TYPOGRAPHY:
- --font-sans, --font-mono
- --text-xs through --text-xl

EFFECTS:
- --shadow-sm, --shadow-md
- --radius-sm, --radius-md
```

## Agent Spawning

For complex frontend work, spawn:

| Task | Agent | Model |
|------|-------|-------|
| Style audit | frontend-stylist | sonnet |
| Component build | frontend-stylist | sonnet |
| Accessibility review | frontend-stylist | sonnet |
| Performance check | perf-profiler | haiku |

## Anti-Pattern Enforcement

When generating ANY frontend code, automatically check:

```
REJECT IF:
- font-family contains "Inter"
- Emoji characters in UI strings
- rounded-full on containers
- shadow-lg + shadow-xl combined
- More than 5 distinct colors
- Skeleton loaders for <500ms operations
```

Suggest alternatives that align with philosophy.

## Output

```
## DESIGN: {feature/audit name}

Context:
- Framework: {detected}
- Styling: {detected}
- Tokens: {status}

Work Completed:
- {description}

Anti-Patterns:
- Found: {count}
- Fixed: {count}
- Remaining: {list with rationale}

Accessibility:
- Contrast: {status}
- Keyboard: {status}
- Screen reader: {status}

Files:
- {file}: {change summary}

Recommendations:
- {future improvements}
```

---

*Design is how it works, not how it looks.*
