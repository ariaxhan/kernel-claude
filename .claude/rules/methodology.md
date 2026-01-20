# Automatic Methodology Application

Apply methodology automatically based on task context. Banks provide depth; these rules trigger when to use them.

---

## Context Detection → Bank Loading

### PLANNING (kernel/banks/PLANNING-BANK.md)

**Trigger when task involves:**
- "implement", "add", "create", "build" + non-trivial feature
- "design", "architect", "structure"
- Multiple components or files to coordinate
- User describes a feature without implementation details

**Auto-apply:**
1. Understand the goal completely before touching code
2. Extract and list assumptions explicitly
3. Investigate existing patterns in codebase first
4. Define interfaces before implementations
5. Mentally simulate execution step-by-step

**Signal phrases:** "add a new...", "implement...", "create a system for...", "build..."

---

### DEBUGGING (kernel/banks/DEBUGGING-BANK.md)

**Trigger when task involves:**
- "bug", "error", "fix", "broken", "not working", "fails"
- Stack traces or error messages in context
- "why is this...", "why does this..."
- Unexpected behavior descriptions

**Auto-apply:**
1. Reproduce the issue first (get exact steps)
2. Isolate to smallest failing case
3. Instrument to understand actual behavior
4. Identify root cause, not just symptoms
5. Fix and verify the fix doesn't break other things

**Signal phrases:** "fix this bug", "why is this failing", "getting an error", "doesn't work"

---

### RESEARCH (kernel/banks/RESEARCH-BANK.md)

**Trigger when task involves:**
- New functionality with no existing pattern in codebase
- Integration with external services/APIs
- "best way to...", "how should I..."
- Technologies or libraries not currently in project

**Auto-apply:**
1. Search for existing packages/solutions first
2. Find 3+ sources before deciding on approach
3. Document known pitfalls from others' experience
4. Prefer battle-tested solutions over custom code
5. The best code is code you don't write

**Signal phrases:** "what's the best way to...", "how do I integrate...", "should I use..."

---

### REVIEW (kernel/banks/REVIEW-BANK.md)

**Trigger when:**
- About to complete a task or mark it done
- User asks to check, validate, or verify work
- Significant changes have been made
- Before committing or shipping

**Auto-apply:**
1. Check correctness against requirements
2. Verify convention adherence (naming, patterns)
3. Validate edge cases and error handling
4. Confirm no regressions introduced
5. Review from fresh perspective before declaring done

**Signal phrases:** "is this right?", "check this", "before we ship", "review this"

---

### DISCOVERY (kernel/banks/DISCOVERY-BANK.md)

**Trigger when:**
- First interaction with unfamiliar codebase
- User asks about project structure
- Need to understand existing patterns before changing
- "where is...", "how does this project..."

**Auto-apply:**
1. Map directory structure and key files
2. Detect tooling (build, test, lint, format)
3. Extract naming conventions from existing code
4. Identify critical paths (don't touch these carelessly)
5. Build world model before making assumptions

**Signal phrases:** "what's in this codebase", "how is this structured", "where should I put..."

---

### ITERATION (kernel/banks/ITERATION-BANK.md)

**Trigger when:**
- "improve", "refactor", "optimize", "clean up"
- "make this better", "simplify"
- Performance or quality improvements
- Technical debt reduction

**Auto-apply:**
1. Understand current implementation deeply first
2. Identify specific improvements (don't vague-refactor)
3. Prioritize by impact (UX > performance > aesthetics)
4. Make one change at a time, verify each
5. Code reduction is often the best improvement

**Signal phrases:** "refactor this", "improve this", "make this cleaner", "optimize"

---

### CRITICAL REVIEW (kernel/banks/TEARITAPART-BANK.md)

**Trigger when:**
- Complex plan about to be implemented
- Architectural decisions being made
- High-risk changes (auth, payments, data migration)
- User explicitly wants critique

**Auto-apply:**
1. Question every assumption in the plan
2. Find what could cause long-term pain (not nitpicks)
3. Identify missing error handling and edge cases
4. Consider maintenance burden and complexity cost
5. Play devil's advocate before implementation

**Signal phrases:** "what could go wrong", "critique this plan", "before I implement..."

---

## Redundancy Layers

### Layer 1: Rule Detection (This File)
Loaded automatically. Detects context from user messages.

### Layer 2: CLAUDE.md Default Behaviors
Embedded in project config. Applied on all tasks.

### Layer 3: Bank Deep Dives
Full methodology available in `kernel/banks/`. Reference when:
- Task is unusually complex
- Initial approach isn't working
- Want the complete checklist

---

## Application Notes

- **Don't announce:** Just apply the methodology naturally
- **Don't be rigid:** Adapt to context, skip irrelevant steps
- **Reference banks:** When deeper guidance needed, read the bank
- **Multiple triggers:** Tasks often trigger multiple methodologies (e.g., implement new feature = RESEARCH + PLANNING + REVIEW)
- **User override:** If user says "just do it" or "skip the planning", respect that

---

## Quick Reference

| Context | Methodology | Bank |
|---------|-------------|------|
| New feature | Research → Plan → Review | RESEARCH, PLANNING, REVIEW |
| Bug fix | Debug → Review | DEBUGGING, REVIEW |
| Refactor | Iterate → Review | ITERATION, REVIEW |
| New codebase | Discover first | DISCOVERY |
| Complex plan | Tear apart before implementing | TEARITAPART |
| Before shipping | Review thoroughly | REVIEW |
