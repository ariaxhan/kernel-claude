---
description: Create contract-first scope before any work
---

# Contract Mode

## ●:ON_START

```bash
agentdb read-start
```

Force contract-first framing before any work begins.

## Why Contracts

No work without explicit scope. Contracts prevent:
- Scope creep
- Unclear success criteria
- Missing failure conditions
- Ambiguous assignments

## Required Clauses

| Clause | Purpose |
|--------|---------|
| GOAL | Observable, testable success metric |
| CONSTRAINTS | Hard walls (files, no deps, no schema changes) |
| FAILURE CONDITIONS | Negative targets (rejected if X) |

## Template

```
CONTRACT: {id}
─────────────
GOAL:
- {observable_outcome}
- Verified by: {test/screenshot/curl}

CONSTRAINTS:
- Scope: {files} | Tier: {1/2/3}
- No dependencies added
- No schema changes
- No refactoring adjacent code

FAILURE CONDITIONS (REJECTED IF):
- Touches files outside scope
- No evidence of verification
- Breaks existing tests
- Changes API shape without approval

ASSIGN: {architect|surgeon|adversary}
```

## Log to AgentDB

```bash
sqlite3 _meta/agentdb/agent.db \
  "INSERT INTO contracts (id, goal, constraints, failure_conditions, tier, assigned_to)
   VALUES ('{id}', '{goal}', '{constraints_json}', '{failures_json}', {tier}, '{assign}');"
```

## Contract Lifecycle

1. **active** — Work in progress
2. **completed** — Goal achieved, evidence provided
3. **blocked** — Waiting on dependency or decision
4. **rejected** — Failed failure conditions

## When Inputs Are Unclear

```
BLOCKED: Cannot create contract
Missing: {what's unclear}
Provide: {what's needed}
```

Do NOT proceed without a complete contract. Unclear inputs → blocked state → ask for clarification.

## Integration

- Used by `/orchestrate` before any Tier 2-3 work
- Used by `/build` for complex features
- Referenced in all agent packets and verdicts

## ●:ON_END

```bash
agentdb write-end '{"command":"contract","did":"created contract","contract_id":"<id>","tier":<tier>,"assigned_to":"<role>"}'
```
