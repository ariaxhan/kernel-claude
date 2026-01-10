# KERNEL: Complete Architecture Breakdown

```
●CONTEXT|type:analysis|for:aria|purpose:ensure_total_clarity
```

---

## 1. CORE CONCEPT (One Paragraph)

KERNEL solves the "amnesia problem" in Claude Code. Every session, Claude learns things about you: your preferences, project decisions, test patterns. When the session ends, that knowledge dies. KERNEL fixes this by making Claude output a structured `<kernel>` JSON block at the end of every response. A lightweight hook script parses that block and writes the learnings to persistent files. Next session, those files inform Claude. Your setup evolves automatically.

---

## 2. THE INFORMATION FLOW

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           KERNEL DATA FLOW                                  │
└─────────────────────────────────────────────────────────────────────────────┘

   YOU                    CLAUDE                   HOOK                 FILES
    │                       │                       │                     │
    │  "always use          │                       │                     │
    │   type hints"         │                       │                     │
    │──────────────────────▶│                       │                     │
    │                       │                       │                     │
    │                       │ (understands this     │                     │
    │                       │  is a preference)     │                     │
    │                       │                       │                     │
    │                       │ outputs response      │                     │
    │                       │ + <kernel> block      │                     │
    │◀──────────────────────│                       │                     │
    │                       │                       │                     │
    │                       │  Stop event fires     │                     │
    │                       │─────────────────────▶│                     │
    │                       │                       │                     │
    │                       │                       │ parse <kernel>      │
    │                       │                       │ deduplicate         │
    │                       │                       │ write to files      │
    │                       │                       │────────────────────▶│
    │                       │                       │                     │
    │                       │                       │    learnings.jsonl  │
    │                       │                       │    CLAUDE.md        │
    │                       │                       │    test-queue.jsonl │
    │                       │                       │                     │
   ───────────────────────────────────────────────────────────────────────────
                              NEXT SESSION
   ───────────────────────────────────────────────────────────────────────────
    │                       │                       │                     │
    │  "help me with X"     │                       │                     │
    │──────────────────────▶│                       │                     │
    │                       │                       │                     │
    │                       │ (reads CLAUDE.md,     │                     │
    │                       │  already knows your   │◀───────────────────│
    │                       │  preferences)         │                     │
    │                       │                       │                     │
    │                       │ response follows      │                     │
    │                       │ your preferences      │                     │
    │◀──────────────────────│                       │                     │
```

---

## 3. GLOSSARY OF EVERY TERM

### Core Concepts

| Term | Definition |
|------|------------|
| **KERNEL** | The plugin name. Metaphor: the core that everything else builds around. |
| **`<kernel>` block** | JSON structure Claude outputs at end of every response. Contains learnings, config updates, test work. |
| **Hook** | Claude Code feature: script that runs automatically on specific events (Stop, PreCompact). |
| **Stop event** | Fires when Claude finishes a response. |
| **PreCompact event** | Fires before Claude Code compresses context (when conversation gets long). |
| **Extraction** | Process of parsing the `<kernel>` block and saving its contents to files. |
| **Deduplication** | Hashing learnings to avoid storing the same thing twice. |

### File Types

| File | Purpose |
|------|---------|
| **CLAUDE.md** | Project-level instructions for Claude. KERNEL adds preferences here. |
| **learnings.jsonl** | Append-only log of everything Claude learned. One JSON per line. |
| **test-queue.jsonl** | Queue of test work (generation/maintenance) waiting to be processed. |
| **Commands** | Slash commands like `/kernel:init`. Defined in `.md` files. |
| **Skills** | Reusable knowledge packages. Domain-specific instructions. |
| **Subagents** | Specialized Claude instances for specific tasks (test-maintainer, config-optimizer). |
| **Hooks JSON** | Configuration file telling Claude Code when to run extraction script. |

### Learning Types

| Type | What It Captures | Example |
|------|------------------|---------|
| **preference** | How you like things done | "always use type hints" |
| **decision** | Project-level choices | "using SQLAlchemy for ORM" |
| **pattern** | Repeated workflows | "user runs tests after implementation" |
| **test_pattern** | How tests are structured | "use pytest fixtures, mock external APIs" |

### Actions

| Action | What It Does |
|--------|--------------|
| **append_claude_md** | Add a line to CLAUDE.md |
| **create_command** | Create a new slash command |
| **create_skill** | Create a new skill file |
| **create_hook** | Create a new automation hook |
| **add_mcp** | Suggest an MCP server integration |

---

## 4. THE `<kernel>` BLOCK STRUCTURE

```json
{
  "learnings": [
    // WHAT CLAUDE LEARNED THIS RESPONSE
    // Array of objects with type + value
    {"type": "preference", "value": "user prefers functional style"},
    {"type": "decision", "value": "project uses PostgreSQL"},
    {"type": "test_pattern", "value": "tests use pytest fixtures"}
  ],
  
  "config_update": {
    // SHOULD A CONFIG FILE CHANGE?
    // null if nothing should change (most responses)
    // OR an object with:
    "action": "append_claude_md",     // what to do
    "target": "CLAUDE.md",            // where
    "content": "- Use type hints",    // what to add
    "reason": "user stated explicitly" // why
  },
  
  "test_generation": {
    // DOES NEW CODE NEED TESTS?
    // null if no tests needed
    // OR:
    "trigger": "new_code",                    // why tests needed
    "target_file": "src/user_service.py",     // the code
    "test_file": "tests/test_user_service.py", // where tests go
    "scope": "unit",                          // unit/integration/e2e
    "reason": "new UserService class"         // explanation
  },
  
  "test_maintenance": {
    // DO EXISTING TESTS NEED UPDATES?
    // null if tests are fine
    // OR:
    "action": "update",                   // update/regenerate/fix
    "test_file": "tests/test_auth.py",    // which tests
    "target_file": "src/auth.py",         // what changed
    "reason": "login() signature changed" // why update
  },
  
  "optimization_trigger": null
  // OPTIONAL: only if maintenance needed
  // e.g., config_bloat, duplicate_patterns
}
```

---

## 5. COMMAND BREAKDOWN

### `/kernel:init` — First-Time Setup

```
┌─────────────────────────────────────────────────────────────┐
│                     /kernel:init FLOW                       │
└─────────────────────────────────────────────────────────────┘

     START
       │
       ▼
  ┌─────────────────┐
  │ Read project    │  package.json, pyproject.toml,
  │ files           │  README, existing .claude/
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Detect stack    │  Python? Node? What frameworks?
  │ & test framework│  pytest? jest? unittest?
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Create/update   │  Add project summary
  │ CLAUDE.md       │  Add KERNEL instruction block
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Suggest MCP     │  Detected GitHub imports? → suggest github MCP
  │ servers         │  Detected Slack? → suggest slack MCP
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Create starter  │  Found npm scripts? → create commands
  │ commands        │  Found Makefile? → create commands
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Enable hooks    │  Update settings.local.json
  │                 │  Extraction now runs on Stop/PreCompact
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Report          │  Tell user what was created
  └─────────────────┘
           │
           ▼
       END (KERNEL is now active)
```

### `/kernel:activate` — Turn On

```
  ┌─────────────────┐
  │ Ensure KERNEL   │
  │ instruction in  │──▶ Add if missing
  │ CLAUDE.md       │
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Enable hooks    │──▶ extraction runs on Stop/PreCompact
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Confirm         │──▶ "KERNEL activated"
  └─────────────────┘
```

### `/kernel:deactivate` — Turn Off

```
  ┌─────────────────┐
  │ Disable hooks   │──▶ extraction stops running
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Keep CLAUDE.md  │──▶ instruction stays (easy reactivation)
  │ instruction     │
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Confirm         │──▶ "KERNEL deactivated"
  └─────────────────┘
```

---

## 6. EXTRACTION HOOK FLOW

This is what happens every time Claude finishes responding:

```
┌─────────────────────────────────────────────────────────────┐
│                   EXTRACTION SCRIPT FLOW                    │
│                     (scripts/extract.py)                    │
└─────────────────────────────────────────────────────────────┘

  Stop/PreCompact event fires
           │
           ▼
  ┌─────────────────┐
  │ Receive hook    │  stdin: {"transcript_path": "..."}
  │ JSON input      │
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐     ┌─────────────────┐
  │ Read transcript │────▶│ No <kernel>?    │──▶ EXIT 0 (silent)
  │ Find <kernel>   │     │                 │
  └────────┬────────┘     └─────────────────┘
           │ found
           ▼
  ┌─────────────────┐
  │ Parse JSON      │──▶ Handle malformed gracefully
  └────────┬────────┘
           │
           ▼
  ┌─────────────────────────────────────────┐
  │            PROCESS LEARNINGS            │
  │                                         │
  │  for each learning:                     │
  │    1. compute hash                      │
  │    2. check learnings.jsonl for hash    │
  │    3. if new → append to file           │
  │    4. if duplicate → skip               │
  └────────┬────────────────────────────────┘
           │
           ▼
  ┌─────────────────────────────────────────┐
  │           PROCESS CONFIG_UPDATE         │
  │                                         │
  │  if config_update is not null:          │
  │    1. check if content already exists   │
  │    2. if duplicate → skip               │
  │    3. if new → create/append file       │
  └────────┬────────────────────────────────┘
           │
           ▼
  ┌─────────────────────────────────────────┐
  │         QUEUE TEST WORK                 │
  │                                         │
  │  if test_generation is not null:        │
  │    → append to test-queue.jsonl         │
  │                                         │
  │  if test_maintenance is not null:       │
  │    → append to test-queue.jsonl         │
  └────────┬────────────────────────────────┘
           │
           ▼
  ┌─────────────────────────────────────────┐
  │         OPTIONAL: QUEUE OPTIMIZATION    │
  │                                         │
  │  if optimization_trigger is not null:   │
  │    → append to config-queue.jsonl       │
  │      or pattern-queue.jsonl             │
  └────────┬────────────────────────────────┘
           │
           ▼
  ┌─────────────────┐
  │ EXIT 0          │  Must be < 10ms total
  └─────────────────┘
```

---

## 7. TEST AUTOMATION FLOW

```
┌─────────────────────────────────────────────────────────────┐
│                   TEST AUTOMATION FLOW                      │
└─────────────────────────────────────────────────────────────┘

   DURING MAIN CONVERSATION
   ─────────────────────────

  You create new code
           │
           ▼
  ┌─────────────────┐
  │ Claude outputs  │  Includes test_generation in <kernel>
  │ response        │
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Hook extracts   │  Appends to test-queue.jsonl
  │ and queues      │  (does NOT generate tests yet)
  └─────────────────┘


   LATER (WHEN TEST-MAINTAINER RUNS)
   ──────────────────────────────────

  ┌─────────────────┐
  │ test-maintainer │  Subagent (sonnet model)
  │ subagent        │
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Read            │  What patterns did KERNEL learn?
  │ learnings.jsonl │  (test_pattern entries)
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ Read            │  What tests need to be generated?
  │ test-queue.jsonl│
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ For each queued │
  │ task:           │
  │                 │
  │ 1. Read target  │  (the implementation file)
  │    file         │
  │                 │
  │ 2. Apply        │  (fixtures, mocking, naming)
  │    patterns     │
  │                 │
  │ 3. Generate     │  (write actual test code)
  │    tests        │
  │                 │
  │ 4. Mark task    │  (_processed: true)
  │    complete     │
  └─────────────────┘
```

---

## 8. PLUGIN FILE STRUCTURE

```
kernel/
│
├── .claude-plugin/
│   └── plugin.json              ← Manifest (name, version, description)
│
├── commands/                    ← Slash commands
│   ├── init.md                  ← /kernel:init
│   ├── activate.md              ← /kernel:activate
│   ├── deactivate.md            ← /kernel:deactivate
│   └── review.md                ← /kernel:review (optional)
│
├── agents/                      ← Subagents
│   ├── test-maintainer.md       ← Core: generates/maintains tests
│   ├── config-optimizer.md      ← Optional: cleans config
│   ├── pattern-analyzer.md      ← Optional: finds meta-patterns
│   └── skill-builder.md         ← Optional: extracts skills
│
├── hooks/
│   └── hooks.json               ← When to run extraction
│
├── scripts/
│   └── extract.py               ← The extraction logic
│
├── memory/                      ← Runtime data (created during use)
│   ├── .gitkeep
│   ├── learnings.jsonl          ← All learnings (append-only)
│   ├── test-queue.jsonl         ← Pending test work
│   ├── config-queue.jsonl       ← Optional: pending config optimization
│   └── pattern-queue.jsonl      ← Optional: pending pattern analysis
│
└── README.md                    ← User documentation
```

---

## 9. THRESHOLDS & RULES

### When Does KERNEL Suggest Config Changes?

```
┌─────────────────────────────────────────────────────────────┐
│            THRESHOLD DECISION TREE                          │
└─────────────────────────────────────────────────────────────┘

  User says something
           │
           ▼
  ┌─────────────────────────────────────┐
  │ Is it EXPLICIT?                     │
  │ "always use type hints"             │
  │ "never use semicolons"              │
  └────────┬───────────────┬────────────┘
           │ YES           │ NO
           ▼               ▼
     ┌──────────┐    ┌─────────────────────────────┐
     │ config   │    │ Has this pattern appeared   │
     │ update   │    │ 3+ times?                   │
     └──────────┘    └────────┬───────────┬────────┘
                              │ YES       │ NO
                              ▼           ▼
                        ┌──────────┐  ┌──────────┐
                        │ config   │  │ learning │
                        │ update   │  │ only     │
                        └──────────┘  │ (no      │
                                      │ config)  │
                                      └──────────┘
```

### What NOT to Do

| DON'T | WHY |
|-------|-----|
| Repeat learnings from earlier in conversation | Claude can see prior `<kernel>` blocks |
| Suggest config for one-off requests | Noise; wastes space |
| Create commands for simple requests | "run tests" doesn't need a command |
| Bloat CLAUDE.md with README content | Already available in project |
| Create skills for built-in knowledge | Redundant |
| Generate tests for trivial code | Getters, simple pass-throughs |
| Overwrite passing tests | Dangerous; confirm first |

---

## 10. CORE vs OPTIONAL FEATURES

```
┌─────────────────────────────────────────────────────────────┐
│                      FEATURE TIERS                          │
└─────────────────────────────────────────────────────────────┘

  CORE (Always Active, Required for KERNEL to Work)
  ─────────────────────────────────────────────────
  
  • Learning capture        ← preferences, decisions, patterns
  • Config evolution        ← CLAUDE.md updates, command creation
  • Test generation         ← queue and generate tests for new code
  • Test maintenance        ← update tests when code changes
  • /kernel:init            ← setup
  • /kernel:activate        ← turn on
  • /kernel:deactivate      ← turn off
  
  
  OPTIONAL (User-Activated Enhancements)
  ─────────────────────────────────────────────────
  
  • config-optimizer        ← clean up bloated config
  • pattern-analyzer        ← discover meta-patterns
  • skill-builder           ← extract skills from workflows
  • /kernel:review          ← see health, get suggestions
  • optimization_trigger    ← optional field in <kernel>
  
  
  ┌─────────────────────────────────────────────────────────┐
  │ KERNEL WORKS PERFECTLY WITH JUST CORE FEATURES.        │
  │ Optional features are maintenance/enhancement add-ons. │
  └─────────────────────────────────────────────────────────┘
```

---

## 11. TOKEN OPTIMIZATION STRATEGY

```
┌─────────────────────────────────────────────────────────────┐
│                TOKEN OPTIMIZATION                           │
└─────────────────────────────────────────────────────────────┘

  PROBLEM: Claude sessions use tokens. More tokens = slower + expensive.
  
  SOLUTION: KERNEL minimizes token usage through:
  
  
  1. CONTEXT SEPARATION
     ────────────────────
     
     Main conversation:        Subagent context:
     ┌──────────────────┐     ┌──────────────────┐
     │ High-level       │     │ Test generation  │
     │ strategy         │     │ only             │
     │                  │     │                  │
     │ Your messages    │     │ Reads patterns   │
     │ Claude's replies │     │ from files       │
     │ <kernel> blocks  │     │                  │
     └──────────────────┘     └──────────────────┘
     
     Test code generation happens in subagent's separate context.
     Main conversation stays focused.
  
  
  2. STORE ONCE, REFERENCE FOREVER
     ─────────────────────────────
     
     Learning: "use pytest fixtures"
         │
         ▼ stored once in learnings.jsonl
         │
         ▼ hashed: "a1b2c3d4"
         │
         ▼ never repeated; checked by hash
  
  
  3. LAZY EXECUTION
     ─────────────────
     
     Extraction hook: < 10ms (just file appends)
     Test work: queued, not executed synchronously
     Subagent: invoked only when needed
  
  
  4. MINIMAL BLOCKS
     ─────────────────
     
     <kernel> blocks are concise JSON.
     No verbose explanations.
     Empty arrays when nothing learned.
```

---

## 12. WHAT HAPPENS IN A TYPICAL SESSION

```
┌─────────────────────────────────────────────────────────────┐
│                 TYPICAL SESSION TIMELINE                    │
└─────────────────────────────────────────────────────────────┘

  SESSION START
       │
       ▼
  ┌─────────────────────────────────────────────────────────┐
  │ Claude reads CLAUDE.md                                  │
  │ → Sees KERNEL instruction                               │
  │ → Sees prior preferences: "use type hints"              │
  │ → Sees project context: "using SQLAlchemy"              │
  └─────────────────────────────────────────────────────────┘
       │
       ▼
  You: "Create a User model"
       │
       ▼
  ┌─────────────────────────────────────────────────────────┐
  │ Claude responds:                                        │
  │                                                         │
  │ Here's a User model with type hints...                  │
  │                                                         │
  │ <kernel>                                                │
  │ {                                                       │
  │   "learnings": [                                        │
  │     {"type": "decision", "value": "User model has       │
  │      email and name fields"}                            │
  │   ],                                                    │
  │   "config_update": null,                                │
  │   "test_generation": {                                  │
  │     "trigger": "new_code",                              │
  │     "target_file": "models/user.py",                    │
  │     "test_file": "tests/test_user.py",                  │
  │     "scope": "unit",                                    │
  │     "reason": "new User model"                          │
  │   },                                                    │
  │   "test_maintenance": null                              │
  │ }                                                       │
  │ </kernel>                                               │
  └─────────────────────────────────────────────────────────┘
       │
       ▼
  ┌─────────────────────────────────────────────────────────┐
  │ HOOK FIRES (Stop event)                                 │
  │                                                         │
  │ extract.py runs:                                        │
  │ → Parses <kernel>                                       │
  │ → Appends learning to learnings.jsonl                   │
  │ → Appends test task to test-queue.jsonl                 │
  │ → Exits in < 10ms                                       │
  └─────────────────────────────────────────────────────────┘
       │
       ▼
  You: "Actually, I always want models to have timestamps"
       │
       ▼
  ┌─────────────────────────────────────────────────────────┐
  │ Claude responds:                                        │
  │                                                         │
  │ Updated User model with created_at and updated_at...    │
  │                                                         │
  │ <kernel>                                                │
  │ {                                                       │
  │   "learnings": [                                        │
  │     {"type": "preference", "value": "models should      │
  │      have timestamp fields"}                            │
  │   ],                                                    │
  │   "config_update": {                                    │
  │     "action": "append_claude_md",                       │
  │     "target": "CLAUDE.md",                              │
  │     "content": "- Models include created_at/updated_at",│
  │     "reason": "user stated explicitly 'always'"         │
  │   },                                                    │
  │   "test_generation": null,                              │
  │   "test_maintenance": {                                 │
  │     "action": "update",                                 │
  │     "test_file": "tests/test_user.py",                  │
  │     "target_file": "models/user.py",                    │
  │     "reason": "User model now has timestamp fields"     │
  │   }                                                     │
  │ }                                                       │
  │ </kernel>                                               │
  └─────────────────────────────────────────────────────────┘
       │
       ▼
  ┌─────────────────────────────────────────────────────────┐
  │ HOOK FIRES (Stop event)                                 │
  │                                                         │
  │ extract.py runs:                                        │
  │ → Appends preference to learnings.jsonl                 │
  │ → Updates CLAUDE.md with timestamp preference           │
  │ → Queues test maintenance task                          │
  └─────────────────────────────────────────────────────────┘
       │
       ▼
  SESSION ENDS
       │
       ▼
  NEXT SESSION: Claude already knows "models have timestamps"
```

---

## 13. SUCCESS CRITERIA CHECKLIST

```
CORE FUNCTIONALITY (Must Work)
──────────────────────────────
□ /kernel:init sets up project correctly
□ Claude outputs <kernel> blocks at end of responses
□ Extraction hook captures learnings without errors
□ Deduplication prevents repeated learnings
□ Config updates are applied to files
□ Test generation queues work to test-queue.jsonl
□ test-maintainer subagent processes queue
□ /kernel:activate and /kernel:deactivate work instantly
□ User can view learnings.jsonl to see what KERNEL learned
□ Extraction runs in < 10ms (no perceptible latency)

OPTIONAL ENHANCEMENTS (Nice to Have)
─────────────────────────────────────
□ /kernel:review shows KERNEL health
□ config-optimizer cleans bloated config
□ pattern-analyzer discovers meta-patterns
□ skill-builder extracts skills from workflows
```

---

## 14. QUESTIONS TO ASK YOURSELF

Before proceeding, ensure you can answer:

1. **What triggers extraction?**
   → Stop and PreCompact events

2. **Where do learnings go?**
   → memory/learnings.jsonl (append-only)

3. **When does KERNEL suggest a config change?**
   → Explicit user statement OR pattern repeated 3+ times

4. **What's the difference between learning and config_update?**
   → Learning = knowledge stored for reference
   → Config_update = actual file modification

5. **How are tests generated?**
   → Queued in test-queue.jsonl; subagent processes later

6. **Why are optional features optional?**
   → KERNEL works without them; they're maintenance add-ons

7. **What prevents bloat?**
   → Deduplication, thresholds, one update per response

8. **What's the subagent's role?**
   → Separate context for tactical work (tests); main stays strategic

---

●LOG :: Δ comprehensive breakdown created covering all architecture elements; flowcharts for init, extraction, test automation, session timeline | → confirm understanding then proceed to Phase 1 build