---
paths: "**/*"
---

# Arbiter Syntax for Context Compression

When extracting facts for context compression, output ONLY in ARBITER SYNTAX.

## SYNTAX RULES

**Identifiers**: `snake_case` only (lowercase with underscores)

**Operators**:
- `&` — AND (conjunction)
- `|` — OR (disjunction)
- `!` — NOT (negation)
- `->` — IMPLIES (if-then)
- `<->` — IFF (if and only if, bidirectional implication)

**Format**:
- One statement per line
- No prose, no explanations, no natural language
- Comments allowed with `#` prefix
- Parentheses for grouping: `(a & b) | c`

## VALID EXAMPLES

```
# Simple facts
use_pytest
api_returns_json
user_authenticated

# Implications
authenticated -> can_read
admin & authenticated -> can_delete
!banned -> can_post

# Equivalences
logged_in <-> session_exists
admin <-> has_role_admin

# Complex conditions
(admin | moderator) & !banned -> can_moderate
authenticated & email_verified -> can_publish
```

## INVALID EXAMPLES

```
# ❌ WRONG: prose/natural language
We decided to use pytest for testing

# ❌ WRONG: camelCase identifier
usePytest

# ❌ WRONG: explanations mixed with logic
use_pytest  # because it's the best framework

# ❌ WRONG: unknown operators
a => b
a == b
```

## EXTRACTION CATEGORIES

When compressing conversation context, extract facts in these categories:

### Project Setup
```
# Technologies and frameworks
use_python
use_fastapi
use_sqlalchemy

# Version constraints
python_version_3_9_plus
requires_pytest
```

### Architecture Decisions
```
# System design
api_is_rest
database_is_postgres
auth_is_jwt

# Patterns
use_repository_pattern
use_dependency_injection
```

### Coding Conventions
```
# Style rules
use_type_hints
use_snake_case_functions
use_dataclasses_for_models

# Testing requirements
test_coverage_minimum_80
require_unit_tests
require_integration_tests
```

### Access Control / Business Rules
```
# Permissions
authenticated -> can_read
admin & authenticated -> can_write
admin & authenticated -> can_delete

# Workflow rules
draft_created -> !published
published -> immutable
```

### API Contracts
```
# Endpoint behaviors
endpoint_returns_json
endpoint_requires_auth
endpoint_is_idempotent

# Data requirements
user_requires_email
user_requires_password_hash
```

### Dependencies / Tooling
```
# Available tools
has_pytest
has_mypy
has_black
has_git

# Configuration
mypy_strict_mode
pytest_coverage_enabled
```

### Derived Facts (Candidates for Compression)
```
# These may be redundant and removed by arbiter
admin -> authenticated
authenticated & verified -> trusted
trusted -> can_post
```

## EXTRACTION PROCESS

When `/arbiter-compact` is invoked:

1. **Analyze conversation**: Read all messages, code changes, decisions made
2. **Extract atomic facts**: Break down knowledge into minimal logical units
3. **Use snake_case**: Convert all concepts to valid identifiers
4. **Output pure logic**: No explanations, no prose, only arbiter syntax
5. **Group with comments**: Use `#` to organize categories
6. **Include derivations**: Let arbiter compression remove redundancies

## COMPRESSION EXPECTATIONS

After extraction, `arbiter.py` will:
- Validate syntax (reject malformed statements)
- Check for contradictions (flag logical inconsistencies)
- Remove tautologies (always-true statements)
- Eliminate redundancies (statements implied by others)

The result is a **minimal, logically consistent fact set** representing all conversation knowledge.

---

## ANTI-PATTERNS TO AVOID

**DON'T write prose:**
```
# ❌ WRONG
The project uses pytest for testing because it has good fixtures.

# ✓ CORRECT
use_pytest
```

**DON'T mix explanation with logic:**
```
# ❌ WRONG
authenticated -> can_read  # users who are logged in can read

# ✓ CORRECT
# Access control
authenticated -> can_read
```

**DON'T use non-snake_case:**
```
# ❌ WRONG
usePyTest
USE_PYTEST
use-pytest

# ✓ CORRECT
use_pytest
```

**DON'T guess at syntax:**
```
# ❌ WRONG
a => b
a === b
a AND b

# ✓ CORRECT
a -> b
a <-> b
a & b
```

---

## WHEN THIS APPLIES

This rule applies when:
- `/arbiter-compact` command is invoked
- Context compression with fact extraction is requested
- User asks for "arbiter format" or "logical compression"

**NOT applicable for:**
- Normal conversation responses
- Code generation
- Documentation writing
- Explanations to user

This is a **specialized extraction format** for mathematical context compression only.
