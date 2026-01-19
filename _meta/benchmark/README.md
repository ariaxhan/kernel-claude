# Benchmark System

**Always-on performance tracking.** Every session generates data to improve the system.

---

## How It Works

1. **Automatic** - Runs silently, no opt-in
2. **Quantitative** - Tokens, time, errors, agent spawns
3. **Qualitative** - Agent reflections at checkpoints
4. **Exportable** - JSON + Markdown for comparison

---

## Files

| File | Purpose | Update Frequency |
|------|---------|------------------|
| `metrics.jsonl` | Append-only metrics | Every session |
| `journal.md` | Agent reflections | At checkpoints |
| `summary.md` | Human-readable rollup | Weekly/on-demand |

---

## Metrics Captured

### Per Session
```json
{
  "session_id": "uuid",
  "started": "ISO timestamp",
  "ended": "ISO timestamp",
  "task": "what was attempted",
  "outcome": "success | partial | failed",
  "tokens": { "input": 0, "output": 0 },
  "tool_calls": 0,
  "agent_spawns": ["agent-name"],
  "errors": 0,
  "retries": 0,
  "commits": 0,
  "tests_passed": 0,
  "tests_failed": 0,
  "self_evolution_events": 0
}
```

### Checkpoints (trigger journal)
- After `/build` planning
- After first implementation attempt
- After any debugging cycle
- After `/validate` completes
- After `/ship` completes
- On session end

---

## Journal Format

```markdown
## [timestamp] - Checkpoint: [name]

**Task:** What I was doing
**Outcome:** success | partial | failed
**Confidence:** 1-5
**Uncertainty:** What I wasn't sure about
**Discovery:** What I learned
**Friction:** What slowed me down
**Would change:** What I'd do differently
```

---

## Using Benchmark Data

### Self-Improvement
System reads past data to:
- Find repeated failures → add rules
- Find slow operations → optimize
- Detect low-confidence areas → improve docs

### Comparison
Export to compare:
- Same config over time (am I improving?)
- Different configs on same task
- Different models with same config

### Pruning
When `metrics.jsonl` > 1000 entries:
1. Summarize to `summary.md`
2. Archive old entries to `benchmark/archive/`
3. Keep recent 100

---

## Integration

Built into:
- `/build` (checkpoints at each phase)
- `/validate` (test results)
- `/ship` (completion)
- Session protocol (start/end)
- Self-evolution (counts updates)

No extra commands. It just works.
