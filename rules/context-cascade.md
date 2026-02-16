# Context Cascade Protocol

**Pass outputs only, not full context.** Each phase gets minimal context + specialized task.

---

## The Problem

Accumulating context causes rot:
```
Phase 1: 10k tokens
Phase 2: 10k + Phase 1 context = 20k tokens
Phase 3: 20k + Phase 2 context = 40k tokens
...
Phase N: Context window exhausted, quality degraded
```

## The Solution

Cascade outputs, discard intermediate context:
```
Phase 1: 10k tokens → Output: 1k token spec
Phase 2: 1k spec + 5k implementation context = 6k tokens → Output: code + tests
Phase 3: Code + 3k review context = 5k tokens → Output: issues
```

Each phase stays lean. Quality stays high.

---

## Phase Handoffs

### PLAN → IMPLEMENT

**Pass forward:**
- Interface spec (inputs, outputs, error cases)
- Key decisions made
- File locations

**Discard:**
- Research context
- Alternative approaches considered
- Planning conversation

### IMPLEMENT → REVIEW

**Pass forward:**
- Code diff
- Test results
- Spec it was built against

**Discard:**
- Implementation conversation
- Debugging tangents
- File exploration context

### REVIEW → SHIP

**Pass forward:**
- Issues found (if any)
- Approval status
- Commit message draft

**Discard:**
- Review conversation
- Code that was already approved

---

## In Practice

When spawning subagents:
```
BAD: "Here's the full conversation context, now implement..."
GOOD: "Implement this spec: [minimal spec]. Files: [locations]. Patterns: [from state.md]"
```

When completing a phase:
```
BAD: Keep everything in context for "reference"
GOOD: Summarize outputs, archive context, start fresh
```

---

## Integration

- Banks should produce discrete outputs, not conversation
- `_meta/context/active.md` captures outputs, not full transcripts
- Subagents get specs, not history

---

*The cascade is a reduction funnel. Each phase compresses, not accumulates.*
