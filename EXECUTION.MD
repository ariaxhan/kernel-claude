# EXECUTION.MD — KERNEL Implementation Record

## PRE-FLIGHT CHECKLIST
- [x] Read VISION.MD
- [x] Fetched current Claude Code docs: settings, hooks, memory, slash-commands, sdk
- [x] Identified native alternatives (see critique below)
- [x] Mapped dependencies

---

## VISION CRITIQUE

### REINVENTING THE WHEEL — Remove these:

| VISION Concept | Native Alternative | Decision |
|----------------|-------------------|----------|
| `<kernel>` JSON block in output | Prompt-based Stop/SubagentStop hooks | **REMOVE** - Hooks already support LLM-based evaluation |
| `learnings.jsonl` storage | `.claude/rules/*.md` with path-specific rules | **REMOVE** - Native memory system is superior |
| `extract.py` parsing custom format | Hook JSON output with decision control | **SIMPLIFY** - Use native hook response schema |
| `test-queue.jsonl` | Direct subagent invocation via Skill tool | **REMOVE** - Over-engineered |
| `config-queue.jsonl`, `pattern-queue.jsonl` | Not needed; hooks handle this | **REMOVE** |
| Four optimization subagents | Single reflection mechanism | **CONSOLIDATE** |

### TRULY NOVEL — Preserve these:

1. **Self-reflection at session boundaries** — Stop hook prompts LLM to identify learnings
2. **Automatic config evolution** — Hook writes directly to `.claude/rules/`
3. **Test maintenance awareness** — Subagent can be invoked when implementation changes

### ARCHITECTURAL DECISION

DECISION: Use native prompt-based hooks instead of custom `<kernel>` format.
WHY: Claude Code's prompt-based hooks (Jan 2026) support LLM evaluation with structured JSON response. This is exactly what KERNEL's extraction mechanism does, but natively.
ALTERNATIVES CONSIDERED: Custom extraction script, SessionEnd hooks (no decision control)

---

## REFINED ARCHITECTURE

```
kernel/
├── .claude-plugin/
│   └── plugin.json           # Manifest
├── commands/
│   └── init.md               # /kernel:init - one-time setup
├── hooks/
│   └── hooks.json            # Stop hook for reflection
└── agents/
    └── test-maintainer.md    # Test generation/maintenance
```

**Total: 4 files** (vs VISION's 15+)

### HOW IT WORKS

1. `/kernel:init` → Adds KERNEL instruction to project CLAUDE.md
2. **Stop hook (prompt-based)** → LLM evaluates session, decides if rules should update
3. Hook writes to `.claude/rules/kernel-learnings.md` if warranted
4. Test-maintainer agent available via `use test-maintainer` when needed

### INTERFACES

| Component | Input | Output |
|-----------|-------|--------|
| init.md | Project files | Updated CLAUDE.md, enabled hooks |
| hooks.json | Stop event + transcript | JSON: `{decision, reason}` + file writes |
| test-maintainer.md | File paths, context | Generated/updated test files |

---

## IMPLEMENTATION PLAN

### Phase 1: Core (MVP)
- [x] 1.1 Create plugin.json manifest
- [x] 1.2 Create init.md command
- [x] 1.3 Create hooks.json with prompt-based Stop hook
- [x] 1.4 Create test-maintainer.md agent

### Phase 2: Validation
- [ ] 2.1 Test /kernel:init on this project
- [ ] 2.2 Verify Stop hook fires and evaluates
- [ ] 2.3 Test rule file creation
- [ ] 2.4 Test test-maintainer invocation

### KILL CRITERIA
If implementation requires:
- More than 5 files → Reconsider architecture
- Custom parsing scripts → Use native hooks instead
- Persistent queues → Rethink workflow

---

## EXECUTION LOG

### Phase 1.1: plugin.json — DONE
**Created**: `kernel/.claude-plugin/plugin.json`
**Content**: Minimal manifest with name "kernel", version 1.0.0
**Decision**: No homepage URL needed for local development

### Phase 1.2: init.md — DONE
**Created**: `kernel/commands/init.md`
**Key design choices**:
- Uses native file operations (Read, Write) via Claude
- Appends KERNEL instruction section to CLAUDE.md
- Creates `.claude/rules/kernel-learnings.md` for persistent learnings
- No external dependencies

### Phase 1.3: hooks.json — REVISED
**Created**: `kernel/hooks/hooks.json`
**CRITICAL LEARNING**: Prompt-based Stop hooks receive transcript_path, NOT transcript content. Haiku can't read files, so it can't evaluate the conversation.

**Revised approach**: SessionStart hook that echoes a reminder. This adds context that KERNEL is active. The actual reflection happens via CLAUDE.md instructions, not hooks.

**Why this is better**:
- Simpler (no complex hook logic)
- More reliable (Claude does the evaluation with full context)
- Aligned with "lean on Claude Code" principle

### Phase 1.4: test-maintainer.md — DONE
**Created**: `kernel/agents/test-maintainer.md`
**Tools**: Read, Write, Grep, Glob, Bash
**Model**: Sonnet (capable for test generation)
**Invocation**: Via Skill tool or explicit "use test-maintainer"

---

## LEARNINGS

### Critical discovery:
Prompt-based hooks receive hook INPUT (metadata like transcript_path), not transcript CONTENT. The LLM in the hook can't read files. This makes prompt-based Stop hooks unsuitable for session evaluation.

### Revised insight:
The simplest approach: put instructions in CLAUDE.md. Claude naturally follows these instructions with full conversation context. No hook complexity needed. The "reflection" happens organically as part of Claude's response.

### Anti-patterns avoided:
- Prompt-based hooks for file-based evaluation (can't read files)
- Custom JSON parsing (used native hook schema)
- Persistent queues (unnecessary complexity)
- Multiple specialized agents (one test-maintainer suffices)

### Architecture validation:
- 4 files total (vs VISION's 15+)
- Zero Python scripts for core functionality
- Uses only native Claude Code features
- SessionStart hook only for activation reminder (optional)

---

## MENTAL DRY-RUN (Final)

Simplified workflow:
1. User installs plugin, runs `/kernel:init` in project
2. init.md adds KERNEL section to CLAUDE.md + creates rules file
3. SessionStart hook echoes "KERNEL active" reminder (added to context)
4. User works normally with Claude
5. When user states explicit preferences, Claude recognizes them (via CLAUDE.md instructions)
6. Before completing task, Claude writes learnings to `.claude/rules/kernel-learnings.md`
7. Next session, Claude reads updated rules automatically (native behavior)

**Why this works:**
- Claude has full conversation context when deciding what to persist
- No hook limitations (file reading, timeouts, LLM calls)
- Natural integration with Claude's existing behavior
- Rules are just markdown files in native memory system

**Edge cases:**
- Claude forgets to persist: SessionStart reminder helps
- Duplicate rules: CLAUDE.md instructs to check existing file first
- Rule file gets large: User can clean up via /memory

---

## NEXT: Validation

To test:
1. Install plugin: `~/.claude/plugins/kernel/` or use local path
2. Enable plugin in settings
3. Run `/kernel:init` in a test project
4. Work with Claude, stating explicit preferences
5. End session, observe hook evaluation
6. Check `.claude/rules/kernel-learnings.md` for persisted rules

---

_Last updated: Phase 1 complete, ready for Phase 2 validation_
