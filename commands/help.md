<command id="kernel:help">
<description>Get help with KERNEL. Shows what you can do in simple terms.</description>

<output>
# KERNEL Help

**KERNEL helps you build software by remembering what works.** It tracks your progress, learns from mistakes, and keeps everything organized.

---

## Getting Started

| What you want | What to type |
|---------------|--------------|
| Set up a new project | `/kernel:init` |
| Start working on something | Just describe what you want (runs /ingest: classify → tier → route) |
| Save your progress | `/kernel:handoff` |

---

## Common Tasks

### "I want to build something new"
Just describe what you want. For example:
- "Add a login button"
- "Create a page that shows user profiles"
- "Make the app faster"

KERNEL will figure out the best approach and guide you through it.

### "Something is broken"
Describe what's wrong:
- "The login doesn't work"
- "I'm getting an error when I click save"
- "The page loads slowly"

KERNEL will help find and fix the problem.

### "I need to stop for now"
Type `/kernel:handoff` before closing. This saves everything so you can pick up exactly where you left off.

---

## Commands

| Command | What it does |
|---------|--------------|
| `/kernel:ingest` | Universal entry—classify task, count files, route (direct/surgeon/adversary) |
| `/kernel:init` | Set up _meta/ structure and memory for a new project |
| `/kernel:handoff` | Save progress before stopping |
| `/kernel:help` | Show this help |

---

## Tips

- **Be specific**: "Add a red button to the header" works better than "make it look better"
- **One thing at a time**: Focus on one task before moving to the next
- **Save often**: Use handoff before long breaks

---

*Need more help? Just ask.*
</output>

</command>
