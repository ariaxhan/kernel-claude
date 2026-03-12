# Reply Draft: Stanley Context Vault Discussion

---

hey stanley, been digging into aDNA and comparing it with what i've built in kernel-claude. you're thinking about this really well and i have a lot to learn from the math side of your approach. here's where i'm at:

## where kernel-claude is now

we use a hybrid: **files for artifacts, SQLite for state**

**files handle:**
- CLAUDE.md (always loaded, <220 lines enforced by tests)
- skills/ - methodology, loaded on-demand via `skill_load`
- commands/ - workflows, only when invoked
- _meta/research/ - knowledge persistence between sessions
- all git-friendly, human-editable

**SQLite (AgentDB) handles:**
- learnings (failures, patterns, gotchas) - cross-session memory
- context (contracts, checkpoints, verdicts) - work state
- errors - automatic capture

the key insight: **files are for humans to read, SQLite is for agents to query**

## the handoff question (files → SQLite)

based on what i've seen, here are the signals that you need SQLite:

| signal | threshold | why |
|--------|-----------|-----|
| node count | >500 files | grep/glob gets slow |
| query complexity | need joins | files can't do relational |
| concurrent agents | 2+ writing | file locks fail under contention |
| search latency | >500ms typical | FTS5 is 10-100x faster |
| deduplication | same data 3+ places | normalization needs DB |

for aDNA specifically: if you're keeping the obsidian-first approach (which i think is smart for accessibility), the handoff could be:
- **keep triad as files** (who/what/how) - human-facing, git-tracked
- **add SQLite shadow index** - FTS5 over file contents for fast search
- **track session patterns in DB** - which node combinations succeed together
- **aggregate metrics in DB** - token usage, success rates, load times

## token discipline (lost-in-the-middle)

we found from research: LLMs attend most to START and END of context, middle gets deprioritized. 70-80% max context is the sweet spot.

kernel enforces this with tests:
```yaml
CLAUDE.md: <220 lines (always loaded)
commands: <180 lines (when invoked)
agents: <250 lines (when spawned)
critical_content: first 50 lines = role/purpose, last 40 = checklist
```

your <50% per work session target aligns perfectly. the convergence narrowing (Campaign → Phase → Mission → Objective) is exactly right.

## what i want to steal from aDNA

1. **explicit ontology** - we have implicit structure, you have formal entity types. the 14-type base ontology is cleaner than our ad-hoc categories

2. **graph merging** - the graph-product on ontologies for combining context graphs is elegant. we don't have clean composition yet

3. **SITREP handoffs** - structured session reports. we have checkpoints but they're less formalized

## what you might want from kernel

1. **token budget tests** - CI that fails if files exceed limits
2. **quality skill** - Big 5 checks (input validation, edge cases, error handling, duplication, complexity) as loadable methodology
3. **tier system** - explicit rules for when to orchestrate vs execute directly

## proposed graph tracking schema

i'm adding this to AgentDB:

```sql
-- track what loads together successfully
CREATE TABLE context_sessions (
  id TEXT PRIMARY KEY,
  task_type TEXT,  -- bug, feature, refactor
  nodes_loaded TEXT,  -- JSON array of paths
  tokens_used INTEGER,
  success BOOLEAN
);

-- track node performance
CREATE TABLE nodes (
  path TEXT PRIMARY KEY,
  tokens INTEGER,
  access_count INTEGER,
  avg_success_rate REAL
);

-- track relationships
CREATE TABLE edges (
  source_path TEXT,
  target_path TEXT,
  relation TEXT,  -- loads, references, conflicts_with, succeeds_with
  weight REAL
);
```

the goal: **learn which context combinations work** and pre-load intelligently based on task type.

## next steps?

would love to:
1. compare our context loading strategies in detail
2. see how you're doing the graph-product math for merging
3. figure out if there's a clean way to make these interoperable (aDNA file structure + kernel SQLite state)

the anthropic workshop sounds like a perfect forcing function to actually build this rather than just theorize.

---

*drafted 2026-03-12*
