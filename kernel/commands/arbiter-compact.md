---
description: Compress conversation context via arbiter logic
allowed-tools: Read, Write, Bash
---

When user invokes `/arbiter-compact`:

## PHASE 1: EXTRACTION

Analyze the current conversation and extract all factual knowledge in **ARBITER SYNTAX**.

Follow `.claude/rules/arbiter-syntax.md` strictly:
- Use `snake_case` identifiers only
- One statement per line
- Operators: `&` (and), `|` (or), `!` (not), `->` (implies), `<->` (iff)
- NO prose, NO explanations, ONLY logic statements
- Group with `#` comments for readability

### Categories to Extract

Extract facts across these dimensions:

**1. Project Setup**
```
# Technologies/frameworks in use
use_<technology>
requires_<dependency>
version_constraint_<tool>
```

**2. Architecture Decisions**
```
# System design choices
api_is_<type>
database_is_<type>
auth_is_<method>
pattern_is_<pattern>
```

**3. Coding Conventions**
```
# Style and patterns
use_type_hints
use_<naming_convention>
require_<practice>
```

**4. Access Control / Business Logic**
```
# Permission rules
<condition> -> <capability>
<role> & <status> -> <permission>
```

**5. API Contracts**
```
# Endpoint behaviors
endpoint_<name>_returns_<format>
endpoint_<name>_requires_<condition>
```

**6. Dependencies / Tooling**
```
# Available tools and configs
has_<tool>
<tool>_<config>_enabled
```

**7. File Locations / Structure**
```
# Where things live (if relevant to future work)
tests_in_tests_dir
config_in_<location>
```

**8. Decisions Made**
```
# Explicit choices during conversation
decided_<decision>
rejected_<alternative>
```

## PHASE 2: VALIDATION & COMPRESSION

1. **Write extracted facts** to `/tmp/arbiter_extracted.txt`

2. **Run arbiter compression**:
   ```bash
   python3 .claude/tools/arbiter.py /tmp/arbiter_extracted.txt > /tmp/arbiter_compressed.txt
   ```

3. **Compare results**:
   - Show original fact count
   - Show compressed fact count
   - Show compression ratio
   - Highlight any contradictions detected

## PHASE 3: OUTPUT

Present to user:

```
## Extracted Facts (N statements)
[show /tmp/arbiter_extracted.txt contents]

## Compressed Facts (M statements, X% reduction)
[show /tmp/arbiter_compressed.txt contents]

## Analysis
- Tautologies removed: [count]
- Redundancies removed: [count]
- Contradictions detected: [list if any]

## Next Steps
You can now use this compressed fact set as context seed.
To reset conversation with these facts, manually use:
  /compact focus=<paste compressed facts>
```

## EXAMPLE OUTPUT

Given conversation about setting up a FastAPI project with pytest:

**Extracted (8 statements)**:
```
use_python
use_fastapi
use_pytest
use_sqlalchemy
database_is_postgres
authenticated -> can_read
admin & authenticated -> can_write
admin -> authenticated
```

**Compressed (7 statements, 12.5% reduction)**:
```
use_python
use_fastapi
use_pytest
use_sqlalchemy
database_is_postgres
authenticated -> can_read
admin & authenticated -> can_write
```

**Analysis**:
- Redundancies removed: 1
  - `admin -> authenticated` is implied by `admin & authenticated -> can_write`

## IMPORTANT NOTES

- **Be comprehensive**: Extract ALL decisions, conventions, constraints discussed
- **Be precise**: Use exact arbiter syntax (see arbiter-syntax.md)
- **Be minimal**: Arbiter compression will remove redundancies, but start clean
- **Check yourself**: Before running arbiter, verify your syntax is valid

## WORKFLOWS

### Manual Workflow (Current)

Use `/arbiter-compact` when you want to manually compress conversation context:
1. Claude extracts facts in arbiter syntax
2. Facts are validated and compressed
3. User sees results and can manually use `/compact focus=<facts>`

### Automatic Workflow (Available via Hook)

To enable automatic compression on every context compaction:

1. **Enable PreCompact hook** in `.claude/settings.json`:
```json
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Extract conversation facts in arbiter syntax per .claude/rules/arbiter-syntax.md. Output ONLY logical statements, no prose."
          }
        ]
      }
    ]
  }
}
```

2. **How it works**:
   - When Claude Code hits context limit → PreCompact hook fires
   - Claude automatically extracts facts in arbiter syntax
   - Facts are compressed via arbiter.py
   - Compressed facts become the new context seed
   - Conversation continues with ~95% token reduction

3. **Benefits**:
   - Zero manual intervention
   - Mathematically precise compression
   - No information loss (only redundancy removal)
   - Seamless long conversations
