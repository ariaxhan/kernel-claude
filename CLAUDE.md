# KERNEL v5.1.0

tokens: ~200 | vn-native | plugin | agentdb-bus

---

## Ψ:ARCHITECTURE

```
4 orchestration agents + 1 agentdb = zero relay

┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│  main   │  │  plan   │  │  exec   │  │   qa    │
│orchestr │  │architect│  │ surgeon │  │adversary│
└────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘
     │            │            │            │
     └────────────┴─────┬──────┴────────────┘
                        │
                   ┌────▼────┐
                   │ agentdb │
                   │context  │
                   │  _log   │
                   └─────────┘
```

---

## Ψ:POSTURE

```
●relentless|until:code_works,work_done,qa_exhausted
●contract_first|no_work_without_scope
●prove|not:assert
●read|before:edit
●commit|every:working_state
●memory_first|check:_meta/
●lsp_first|goToDefinition,findReferences,hover
```

---

## Ω:AGENTS

| Agent | Tab | Focus | Writes |
|-------|-----|-------|--------|
| orchestrator | main | route, contract, reconcile | directives |
| architect | plan | discover, scope, risk | packets |
| surgeon | exec | minimal diff, commit | checkpoints |
| adversary | qa | break it, prove it | verdicts |

Agent files: `agents/{name}.md`

---

## ●:AGENTDB_BUS

```sql
-- Write (any agent)
INSERT INTO context_log (tab, type, vn, detail, contract, files)
VALUES ('{tab}', '{type}', '{vn}', '{detail}', '{contract_id}', '{files_json}');

-- Read (session start)
SELECT tab, type, vn, detail FROM context_log
WHERE contract = '{id}' OR ts > datetime('now', '-1h')
ORDER BY ts DESC LIMIT 20;
```

| Type | Writer | Reader |
|------|--------|--------|
| directive | main | plan, exec, qa |
| packet | plan, exec | main |
| verdict | qa | main |
| checkpoint | exec | all |

---

## ●:AGENTDB_INIT

```
if !exists(orchestration/agentdb/) → run orchestration/agentdb/init.sh
```

---

## ●:FLOW

```
1. main: CONTRACT → directive → agentdb
2. plan: reads → discovery → packet → agentdb
3. main: reads packet → approves → directive
4. exec: reads → implements → checkpoint → agentdb
5. qa: reads checkpoint → verifies → verdict → agentdb
6. main: reads verdict → SHIP or iterate
```

---

## ●:TIERS

| Tier | Scope | Flow |
|------|-------|------|
| 1 | 1-2 files | main executes |
| 2 | 3-5 files | main → exec |
| 3 | 6+ files | main → plan → exec → qa |

---

## ●:ROUTING

| tier | model | use_for |
|------|-------|---------|
| 1 | ollama | drafts,brainstorm,variations |
| 2 | gemini | web_search,bulk_read,research |
| 3 | sonnet | secondary_impl,synthesis |
| 4 | opus | core_impl,planning,orchestrate |
| 5 | haiku | test_exec,lint,typecheck |

---

## ●:STRUCTURE

| Type | Location | Trigger |
|------|----------|---------|
| Commands | commands/ | /name |
| Skills | skills/ | Skill tool |
| Agents | agents/ | Tab load |

---

## ≠:ANTI

```
●assume_silently|→extract+confirm
●implement_before_investigate|→search_first
●serial_when_parallel|→2+_tasks=parallel
●swallow_errors|→fail_fast
●manual_git|→@git-sync
●work_on_main|→branch/worktree
●guess_APIs|→LSP_goToDefinition
●rediscover_known|→check_memory_first
```

---

## →:LOAD

| Always | On-demand |
|--------|-----------|
| agents/{role}.md | skills/{name}/SKILL.md |

---

*KERNEL = coding OS. LSP-first. Memory-first. Quality gates enforced.*
