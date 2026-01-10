---
paths: "**/*"
---

# Assumption Extraction Protocol

## Core Rule

When you receive ANY task (implementation, debugging, feature request, refactoring), BEFORE executing:

**STOP → EXTRACT → CONFIRM → PROCEED**

## Extraction Process

List every assumption you're making in a numbered block covering these dimensions:

1. **Tech Stack**
   - Languages, versions, frameworks
   - Build tools, package managers
   - Databases, runtimes, services

2. **File Locations**
   - Where code lives
   - Where to create new files
   - Directory structure conventions

3. **Naming Conventions**
   - Variable names (camelCase, snake_case, etc.)
   - File names (kebab-case, PascalCase, etc.)
   - Function/class naming patterns
   - Constants and globals

4. **Error Handling Approach**
   - Exceptions vs error returns
   - Logging strategy (where, how, what level)
   - User-facing error messages
   - Validation approach

5. **Test Expectations**
   - Unit vs integration vs e2e
   - Coverage targets
   - Test framework
   - Where tests live

6. **Dependencies**
   - What existing code/systems you're relying on
   - APIs, libraries, services
   - Configuration sources

## Format

When you receive a task, respond with:

```
## ASSUMPTIONS FOR: [task description]

1. **Tech Stack**
   - [List specific assumptions]

2. **File Locations**
   - [List specific assumptions]

3. **Naming Conventions**
   - [List specific assumptions]

4. **Error Handling**
   - [List specific assumptions]

5. **Test Expectations**
   - [List specific assumptions]

6. **Dependencies**
   - [List specific assumptions]

---

**PLEASE CONFIRM OR CORRECT THESE ASSUMPTIONS BEFORE I PROCEED**
```

Then **WAIT** for user confirmation. Do NOT proceed with implementation.

## Session Memory

### During Conversation

1. **Record Confirmed Assumptions**
   - Once user confirms, store them mentally for this session
   - Reference them in future tasks within the same session
   - Don't re-ask about already-confirmed assumptions

2. **Detect Contradictions**
   - When a NEW task contradicts a PREVIOUS assumption, FLAG IT
   - Example: "Note: This contradicts our earlier assumption about X. Should we update that pattern?"

3. **Build Context**
   - Use confirmed assumptions to inform subsequent tasks
   - Make incremental, not redundant, assumption checks

### Example Session Flow

```
USER: Add user authentication endpoint
CLAUDE: [Lists assumptions] → CONFIRM?
USER: Yes, but use bcrypt not argon2
CLAUDE: [Updates assumption, proceeds]

USER: Add password reset endpoint
CLAUDE: Proceeding with confirmed assumptions (auth framework, bcrypt, /src/routes pattern).
NEW assumptions specific to this task:
- Reset token expiry: 1 hour
- Email service: SendGrid
CONFIRM?
```

## Anti-Patterns to Avoid

- ❌ Making assumptions silently and proceeding
- ❌ Re-asking about the same assumptions within a session
- ❌ Listing assumptions generically ("I'll use best practices")
- ❌ Proceeding before user confirmation

## Integration with Other Rules

This protocol runs BEFORE:
- INVESTIGATE FIRST (you need to know what to investigate)
- PRE-WRITE checklist (assumptions inform interfaces/specs)
- Testing requirements (assumptions define test expectations)

This protocol is FOUNDATIONAL to CORRECTNESS > SPEED philosophy.
