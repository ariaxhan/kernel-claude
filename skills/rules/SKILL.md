---
name: rules
description: Core invariants and methodology rules
triggers: rules, invariants, methodology, discipline, protocols
---

# Rules

type: invariant | load: on-demand

---

## Ψ:PHASE_ORDER

PREFLIGHT → DISCOVERY → EXECUTE → VERIFY → LOG

```
PREFLIGHT: check_memory → extract_assumptions → confirm
DISCOVERY: search_patterns → find_examples → read_existing
EXECUTE:   copy_pattern → adapt_minimal → implement
VERIFY:    test → review → check_conventions
LOG:       commit → document → evolve_system
```

---

## ●:INVARIANTS

```
SECURITY:   no_hardcoded_secrets | env_vars_or_vault_only
INTEGRITY:  atomic_commits | one_change_one_commit
STABILITY:  tests_pass_before_merge | breaking_changes_need_migration
DATA:       no_irreversible_ops_without_confirm | rollback_always_possible
TRANSPARENCY: every_decision_logged | every_change_has_reason | no_silent_failures
AUTONOMY:   read_ops_always_permitted | write_ops_pause_if_ambiguous
```

---

## ●:FAIL_FAST

```
IF uncertain: STOP → ASK → WAIT
Assumptions cause debugging.
Silent failures cause pain.
```

### Code Behavior
- validate_inputs_at_entry
- return_early_on_invalid
- specific_error_messages
- never_swallow_errors

### Agent Behavior
- stop_when_blocked
- ask_when_uncertain
- report_failures_immediately
- document_what_went_wrong

### Error Format
```
EVERY ERROR INCLUDES:
1. What went wrong
2. Why (if known)
3. How to fix (if known)
4. Context (file, line, function)
```

---

## ●:COMMIT

```
SMALL > BIG
Each commit = one logical unit
Each commit = independently useful
Each commit = can be reverted cleanly
```

### When
- after_single_function_or_feature
- after_single_bug_fix
- after_config_update
- after_system_evolution
- before_switching_work
- every_3-5_messages_if_coding
- ALWAYS_before_session_end

### Format
```
<type>(<scope>): <subject>

[optional body]
```

### Types
| type | use |
|------|-----|
| feat | new feature |
| fix | bug fix |
| docs | documentation |
| style | formatting |
| refactor | restructure |
| test | tests |
| chore | maintenance |

### Push
- push_at_end_of_logical_unit
- push_before_session_end
- push_after_config_evolution
- never_accumulate_unpushed

---

## ●:MEMORY_FIRST

```
CHECK MEMORY BEFORE ACTING
Answers often already exist.
```

### Before Architecture
```
→ Check _meta/project-notes/decisions.md
→ Ask: "Was this already decided? Why?"
→ If conflict: surface it, don't override
```

### Before Debugging
```
→ Search _meta/project-notes/bugs.md
→ Ask: "Have we fixed this before?"
→ If found: apply solution, verify
→ If new: fix, then ADD to bugs.md
```

### Before Infrastructure
```
→ Check _meta/project-notes/key_facts.md
→ Ask: "Is this documented?"
→ If missing: discover once, ADD to key_facts.md
```

### The Loop
```
WITHOUT MEMORY:
Session N: Discover → Fix → (lost)

WITH MEMORY:
Session 1: Discover → Fix → RECORD
Session N: Check → Apply → Done (5x faster)
```

---

## ●:INVESTIGATE_FIRST

```
NEVER implement first.
1. Find working example (search, grep, docs)
2. Read every line
3. Copy pattern exactly
4. Adapt minimally
```

### Before Writing Code
1. search_codebase for similar implementations
2. if_pattern_exists → copy_exactly, adapt_minimal
3. if_no_pattern → search_external (docs, github, stackoverflow)
4. document_source in commit message

### Verification
- does_pattern_exist_elsewhere?
- is_there_a_library?
- what's_canonical_way?
- am_i_fighting_framework?

---

## ●:ASSUMPTIONS

```
STOP → EXTRACT → CONFIRM → PROCEED
```

### Dimensions
1. **Tech Stack**: languages, versions, frameworks, tools
2. **File Locations**: where code lives, where to create
3. **Naming Conventions**: variables, files, functions
4. **Error Handling**: exceptions vs returns, logging
5. **Test Expectations**: unit/integration/e2e, coverage, location
6. **Dependencies**: existing code, APIs, services

### Session Memory
- record_confirmed_assumptions
- detect_contradictions → flag them
- incremental_checks (don't re-ask confirmed)

---

## ●:CONTEXT_CASCADE

```
Pass outputs only, not full context.
Each phase gets minimal context + specialized task.
```

### Phase Handoffs

**PLAN → IMPLEMENT**
- pass: interface spec, decisions, file locations
- discard: research, alternatives, planning conversation

**IMPLEMENT → REVIEW**
- pass: code diff, test results, spec
- discard: implementation conversation, debugging tangents

**REVIEW → SHIP**
- pass: issues, approval status, commit message
- discard: review conversation, approved code

---

## ●:METHODOLOGY_TRIGGERS

| context | trigger | bank |
|---------|---------|------|
| new feature | implement/add/create/build | PLANNING |
| bug fix | bug/error/fix/broken/fails | DEBUGGING |
| unfamiliar codebase | where is/how does this | DISCOVERY |
| refactor | improve/refactor/optimize | ITERATION |
| before shipping | check/validate/verify | REVIEW |
| complex plan | what could go wrong | TEARITAPART |

---

## ●:SELF_EVOLUTION

```
WHEN YOU LEARN → UPDATE THE SYSTEM
WHEN SOMETHING BREAKS 2x → PATCH THE RULES
WHEN PATTERN EMERGES → ENCODE IT
WHEN CONFIG IS WRONG → FIX IT NOW
```

### Triggers
- find_gotcha → add_to_rules
- solve_problem_certain_way → add_to_patterns
- make_mistake_twice → add_prevention_rule
- discover_infra_info → add_to_session
- find_better_approach → update_agent/skill

### Log Format
```markdown
## {date}
**Context:** {project}
**Type:** pattern | gotcha | fix | optimization | tool
**What:** {description}
**Why:** {rationale}
**Applied to:** {files}
```

### Deletion = Evolution
- remove_stale_rules
- kill_dead_patterns
- evolution_means_pruning

---

## ●:SUBAGENT_OUTPUT

```
EVERY SUBAGENT MUST WRITE TO FILES.
Conversation-only output is LOST.
```

### When Spawning
1. tell_WHERE_to_write (absolute path)
2. tell_WHAT_format (.md, structured)
3. subagent_writes_BEFORE_returning
4. terminal_output_ALSO_required

### Output Locations
| type | path |
|------|------|
| research | _meta/research/{topic}.md |
| analysis | _meta/analysis/{component}.md |
| debug | _meta/debug/{issue}.md |
| plans | _meta/plans/{feature}.md |
| general | _meta/context/ |

---

## ≠:ANTI

```
NEVER:
- assume_intent → challenge instead
- silent_interpretation → surface confusion
- neutral_options → state opinion
- compliance_without_conviction → disagree openly
- implement_before_investigating
- swallow_errors_silently
- skip_memory_check
- accumulate_context (cascade outputs)
- subagent_returns_without_file_write
- commit_10+_files (split them)
- WIP_commits (name what's done)
- end_session_with_uncommitted_work
```

---

## Δ:QUICK_REF

```
PREFLIGHT:
□ memory checked?
□ assumptions extracted?
□ patterns investigated?

EXECUTE:
□ one task = one thing?
□ fail-fast?
□ no silent failures?

COMPLETE:
□ committed?
□ pushed?
□ system evolved?
```
