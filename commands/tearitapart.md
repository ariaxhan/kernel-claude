---
name: kernel:tearitapart
description: "Critical pre-implementation review. Find what AI breaks. Verdict: PROCEED, REVISE, or RETHINK. Triggers: review plan, tear apart, critique, analyze."
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob
---

<command id="tearitapart">

<on_start>
```bash
agentdb read-start
```

Load: skills/testing/SKILL.md, skills/security/SKILL.md, skills/architecture/SKILL.md
Reference: _meta/research/ai-code-anti-patterns.md
</on_start>

<mindset>
principle: slow down to speed up
  - 50-70% planning, 30-50% coding
  - 3x faster overall when spec-driven
  - AI code is 1.7x buggier - scrutiny saves time

assume_broken: 40-62% of AI code has security flaws
assume_incomplete: edge cases missing by default
assume_duplicated: AI generates copy-paste readily

goal: find real problems, not generic concerns
  - check against THE BIG 5 (what AI actually breaks)
  - reference skill checklists, not generic questions
  - be specific: file:line, exact concern, fix
</mindset>

<phase id="gather_context">
do:
  - Read the plan/spec being reviewed
  - List all files that will be touched
  - Check git status for uncommitted work
  - Check AgentDB for prior contracts on same area
  - Read _meta/research/ for relevant anti-patterns

output:
  scope: N files
  tier: 1|2|3
  prior_work: contracts, research docs found
</phase>

<phase id="big5" name="THE BIG 5 (AI-SPECIFIC)">
Check against what AI actually breaks (from research):

<check id="input_validation">
- Every API endpoint has Zod/Pydantic schema?
- User input validated BEFORE processing?
- Parameterized queries (no string concat)?
- File uploads validated (size, type, extension)?
skill_ref: skills/security/SKILL.md → input_validation
detection: grep -r "req\.body" | grep -v "parse\|validate\|z\."
</check>

<check id="edge_cases">
- Null/undefined handling present?
- Empty arrays handled (length check before access)?
- Zero-length strings rejected?
- Unicode text processing correct?
- Concurrent access considered?
- Timeout handling for external calls?
skill_ref: skills/testing/SKILL.md → edge_cases_first
template: "What if input is null? Empty? Unicode? Concurrent?"
</check>

<check id="error_handling">
- No empty catch blocks?
- Errors logged with context?
- User-facing messages generic (no stack traces)?
- Background jobs have retry + dead letter?
- Error boundaries at component level?
skill_ref: skills/debug/SKILL.md → error_handling
detection: grep -r "catch.*{}" (empty catch)
</check>

<check id="duplication">
- Same logic repeated in multiple places?
- Copy-paste patterns that should be utilities?
- Similar components with minor differences?
skill_ref: skills/architecture/SKILL.md → modular_boundaries
detection: jscpd or manual scan for repeated blocks
</check>

<check id="complexity">
- Functions > 30 lines?
- Nested ternaries > 2 levels?
- God components doing too much?
- Cyclomatic complexity manageable?
skill_ref: skills/architecture/SKILL.md → design_heuristics
threshold: function < 30 lines, complexity < 10
</check>
</phase>

<phase id="security" name="SECURITY (OWASP)">
check_against: skills/security/SKILL.md → pre_deployment_checklist

<critical>
- [ ] No hardcoded secrets (API keys, passwords)
- [ ] Auth tokens in httpOnly cookies (not localStorage)
- [ ] Row Level Security enabled (if Supabase)
- [ ] Rate limiting on all endpoints
- [ ] HTTPS enforced
</critical>

<injection>
- [ ] SQL: parameterized queries only
- [ ] XSS: user content sanitized (DOMPurify)
- [ ] CSRF: tokens on state-changing ops
- [ ] Command: no user input in shell commands
</injection>

skill_ref: skills/security/SKILL.md → owasp_awareness
</phase>

<phase id="testing" name="TESTING COVERAGE">
check_against: skills/testing/SKILL.md → anti_patterns

<verify>
- Tests exist BEFORE implementation?
- Edge cases covered (not just happy path)?
- Assertions specific (not toBeTruthy)?
- Mocks at boundaries only (not internal functions)?
- Regression tests for any bug fix?
</verify>

<red_flags>
- "Will add tests later" (you won't)
- 100% coverage with weak assertions
- Tests that pass with buggy code
- No error path testing
</red_flags>

skill_ref: skills/testing/SKILL.md → core_principles
</phase>

<phase id="architecture">
check_against: skills/architecture/SKILL.md

<verify>
- Follows existing patterns in codebase?
- Interface stability (changing interfaces breaks everything)?
- Modular boundaries (each module = one reason to change)?
- Dependency direction (core doesn't know edges)?
</verify>

<ai_specific>
- AI amplifies existing patterns - good or bad
- 30%+ defect risk when AI applied to unhealthy code
- Check code health BEFORE adding AI code
</ai_specific>

skill_ref: skills/architecture/SKILL.md → ai_code_health_nexus
</phase>

<velocity_calibration>
Do NOT overestimate effort. Use research baselines:

task_speed_gains:
  boilerplate: 10x (minimal review needed)
  config_docker: 8-10x (mostly correct)
  api_integration: 3-5x (check auth/errors)
  domain_logic: 2-5x (scrutinize edge cases)
  architecture: 1x (human-led, AI assists)

timeline_baselines:  # greenfield + clear requirements
  simple_crud: 2-3 days
  mvp_with_payment: 5-7 days
  saas_custom: 10-14 days
  fullstack_complex: 3-4 weeks

calibration:
  - If task is boilerplate → low scrutiny, fast proceed
  - If task is domain logic → high scrutiny, edge case focus
  - If task is architecture → human-led, don't rush
  - If requirements unclear → fix that first (no speed gain)

reference: _meta/research/ai-code-anti-patterns.md → velocity_calibration
</velocity_calibration>

<verdict>
<option id="PROCEED">
criteria:
  - No Big 5 violations
  - Security checklist passes
  - Tests defined (or trivial change)
  - Architecture follows patterns
output: "PROCEED with caveats: [list minor items]"
</option>

<option id="REVISE">
criteria:
  - 1-2 Big 5 violations (fixable)
  - Missing but addressable security items
  - Tests need edge cases
  - Minor architecture concerns
output: "REVISE: [specific changes with file:line]"
</option>

<option id="RETHINK">
criteria:
  - 3+ Big 5 violations
  - Fundamental security gaps
  - No tests and complex logic
  - Architecture breaks existing patterns
  - Requirements still unclear
output: "RETHINK: [why fundamentally flawed] → [alternative approach]"
</option>
</verdict>

<output_format>
Save to `_meta/reviews/{feature}-teardown.md`:

```yaml
# Tear Down: {feature}
reviewed: {timestamp}
tier: {1|2|3}
scope: {N files}

## Big 5 Check
input_validation: pass|fail|n/a - {details}
edge_cases: pass|fail|n/a - {details}
error_handling: pass|fail|n/a - {details}
duplication: pass|fail|n/a - {details}
complexity: pass|fail|n/a - {details}

## Security
{checklist results}

## Testing
{coverage assessment}

## Architecture
{pattern compliance}

## Verdict: PROCEED | REVISE | RETHINK
{reasoning}

## Action Items
1. {specific fix with file:line}
2. {specific fix with file:line}
```
</output_format>

<on_complete>
```bash
agentdb write-end '{"command":"tearitapart","verdict":"X","big5_violations":N,"security_issues":N,"action_items":N}'
```
</on_complete>

</command>
