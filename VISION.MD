# KERNEL — Self-Evolving Configuration for Claude Code

```
●CONTEXT|type:seed_document|for:claude_code|purpose:build_plugin
```

---

## WHAT IS KERNEL

KERNEL is a Claude Code plugin that makes your setup evolve automatically based on how you actually work.

**One sentence**: Claude reflects on each session, surfaces what it learned, updates your configuration, generates and maintains test cases, so you never repeat yourself.

---

## THE PROBLEM

You're a power user. Your requests are detailed (10+ sentences). Claude Code runs for minutes, figuring things out. By the end, Claude *knows* things:

- Your preferences ("always use type hints")
- Project decisions ("we're using SQLAlchemy")
- Workflow patterns (you always want tests after implementation)
- Test patterns (how you structure tests, what you test, coverage expectations)
- Maintenance needs (which tests need updates when code changes)

Then the session ends. That knowledge dies. Next session, you explain it all again. Tests drift out of sync. Test patterns aren't consistent.

Claude Code has powerful features (CLAUDE.md, commands, skills, subagents, hooks, MCP servers) that could preserve this knowledge. But you don't want to manually configure them. You want Claude to do it.

---

## THE SOLUTION

KERNEL embeds self-reflection directly into Claude's output.

At the end of every response, Claude outputs a `<kernel>` block containing:
- What it learned (preferences, decisions, patterns, test strategies)
- Suggested config updates (when patterns are strong enough)
- Test generation triggers (when new code needs tests)
- Maintenance actions (when existing tests need updates)

A lightweight hook parses these blocks and:
- Applies config changes automatically
- Records test work in a queue
- A specialized subagent processes the queue in its own context

**The main model does the thinking. The hook just extracts and queues. The subagent executes.**

**Token optimization**: Main conversation stays focused on high-level strategy. Test generation happens in subagent's separate context. Learned patterns are stored once and referenced, never repeated. Total token usage is minimized through context separation and lazy execution.

---

## HOW IT WORKS

### 1. `/kernel:init`

Run once per project. This command:

1. Analyzes your project (files, dependencies, structure)
2. Generates initial CLAUDE.md with project context
3. Adds the KERNEL instruction block (teaches Claude to output `<kernel>`)
4. Suggests relevant MCP servers based on detected APIs/services
5. Creates any obvious starter commands based on package.json scripts, Makefile, etc.
6. Detects existing test frameworks and patterns
7. Enables the extraction hooks and test maintenance hooks

After init, KERNEL is active. Learning happens automatically. Test generation and maintenance run continuously.

### 2. `/kernel:activate` and `/kernel:deactivate`

Toggle KERNEL on/off without removing it.

- **Activate**: Enables hooks, Claude outputs `<kernel>` blocks
- **Deactivate**: Disables hooks, normal Claude behavior

### 3. The `<kernel>` block

Claude outputs this at the end of every response:

```
<kernel>
{
  "learnings": [
    {"type": "preference", "value": "..."},
    {"type": "decision", "value": "..."},
    {"type": "pattern", "value": "..."},
    {"type": "test_pattern", "value": "..."}
  ],
  "config_update": {
    "action": "append_claude_md | create_command | create_skill | create_hook | add_mcp",
    "target": "filename or section",
    "content": "minimal content to add",
    "reason": "why this should persist"
  },
  "test_generation": {
    "trigger": "new_code | refactor | missing_coverage",
    "target_file": "path/to/implementation.py",
    "test_file": "path/to/test_implementation.py",
    "scope": "unit | integration | e2e",
    "reason": "why tests are needed"
  },
  "test_maintenance": {
    "action": "update | regenerate | fix",
    "test_file": "path/to/test_file.py",
    "target_file": "path/to/implementation.py",
    "reason": "implementation changed, test outdated"
  },
  "optimization_trigger": null  // OPTIONAL: only include when optimization needed
}
}
</kernel>
```

**Core fields** (always present):
- `learnings`: Core learning mechanism
- `config_update`: Core configuration evolution
- `test_generation`: Core test automation
- `test_maintenance`: Core test maintenance

**Optional field**:
- `optimization_trigger`: Enhancement feature for maintenance/cleanup

The block stays visible in conversation. This helps Claude:
- See what it already learned (no repeats)
- Stay consistent across responses
- Build on previous insights

### 4. The extraction hook

Fires on `Stop` and `PreCompact` events. Core functionality (always runs):

1. **Parse**: Find the last `<kernel>` block in output
2. **Deduplicate**: Hash learnings, skip if already recorded
3. **Apply**: If `config_update` is present, create/update the config file
4. **Queue test work**: If `test_generation` or `test_maintenance` is present, append to `memory/test-queue.jsonl`

Optional functionality (only if `optimization_trigger` present in block):

5. **Queue optimization**: If `optimization_trigger` is present, append to `memory/config-queue.jsonl` or `memory/pattern-queue.jsonl`

**How it works**: The extraction script is extremely lightweight—just JSON parsing and file appends. Core functionality (learning + config + test queueing) works independently. Optimization features are optional add-ons that enhance KERNEL but aren't required for basic operation.

---

## WHAT GETS CONFIGURED

KERNEL can create or update any Claude Code configuration:

| Config Type | When Created | Example |
|-------------|--------------|---------|
| **CLAUDE.md** | Explicit preferences, project decisions | "Always use type hints" |
| **Commands** | Workflow repeated 3+ times | `/test-this` after implementation |
| **Skills** | Domain knowledge worth preserving | API patterns, coding standards |
| **Subagents** | Specialized tasks you delegate repeatedly | Research agent, review agent |
| **Hooks** | Automation you'd want every time | Format on save, lint on edit |
| **MCP Servers** | External APIs used repeatedly | GitHub, database, Slack |
| **Test Files** | New code added, missing coverage | `test_user_service.py` for `user_service.py` |
| **Test Patterns** | Test structure repeated 3+ times | "Always use fixtures for DB setup" |
| **Test Maintenance** | Code changes detected | Update tests when API signature changes |

---

## LEAN BY DESIGN

KERNEL aggressively avoids bloat:

### Deduplication
- Learnings are hashed; duplicates are ignored
- Config is checked before adding; no redundant entries
- Claude is instructed to check prior `<kernel>` blocks before repeating

### Thresholds
- Config suggestions require strong signals:
  - Explicit user statement ("always do X")
  - Pattern repeated 3+ times
  - Decision with project-wide impact
- One-off requests don't generate config

### Minimal content
- CLAUDE.md entries are one-liners, not paragraphs
- Commands are short and focused
- Skills are created rarely, only for reusable domain knowledge

### One update per response
- `config_update` is singular, not an array
- Forces prioritization; only the most important change
- Prevents config explosion from a single session

---

## THE KERNEL INSTRUCTION

This is added to CLAUDE.md by `/kernel:init`:

```markdown
## KERNEL: Self-Evolving Configuration

End EVERY response with a <kernel> block:

<kernel>
{
  "learnings": [],
  "config_update": null
}
</kernel>

### Learnings

Add genuinely NEW insights only:
- `{"type": "preference", "value": "user prefers X"}`
- `{"type": "decision", "value": "project uses Y"}`
- `{"type": "pattern", "value": "user always does Z after W"}`
- `{"type": "test_pattern", "value": "tests use pytest fixtures, mock external APIs"}`

Rules:
- Check prior <kernel> blocks in this conversation; never repeat
- Empty array is correct for most responses
- Only include insights worth remembering across sessions
- Test patterns capture how tests are structured, not individual test cases

### Config Update

Suggest configuration when patterns are STRONG:
- User explicitly states a preference
- Same workflow appears 3+ times
- Decision affects the entire project

Structure:
```json
{
  "action": "append_claude_md | create_command | create_skill | create_hook | add_mcp",
  "target": "filename or identifier",
  "content": "minimal, precise content",
  "reason": "why this should persist"
}
```

### Test Generation

When new code is added or coverage is missing, signal that tests are needed:
```json
{
  "trigger": "new_code | refactor | missing_coverage",
  "target_file": "path/to/implementation.py",
  "test_file": "path/to/test_implementation.py",
  "scope": "unit | integration | e2e",
  "reason": "why tests are needed"
}
```

Rules:
- Only include metadata (no test code in the block)
- Extraction script will queue a subagent task to generate the actual tests
- Subagent uses learned test patterns from `memory/learnings.jsonl`
- Only generate if test file doesn't exist or is significantly outdated

### Test Maintenance

When code changes affect existing tests, signal that maintenance is needed:
```json
{
  "action": "update | regenerate | fix",
  "test_file": "path/to/test_file.py",
  "target_file": "path/to/implementation.py",
  "reason": "implementation changed, test outdated"
}
```

Rules:
- Only include metadata (no test code in the block)
- Extraction script will queue a subagent task to update the tests
- Subagent reads both files, detects changes, and updates tests accordingly
- Preserve test intent while fixing broken assertions

### Optimization Triggers

When patterns emerge or config grows, signal optimization opportunities:
```json
{
  "type": "config_bloat | duplicate_patterns | skill_opportunity",
  "reason": "50+ learnings accumulated, patterns repeating",
  "suggested_agent": "config-optimizer | pattern-analyzer | skill-builder"
}
```

Rules:
- Only include when clear signal exists (thresholds met)
- Extraction script queues optimization work
- User can invoke suggested agent explicitly or let Claude decide
- Optimization work happens in separate context

### Config Update Rules

- ONE update per response maximum (or null)
- Check existing config first; update rather than duplicate
- Keep content minimal; one line for CLAUDE.md
- When uncertain, output null; lean beats complete
- Never suggest config for one-off requests

### What NOT to do
- Repeat learnings from earlier in this conversation
- Suggest config for single-use workflows
- Create commands for simple, easy-to-type requests
- Bloat CLAUDE.md with project info already in README
- Create skills for knowledge Claude already has
- Generate tests for trivial code (getters, setters, simple pass-throughs)
- Overwrite existing tests without checking if they still pass
- Generate tests when user explicitly says "no tests needed"

### Optional: Optimization triggers

**Not required for core functionality.** Only include `optimization_trigger` when you detect opportunities for improvement:

```json
{
  "type": "config_bloat | duplicate_patterns | skill_opportunity",
  "reason": "clear signal for optimization",
  "suggested_agent": "config-optimizer | pattern-analyzer | skill-builder"
}
```

Rules:
- Completely optional; KERNEL works without this
- Only suggest when clear benefit exists
- User can ignore suggestions; nothing breaks
- These are maintenance/enhancement features, not core operations
```

---

## PLUGIN STRUCTURE

```
kernel/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
│
├── CORE FUNCTIONALITY (Required)
│   ├── commands/
│   │   ├── init.md              # /kernel:init - setup project
│   │   ├── activate.md          # /kernel:activate - enable learning
│   │   └── deactivate.md        # /kernel:deactivate - disable learning
│   ├── agents/
│   │   └── test-maintainer.md   # Test generation/maintenance
│   ├── hooks/
│   │   └── hooks.json           # Stop + PreCompact extraction
│   ├── scripts/
│   │   └── extract.py           # Parse <kernel>, dedup, apply config
│   └── memory/
│       ├── .gitkeep             # learnings.jsonl created at runtime
│       └── test-queue.jsonl     # Queued test tasks
│
├── OPTIONAL ENHANCEMENTS (Add-ons)
│   ├── commands/
│   │   └── review.md            # /kernel:review - review all learnings
│   ├── agents/
│   │   ├── config-optimizer.md  # Config cleanup and optimization
│   │   ├── pattern-analyzer.md  # Deep pattern discovery
│   │   └── skill-builder.md     # Skill creation from workflows
│   └── memory/
│       ├── config-queue.jsonl   # Queued config optimizations
│       └── pattern-queue.jsonl  # Queued pattern analysis
│
└── README.md                    # User documentation
```

---

## IMPLEMENTATION NOTES

### plugin.json

Standard manifest. Name: `kernel`. Description emphasizing automatic configuration evolution.

### commands/init.md

Slash command that:
1. Reads project structure (package.json, pyproject.toml, README, etc.)
2. Creates `.claude/CLAUDE.md` with:
   - Project summary (brief, from existing docs)
   - Tech stack detected
   - KERNEL instruction block (including test generation/maintenance)
3. Detects potential MCP servers from dependencies/imports
4. Creates starter commands from detected scripts
5. Detects test framework (pytest, unittest, jest, etc.) and existing test patterns
6. Enables hooks by creating/updating `.claude/settings.local.json`
7. Initializes test maintenance tracking
8. Reports what was created

### commands/activate.md

Enables KERNEL:
1. Ensures KERNEL instruction exists in CLAUDE.md
2. Enables extraction hooks
3. Confirms activation

### commands/deactivate.md

Disables KERNEL:
1. Disables extraction hooks (does not remove KERNEL instruction)
2. Claude continues normally; `<kernel>` blocks still appear but aren't processed
3. Confirms deactivation

### agents/test-maintainer.md

Plugin subagent for test generation and maintenance:

```markdown
---
name: test-maintainer
description: Test generation and maintenance specialist. Proactively use when test-generation or test-maintenance appears in <kernel> blocks, or when user requests test updates. Reads test queue and applies learned patterns.
tools: Read, Write, Grep, Glob, Bash
model: sonnet
---

You are a test maintenance specialist that generates and updates tests following learned patterns.

**Initialization**:
1. Read `memory/test-queue.jsonl` for pending test work
2. Read `memory/learnings.jsonl` for test patterns (type: "test_pattern")
3. Process each queued task in order

**For test generation**:
1. Read the target implementation file
2. Apply learned test patterns from memory
3. Generate tests matching project conventions
4. Write to specified test_file
5. Remove processed task from queue

**For test maintenance**:
1. Read both implementation and test files
2. Detect changes (signatures, behavior, imports)
3. Update tests preserving intent
4. Write updated tests
5. Remove processed task from queue

**Test patterns to follow** (from learnings):
- Framework detection (pytest, unittest, jest, etc.)
- Fixture usage patterns
- Mocking conventions
- Naming conventions
- Directory structure

**Output**:
- Concise summary of tests generated/updated
- Any patterns learned during this session
- File paths modified

**Never**:
- Overwrite passing tests without user confirmation
- Generate tests for trivial code (getters, simple pass-throughs)
- Duplicate existing test coverage
```

### agents/config-optimizer.md

Plugin subagent for configuration optimization and cleanup:

```markdown
---
name: config-optimizer
description: Configuration optimization specialist. Use proactively when CLAUDE.md grows large, when duplicate patterns appear, or when user requests config cleanup. Analyzes and optimizes all KERNEL-managed config.
tools: Read, Write, Grep, Glob
model: sonnet
---

You are a configuration optimization specialist that keeps KERNEL lean and efficient.

**Initialization**:
1. Read `memory/learnings.jsonl` to understand all learnings
2. Read `memory/config-queue.jsonl` for optimization requests
3. Read `.claude/CLAUDE.md` and other config files

**Optimization tasks**:
1. **Deduplicate**: Find and merge similar learnings/config entries
2. **Consolidate**: Combine related preferences into single entries
3. **Prune**: Remove outdated learnings (user can override)
4. **Organize**: Restructure CLAUDE.md for clarity
5. **Suggest deletions**: Identify unused commands/skills

**Output format**:
- Before/after comparison showing size reduction
- List of changes made with rationale
- Token savings estimate
- Suggestions for user review

**Principles**:
- Never delete user-created content without confirmation
- Preserve meaning while reducing verbosity
- Maintain chronological order in learnings.jsonl
- Back up before making changes

**Invoke when**:
- CLAUDE.md > 500 lines
- 100+ learnings accumulated
- Duplicate patterns detected
- User requests `/kernel:optimize`
```

### agents/pattern-analyzer.md

Plugin subagent for deep pattern discovery:

```markdown
---
name: pattern-analyzer
description: Pattern discovery specialist. Use proactively after 5+ similar workflows to discover meta-patterns. Analyzes learnings to surface higher-level automation opportunities.
tools: Read, Write, Grep, Glob
model: sonnet
---

You are a pattern analysis specialist that discovers automation opportunities.

**Initialization**:
1. Read `memory/learnings.jsonl` completely
2. Read `memory/pattern-queue.jsonl` for analysis requests
3. Read recent conversation transcripts if available

**Analysis process**:
1. **Cluster learnings**: Group by similarity
2. **Find sequences**: Detect workflow patterns (A → B → C)
3. **Identify triggers**: What causes these patterns?
4. **Suggest automation**: Commands, hooks, or skills to create

**Pattern types to detect**:
- **Workflow sequences**: User always does X after Y
- **Conditional patterns**: When A, then B
- **Tool chains**: Grep → Read → Edit sequences
- **Error patterns**: Same fix applied repeatedly
- **Code patterns**: Structural similarities across files

**Output format**:
```json
{
  "pattern_type": "workflow_sequence",
  "frequency": 8,
  "confidence": 0.92,
  "description": "After editing API files, user runs tests then updates docs",
  "automation_suggestion": {
    "type": "command",
    "name": "api-update",
    "rationale": "Observed 8 times, high consistency"
  }
}
```

**Invoke when**:
- 50+ learnings accumulated
- User requests `/kernel:analyze`
- Repeated workflow detected (3+ times)
- Monthly maintenance check
```

### agents/skill-builder.md

Plugin subagent for skill creation from workflows:

```markdown
---
name: skill-builder
description: Skill creation specialist. Use proactively when domain-specific patterns emerge (e.g., "always validate inputs this way"). Creates reusable Skills from learned workflows.
tools: Read, Write, Grep, Glob
model: sonnet
---

You are a skill builder that extracts reusable knowledge into Agent Skills.

**Initialization**:
1. Read `memory/learnings.jsonl` for domain patterns
2. Read existing skills in `.claude/skills/`
3. Analyze which patterns are skill-worthy

**Skill-worthy patterns**:
- Domain-specific knowledge (API conventions, data validation)
- Multi-step procedures done consistently
- Decision trees ("if X then Y, else Z")
- Tool combinations for specific tasks
- Project-specific best practices

**Creation process**:
1. **Identify candidate**: Pattern repeated 3+ times with consistency
2. **Extract knowledge**: What's the reusable insight?
3. **Write SKILL.md**: Follow progressive disclosure format
4. **Test conceptually**: Does this generalize?
5. **Create file**: Write to `.claude/skills/{skill-name}/SKILL.md`

**Skill format**:
```markdown
---
name: api-input-validator
description: Validates API inputs using project conventions. Use when handling API requests.
---

## When to use
Invoke when processing API request handlers or validating user inputs.

## Validation steps
1. Check required fields are present
2. Validate types match schema
3. Apply business rules (learned from project)
4. Sanitize inputs per project standards
```

**Output**:
- Skill created with path
- Rationale for creation
- Usage examples
- Related learnings that informed the skill

**Never**:
- Create skills for trivial knowledge
- Duplicate existing Claude capabilities
- Make skills too specific (won't generalize)
```

### commands/review.md

New slash command for reviewing learnings:

```markdown
---
description: Review accumulated learnings and suggest optimizations
---

# Review Learnings

Analyze current KERNEL state and suggest optimizations:

1. **Count learnings** in `memory/learnings.jsonl` by type
2. **Report config size**: CLAUDE.md lines, commands count, etc.
3. **Identify opportunities**:
   - Patterns that could become skills
   - Config that could be consolidated
   - Duplicate learnings to merge
4. **Suggest subagent invocations**:
   - "Consider running config-optimizer" if config is large
   - "Consider running pattern-analyzer" if 50+ learnings
   - "Consider running skill-builder" if domain patterns exist

Present findings in a concise summary with actionable recommendations.
```

### hooks/hooks.json

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 ${CLAUDE_PLUGIN_ROOT}/scripts/extract.py"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ${CLAUDE_PLUGIN_ROOT}/scripts/extract.py"
          }
        ]
      }
    ]
  }
}
```

### scripts/extract.py

Minimal Python script:

1. **Input**: Receives hook JSON via stdin (includes `transcript_path`)
2. **Parse**: Read transcript, find last `<kernel>` block, parse JSON
3. **Deduplicate learnings**:
   - Hash each learning
   - Check against `memory/learnings.jsonl`
   - Append only new learnings
4. **Apply config update** (if present):
   - Check if content already exists (fuzzy match)
   - Skip if duplicate
   - Otherwise create/append file
5. **Queue test work** (if `test_generation` or `test_maintenance` present):
   - Append JSON entry to `memory/test-queue.jsonl` with metadata
   - Entry includes: target_file, test_file, scope, reason, timestamp
   - No subagent invocation from hook—just record the request
6. **Queue optimization work** (if `optimization_trigger` present):
   - Append to appropriate queue: `config-queue.jsonl` or `pattern-queue.jsonl`
   - Entry includes: type, reason, suggested_agent, timestamp
7. **Check thresholds** (after processing):
   - Count learnings: if > 50, suggest pattern-analyzer
   - Check CLAUDE.md size: if > 500 lines, suggest config-optimizer
   - Log suggestions to console (non-blocking)
8. **Exit 0**: Allow Stop/PreCompact to proceed instantly (< 10ms)

Key behaviors:
- Graceful failure; if no `<kernel>` found, exit silently
- Never overwrite existing commands/skills without explicit flag
- No blocking operations; everything is append-only file writes
- Log what was recorded for transparency
- Threshold checks are purely informational (don't block or force actions)

### memory/learnings.jsonl

Append-only log of all learnings:

```json
{"type": "preference", "value": "always use type hints", "_hash": "a1b2c3d4", "_ts": "2025-01-09T..."}
{"type": "decision", "value": "using pytest for testing", "_hash": "e5f6g7h8", "_ts": "2025-01-09T..."}
{"type": "test_pattern", "value": "tests use pytest fixtures, mock external APIs with unittest.mock", "_hash": "i9j0k1l2", "_ts": "2025-01-09T..."}
```

Used for:
- Deduplication (by hash)
- Future analysis (what has KERNEL learned?)
- Debugging (why was this config created?)
- Test generation (apply learned patterns to new tests)
- Test maintenance (understand expected test structure)

### memory/test-queue.jsonl

Append-only queue of test work:

```json
{"type": "generation", "target_file": "src/user.py", "test_file": "tests/test_user.py", "scope": "unit", "reason": "new UserService class added", "_ts": "2025-01-09T..."}
{"type": "maintenance", "target_file": "src/auth.py", "test_file": "tests/test_auth.py", "action": "update", "reason": "login signature changed", "_ts": "2025-01-09T...", "_processed": true}
```

Used for:
- Queueing test work from extraction hook
- Subagent reads and processes queue
- Processed entries remain for audit trail (subagent adds `_processed: true`)

### memory/config-queue.jsonl (Optional)

**Only created if optimization features are used.** Append-only queue of config optimization work:

```json
{"type": "config_bloat", "reason": "CLAUDE.md reached 520 lines", "suggested_agent": "config-optimizer", "_ts": "2025-01-09T..."}
{"type": "duplicate_patterns", "reason": "similar preferences detected", "suggested_agent": "config-optimizer", "_ts": "2025-01-09T...", "_processed": true}
```

### memory/pattern-queue.jsonl (Optional)

**Only created if optimization features are used.** Append-only queue of pattern analysis work:

```json
{"type": "workflow_repetition", "reason": "55 learnings accumulated, potential meta-patterns", "suggested_agent": "pattern-analyzer", "_ts": "2025-01-09T..."}
{"type": "skill_opportunity", "reason": "API validation pattern repeated 5 times", "suggested_agent": "skill-builder", "_ts": "2025-01-09T..."}
```

**Note**: KERNEL works perfectly without these files. They only get created when optimization triggers are included in `<kernel>` blocks.

---

## INSTALLATION

User installs via Claude Code plugin system:

```
/plugin install kernel
```

Or manually by cloning to `~/.claude/plugins/kernel/`.

After installation:
1. Navigate to project directory
2. Run `/kernel:init`
3. KERNEL is now active

---

## SUCCESS CRITERIA

### Core Functionality (Required)

KERNEL's core features work when:

1. **Learning happens invisibly**: User works normally; `<kernel>` blocks appear without disruption
2. **Config evolves automatically**: After a few sessions, CLAUDE.md has useful entries, relevant commands exist
3. **Tests generate automatically**: New code gets tests following learned patterns, no manual test creation needed
4. **Tests maintain themselves**: When code changes, tests update automatically to stay in sync
5. **Easy control**: `/kernel:activate` and `/kernel:deactivate` work instantly
6. **Transparent**: User can see what KERNEL learned via `memory/learnings.jsonl`
7. **Minimal overhead**: No perceptible latency; extraction script runs in milliseconds

### Optional Enhancements (Add-ons)

Advanced features work when user chooses to use them:

8. **Config optimization**: `/kernel:review` shows health, user can invoke `config-optimizer` if needed
9. **Pattern discovery**: User can invoke `pattern-analyzer` to find meta-patterns after 50+ learnings
10. **Skill extraction**: User can invoke `skill-builder` when domain patterns emerge
11. **No bloat**: Config stays lean through optional optimization features
12. **Self-maintenance**: KERNEL can optimize itself when user requests it

**Important**: Features 8-12 are enhancements. KERNEL fully functions with just features 1-7.

---

## CORE VS OPTIONAL FEATURES

### Core Features (Always Active)

These features make KERNEL work and are always present:

| Feature | What it does | Files involved |
|---------|--------------|----------------|
| **Learning** | Captures preferences, decisions, patterns | `extract.py`, `learnings.jsonl` |
| **Config Evolution** | Creates/updates CLAUDE.md, commands, skills | `extract.py`, `.claude/` files |
| **Test Generation** | Queues and generates tests for new code | `test-maintainer.md`, `test-queue.jsonl` |
| **Test Maintenance** | Updates tests when code changes | `test-maintainer.md`, `test-queue.jsonl` |
| **Commands** | `/kernel:init`, `/kernel:activate`, `/kernel:deactivate` | `commands/` |

**These features work independently. KERNEL is fully functional with just these.**

### Optional Enhancements (User-Activated)

These features enhance KERNEL but aren't required for it to work:

| Feature | What it does | When to use | Files involved |
|---------|--------------|-------------|----------------|
| **Config Optimization** | Deduplicates and cleans configuration | When CLAUDE.md > 500 lines | `config-optimizer.md`, `config-queue.jsonl` |
| **Pattern Analysis** | Discovers meta-patterns and automation opportunities | After 50+ learnings | `pattern-analyzer.md`, `pattern-queue.jsonl` |
| **Skill Extraction** | Creates reusable Skills from workflows | When domain patterns emerge 3+ times | `skill-builder.md`, `pattern-queue.jsonl` |
| **Review Command** | Shows KERNEL health and suggests optimizations | When you want to check status | `review.md` |

**How optional features activate**:
1. Claude can include `optimization_trigger` in `<kernel>` block (optional field)
2. User can explicitly invoke enhancement subagents (e.g., "use config-optimizer")
3. User can run `/kernel:review` to see suggestions
4. If never used, KERNEL still works perfectly—just without self-optimization

**Think of it like**:
- **Core**: The engine that makes KERNEL learn and evolve
- **Optional**: The maintenance crew that keeps the engine tuned

---

## WHAT KERNEL IS NOT

- ❌ **Not a context manager**: Claude Code already has Read/Grep/Glob for searching
- ❌ **Not a prompt validator**: The user writes detailed prompts; gating is unnecessary
- ❌ **Not an agent framework**: Claude Code already has subagents via Task tool
- ❌ **Not complex**: Two hooks, one script, three commands; that's it

---

## DESIGN PHILOSOPHY

### Claude does the thinking

The main model is already in context, already understands. KERNEL just asks it to articulate that understanding in a structured way. For test generation/maintenance, a subagent (also Claude) handles the actual test code generation using learned patterns. The extraction script stays lightweight—just metadata extraction and task queuing.

### Visible reflection

The `<kernel>` block stays in conversation. Claude sees its own prior learnings. This creates consistency and prevents repetition.

### Lean config

Every config addition is checked for duplicates. Strong thresholds prevent noise. One update per response forces prioritization.

### Automatic with escape hatch

Learning happens by default. Test generation and maintenance happen automatically. User can deactivate anytime. Config changes are visible and reversible. Tests can be regenerated or disabled per-project.

### Token optimization strategy

**Minimize main conversation bloat**:
- `<kernel>` blocks are concise JSON (no verbose explanations)
- Learnings are stored once in memory, referenced by hash
- Test generation happens in subagent's separate context
- Main conversation stays focused on high-level objectives

**Efficient knowledge reuse**:
- Test patterns learned once, applied infinitely
- Subagent reads `learnings.jsonl` only when needed
- No duplication: patterns referenced, not repeated
- Queue-based architecture: test work doesn't block main flow

**Lazy execution**:
- Extraction hook runs in < 10ms (just file appends)
- Test work queued, not executed synchronously
- Subagent invoked only when user explicitly requests or Claude detects need
- No wasted tokens on unused patterns

**Separate contexts**:
- Main conversation: strategy, learning, configuration
- Subagent context: tactical test generation using learned patterns
- Each context stays small and focused
- Total token usage across both contexts < single-context approach

---

## YOUR TASK

Build KERNEL as specified:

### Phase 1: Core Functionality (MVP)

1. Create plugin structure at `~/.claude/plugins/kernel/`
2. Implement core files:
   - `plugin.json` (manifest)
   - `init.md`, `activate.md`, `deactivate.md` (core commands)
   - `test-maintainer.md` (core subagent)
   - `hooks.json` (extraction triggers)
   - `extract.py` (parse, dedup, apply, queue test work)
   - `README.md` (documentation)
3. Ensure scripts are executable
4. Test core flow:
   - `/kernel:init` sets up a project
   - Claude outputs `<kernel>` blocks
   - Extraction hook captures learnings
   - Config updates are applied
   - Test generation queues work
   - Test-maintainer processes queue

### Phase 2: Optional Enhancements (Can be added later)

5. Add enhancement files (optional):
   - `review.md` (command)
   - `config-optimizer.md`, `pattern-analyzer.md`, `skill-builder.md` (enhancement subagents)
6. Test enhancement flow:
   - `/kernel:review` shows status
   - Enhancement subagents work when invoked
7. Report what you built

**Start with Phase 1. Phase 2 can be built incrementally after core works.**

Focus on:
- **Minimal code**: Clean, readable, maintainable
- **Proper documentation**: README explains everything
- **Graceful failures**: Script handles missing blocks, malformed JSON
- **No token waste**: Extraction is fast and local

---

## VERIFICATION

After building:

```bash
# Check structure
tree ~/.claude/plugins/kernel/

# Validate plugin.json
cat ~/.claude/plugins/kernel/.claude-plugin/plugin.json | jq .

# Test extraction script with mock input
echo '{"transcript_path": "/tmp/test.jsonl"}' | python3 ~/.claude/plugins/kernel/scripts/extract.py

# In Claude Code
/kernel:init
# ... work normally ...
# Check that <kernel> blocks appear
# Check .claude/CLAUDE.md for updates
# Create new code - verify tests are generated
# Modify existing code - verify tests are maintained
```

Begin.


/Users/ariaxhan/Documents/claude-code-playground/kernel-plugin
Alias setup complete

To configure claude, add this line to your /Users/ariaxhan/.zshrc:
  alias claude="/Users/ariaxhan/.claude/local/claude"

Then run: source /Users/ariaxhan/.zshrc



Next, we'll remove the globally installed npm package


