# KERNEL Baseline System: Architecture Breakdown

## 1. CORE CONCEPT

KERNEL gives any coding project a lightweight "brain" that learns as you work. Instead of dumping a ton of rules upfront, it provides empty slots that fill in as the project evolves. Think of it like a new employee's notebook: starts mostly blank, fills with relevant notes over time, stays organized so nothing gets lost.

## 2. GLOSSARY

| Term | Plain English Definition |
|------|-------------------------|
| Bank | A reference doc with methodology (how to plan, debug, review). Loads only when needed. |
| Mode | A thinking style you activate. "/plan" means "think carefully before coding." |
| Slot | A placeholder in a bank designed to be filled. Has a max capacity to prevent bloat. |
| State | The current snapshot of what KERNEL knows about this project. |
| Hook | An automatic prompt that offers (not forces) an action after something happens. |
| Rules | Project-specific patterns that emerge over time. Starts empty. |
| Invariant | Something that must never change without explicit decision. |
| Preference | Something negotiable (formatting, defaults). |

## 3. THE FLOW

```
┌─────────────────────────────────────────────────────────────────┐
│                      You start working                          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CLAUDE.md loads (~150 tokens)                │
│                                                                  │
│  "Correctness > speed. Detect, then act. Protect state."        │
│                                                                  │
│  This is always present. Sets the tone.                         │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                   You activate a MODE                            │
│                                                                  │
│    /discover  "Map this codebase"                               │
│    /plan      "Think before building"                           │
│    /debug     "Systematically find the bug"                     │
│    /review    "Check for correctness"                           │
│                                                                  │
│  Mode loads its BANK + reads current STATE                      │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Work happens...                               │
│                                                                  │
│  KERNEL observes patterns. Hooks fire:                          │
│                                                                  │
│  "I noticed you prefer UTC timestamps. Save this? [y/n]"        │
│  "Formatter detected. Auto-format? [y/n]"                       │
│  "Tests exist. Run before completing? [y/n]"                    │
│                                                                  │
│  You confirm what gets saved. Nothing auto-writes.              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                   STATE and RULES evolve                         │
│                                                                  │
│  kernel/state.md: "This project uses pytest, black, mypy"       │
│  rules/preferences.md: "Dates display as 'Jan 15, 2026'"        │
│  rules/patterns.md: "Errors use Result<T, E> pattern"           │
│                                                                  │
│  Next session reads these. No repeated discovery.               │
└─────────────────────────────────────────────────────────────────┘
```

## 4. WHAT HAPPENS WHEN: New Project

1. Run `/kernel-init` on empty project
2. KERNEL creates file structure with empty templates
3. Run `/discover` to map the codebase
4. State populates: "Found: pytest, no formatter, src/ is entrypoint"
5. Run `/plan` for first feature
6. Planning bank loads, references state, guides thinking
7. After implementation, hook offers: "Save this pattern? [y/n]"
8. Confirmed patterns go to rules/
9. Next session: state + rules already populated, no re-discovery

## 5. WHAT HAPPENS WHEN: Returning to Project

1. Start working
2. CLAUDE.md loads (philosophy)
3. Activate any mode
4. Mode loads its bank + state.md
5. State says: "pytest exists, black configured, uses Result pattern"
6. You have full context without re-discovering anything
7. New discoveries still get offered for capture

## 6. COMPONENT BREAKDOWN

### kernel/state.md
- **Purpose**: Single source of truth about current project reality
- **Receives**: Updates from all modes and hooks
- **Produces**: Context for every mode activation
- **Cap**: ~200 tokens max

### Banks (Discovery, Planning, Debugging, Review)
- **Purpose**: Methodology templates with fillable slots
- **Receives**: Nothing (read-only reference)
- **Produces**: Thinking framework for current mode
- **Cap**: 500-800 tokens each, slots have individual caps

### Modes (/discover, /plan, /debug, /review)
- **Purpose**: Activate a thinking style
- **Receives**: User command
- **Produces**: Loads relevant bank + state
- **Cap**: ~30 tokens each (ultra-thin)

### Hooks (post-write, pattern-capture, pre-complete)
- **Purpose**: Offer helpful actions at key moments
- **Receives**: Events (file written, task completing, etc.)
- **Produces**: Prompts with [y/n] confirmation
- **Cap**: ~20 tokens each

### Rules Directory (preferences, invariants, patterns, decisions)
- **Purpose**: Store project-specific knowledge
- **Receives**: Confirmed captures from hooks
- **Produces**: Context for future sessions
- **Cap**: Starts empty, grows organically

## 7. TOKEN BUDGET VISUALIZATION

```
ALWAYS LOADED (~330 tokens)
├── CLAUDE.md ████████████████ 150
├── Mode metadata ████████ 120  
└── Hook definitions ████ 60

LOADED ON DEMAND (0 until needed)
├── Banks ░░░░░░░░░░░░░░░░ 500-800 each
├── State ░░░░░░░░ ~200
└── Rules ░░░░░░░░ varies

Compare to old approach:
████████████████████████████████████████████████ 6000+ tokens always
```

## 8. THE SLOT SYSTEM

Banks aren't walls of text. They're structured containers:

```
┌─────────────────────────────────────────┐
│           PLANNING BANK                  │
├─────────────────────────────────────────┤
│ Philosophy (fixed)                       │
│ "Correctness > speed..."                │
├─────────────────────────────────────────┤
│ Pre-implementation Checklist (max 8)    │
│ ☑ WHAT/WHY/DONE-WHEN                    │
│ ☑ List assumptions                      │
│ ☐ [empty slot]                          │
│ ☐ [empty slot]                          │
│ ...                                      │
├─────────────────────────────────────────┤
│ Stack Patterns (max 10)                  │
│ ☐ [fills as you use different stacks]   │
├─────────────────────────────────────────┤
│ Pitfalls Observed (max 10)              │
│ ☐ [fills as you hit issues]             │
└─────────────────────────────────────────┘
```

Caps prevent bloat. When full: replace least valuable OR promote to rules/.

## 9. QUESTIONS TO VERIFY UNDERSTANDING

Before building, can you answer:

1. What loads automatically vs on-demand?
2. Where does discovered information get saved?
3. What's the difference between a preference and an invariant?
4. Why do hooks "offer" instead of "auto-write"?
5. What triggers state.md to update?
6. How does a pattern in a bank slot eventually become a rule?