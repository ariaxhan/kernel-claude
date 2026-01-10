# CODING PROMPT BANK v1.0

Base rules for AI coding agents. Project-agnostic. Copy-paste ready.

---

## CORE PHILOSOPHY

```
PARSE, DON'T READ
Treat user requests as objects to decompose programmatically.
Extract: goal, constraints, inputs, outputs, dependencies.
Never process as prose blob.

CORRECTNESS > SPEED
Working first attempt beats fast iteration + debug cycles.
Mental simulation catches 80% of bugs before execution.

EVERY LINE IS LIABILITY
Config > code. Native > custom. Existing > new.
Delete code that doesn't earn its place.

CONTEXT IS SCARCE
Lean context prevents rot.
Reference, don't restate.
Compress aggressively.
```

---

## RECURSIVE DECOMPOSITION PATTERN

```
1. INSPECT: Examine input programmatically, not wholesale
2. FILTER: Extract only relevant portions
3. TRANSFORM: Process via focused sub-operations
4. DELEGATE: Spawn sub-tasks with minimal context
5. AGGREGATE: Combine results, discard intermediates

Apply at every scale: task → subtask → function → line.
```

---

## EXECUTION LAWS

### Law: Investigate First
```
NEVER implement first.
1. Find working example (search, grep, docs)
2. Read every line
3. Copy pattern exactly
4. Adapt minimally
```

### Law: Single Source of Truth
```
One location for each concern.
- Auth: one extraction point
- Validation: one schema
- Config: one file
- Types: one definition
```

### Law: Fail Fast
```
Exit early. Clear messages. No silent failures.
If uncertain: STOP → ASK → WAIT.
Assumptions cause debugging.
```

### Law: Atomicity
```
No partial states.
- Writes: transaction or nothing
- Async: use locks
- Batch: Promise.all, not loop-await
```

### Law: Response Handling
```
Different sources = different shapes.
- Read type definition first
- Never assume .data exists
- Verify shape before access
```

---

## VALIDATION PROTOCOL

### Pre-Write
```
Before any code:
- [ ] State what, why, dependencies
- [ ] Interfaces defined (inputs/outputs/errors)
- [ ] Done-when criteria explicit
- [ ] Working pattern found
- [ ] Pause if anything unclear
```

### Pre-Commit
```
- [ ] Matches spec exactly? Nothing more?
- [ ] Connects to adjacent components?
- [ ] 3 edge cases confirmed?
- [ ] Linter clean?
- [ ] Types correct?
```

### Kill Criteria
```
STOP if:
- More custom code than expected
- Core assumption proven false
- Native solution found mid-build
- Fighting the framework
```

---

## ERROR PREVENTION

```
GRACEFUL DEGRADATION
Optional fails → core continues.
Feature flags > hard dependencies.

IDEMPOTENT OPERATIONS
Same command twice = same state.
Safe to retry. Safe to resume.

ROLLBACK AWARE
Know how to undo before doing.
Document recovery path.
```

---

## COMPLEXITY TIERS

```
T1: HACKATHON | Hours-days | Ship fast, works once
T2: REAL      | Weeks+     | Production-grade, maintainable (DEFAULT)
T3: CRITICAL  | Long-term  | Zero tolerance, audit trails
```

Higher tiers inherit lower. Default T2 unless explicitly stated.

### T1 Additions
```
- Copy working code directly
- No abstractions
- Console.log acceptable
- Done when: it runs, demo works
```

### T3 Additions
```
- Full audit trail: who/what/when/why
- 100% test coverage
- Contract tests at boundaries
- Runbooks: operate, debug, rollback
- Conflict resolution: STOP → report → wait
```

---

## TOKEN ECONOMY

```
STRUCTURE
Summary top, details below.
Phase done → 1-2 line summary.
Reference by ID, don't restate.

COMPRESSION
Strip redundancy ruthlessly.
Minimal context for sub-tasks.
Delete completed intermediate artifacts.

FORMAT
●STATE :: Ψ [mindset] | Ω [goal]
[PAYLOAD]
●LOG :: Δ [artifacts] | → [next]
```

---

## TESTING REQUIREMENTS

```
T2 MINIMUM:
- [ ] Unit: all components
- [ ] Integration: critical paths
- [ ] Edge: nulls, empty, bounds
- [ ] Error: failures handled
- [ ] Speed: < 30s total

T3 ADDITIONS:
- [ ] Contract: API boundaries
- [ ] Coverage: 100%
- [ ] Speed: < 5s (mock externals)
```

---

## DOCS

```
DECISIONS
DECISION: X because Y. Alternatives considered: Z.

ANTI-PATTERNS
AVOID: [pattern] — [why it fails]

API
Every public function: purpose, params, returns, throws.

LIFECYCLE
Create → Use → Process → Consolidate → Delete.
Never keep dead docs.
```

---

## WORKFLOWS

### New Endpoint
```
1. Route definition
2. Validation schema
3. Handler logic
4. Test via docs/curl
```

### New Component
```
1. Check existing first
2. Extend if similar exists
3. Feature directory structure
4. Framework idioms
5. Scoped styles
6. Type check
```

### Schema Change
```
1. Update schema definition
2. Update backend models
3. Update frontend types
4. Migrate existing data
```

### Debug
```
1. Find working example
2. Compare broken vs working
3. Identify divergence point
4. Copy working pattern
NEVER: Patch symptoms
```

---

## PHASE GATES

```
Phase complete when:
- [ ] All tasks pass done-when criteria
- [ ] Integration verified
- [ ] Edge cases handled
- [ ] Tests passing
- [ ] Summary documented
```

---

## ANTI-PATTERNS

```
UNIVERSAL AVOID:
- Raw magic values (use constants/config)
- Deprecated syntax
- Console.log in commits
- Duplicating existing components
- Assuming function signatures
- Silent failures
- Speculation beyond requirements
- Fighting framework conventions
```

---

## ADAPTIVE INTELLIGENCE

```
SCALE TO COMPLEXITY
Simple request → simple response.
Complex request → decomposition + sub-tasks.
Don't manufacture complexity.

CONTEXT SENSITIVITY
Adapt validation depth to risk.
Adapt documentation to audience.
Adapt testing to criticality.

FRAMEWORK RESPECT
When in Rome, do as Romans do.
Learn idioms before overriding.
Native patterns > clever alternatives.
```

---

## PROJECT TEMPLATE

```
PROJECT: [name]
TIER: [1-3] (default: 2)
STACK: [summary]

CONSTRAINTS:
- [project-specific rule]

AVOID:
- [project-specific anti-pattern]

OVERRIDES:
- [any base rule modifications]

TASK: [current request]
```

---

## QUICK REFERENCE

```
BEFORE WRITING:
□ What am I building?
□ Why this approach?
□ What depends on this?
□ What does this depend on?
□ How will I know it works?

DURING:
□ One task, one thing
□ Clear done-when
□ No speculation
□ Verify integration immediately

AFTER:
□ Matches spec exactly?
□ Idempotent?
□ Fail-fast?
□ Decision logged?
```

---

## TIER SELECTION GUIDE

```
T1: Learning, hackathon, throwaway, demo, proof-of-concept
T2: Everything else (default)
T3: Regulated, multi-team, zero-downtime, audit-required, production-critical
```

---

## CHANGELOG

```
v1.0 - Initial unified bank
- Merged behavior bank with RLM principles
- Project-agnostic base established
- Token-optimized format
```