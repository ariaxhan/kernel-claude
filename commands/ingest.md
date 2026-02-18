---
description: Universal entry point - classify input and route to appropriate flow
---

# /ingest

Universal entry. Classify → Scope → Route.

## ●:ON_START

```bash
agentdb read-start
```

## ●:CLASSIFY

| Signal | Type | Route |
|--------|------|-------|
| error, bug, fix, broken | bug | debug skill → surgery |
| add, create, implement, build | feature | /build |
| what, how, why, ? | question | research skill |
| refactor, clean, improve | refactor | contract → surgery |
| test, verify, check | verify | adversary |

## ●:TIER

Count affected files to determine tier:

| Tier | Files | Action |
|------|-------|--------|
| 1 | 1-2 | Execute directly |
| 2 | 3-5 | Create contract, spawn surgeon |
| 3 | 6+ | Create contract, spawn surgeon + adversary |

## ●:CONFIRM (Tier 2+)

```
CONFIRM:
- Type: {bug|feature|refactor|question}
- Scope: {files}
- Tier: {1|2|3}
- Approach: {what I'll do}

Proceed?
```

## ●:ROUTES

**Bug (Tier 1):**
```
1. Load debug skill
2. Reproduce → Isolate → Fix → Verify
3. Commit
```

**Bug (Tier 2+):**
```
1. Create contract
2. Spawn surgeon with debug skill
3. Spawn adversary to verify
```

**Feature:**
```
1. Load research skill (if unfamiliar)
2. Create contract (Tier 2+)
3. /build pipeline
```

**Question:**
```
1. Load research skill
2. Search codebase
3. Answer with file:line references
```

## ●:PARALLEL

```
independent_tasks(2+) → spawn parallel agents
```

Don't do serially what can be done in parallel.

## ≠:NEVER

```
code_before_confirm (Tier 2+)
guess_bug_cause
skip_agentdb_read
```

## ●:ON_END

```bash
agentdb write-end '{"ingested":"X","routed_to":"Y","tier":N}'
```
