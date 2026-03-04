<command id="kernel:tearitapart">
<description>Critical pre-implementation review. Find problems before writing code.</description>

<on_start>
agentdb read-start
</on_start>

<constraint>Run after planning, before implementing.</constraint>
<constraint>If verdict is REVISE or RETHINK, update plan and re-run this command.</constraint>
<constraint>All output clear to non-technical readers.</constraint>
<constraint>Adopt adversarial mindset: ask "how could this break or be abused?" not just "does this work?"</constraint>

<!-- ============================================ -->
<!-- PHASE 0: GATHER CONTEXT                      -->
<!-- ============================================ -->

<pre_review>
  <step>Read the plan/spec/proposal being reviewed.</step>
  <step>Identify all files that will be touched.</step>
  <step>Check git status: are we on a clean branch? Is there a plan file?</step>
  <step>Read relevant existing code to understand current state.</step>
  <step>Check AgentDB for prior contracts/reviews on this feature.</step>
  <recon>
    git status --short
    git log --oneline -5
    agentdb query "SELECT contract_id, content FROM context WHERE type IN ('contract','verdict') ORDER BY ts DESC LIMIT 3"
  </recon>
</pre_review>

<!-- ============================================ -->
<!-- PHASE 1: CRITICAL ISSUES                     -->
<!-- Must fix before proceeding.                  -->
<!-- ============================================ -->

<phase id="critical" priority="1" label="What will definitely break?">
  <category id="requirements">
    <check>Missing requirements: does the plan cover all stated needs?</check>
    <check>Contradictory requirements: do any goals conflict with each other?</check>
    <check>Unstated assumptions: what does the plan assume that isn't written down?</check>
    <check>Wrong problem: is this solving what the user actually asked for, or a related-but-different thing?</check>
  </category>
  <category id="technical">
    <check>Technical impossibility: can this actually be built as described?</check>
    <check>Missing infrastructure: does the plan need services/tools/APIs that don't exist yet?</check>
    <check>Data integrity: can this corrupt, lose, or expose data?</check>
    <check>Race conditions: can concurrent access cause inconsistent state?</check>
    <check>Breaking changes: does this break existing APIs, interfaces, or contracts?</check>
  </category>
  <category id="security">
    <check>Input validation: is all user input validated and sanitized?</check>
    <check>Authentication: are all endpoints properly auth-gated?</check>
    <check>Authorization: can users access only what they should?</check>
    <check>Data exposure: are secrets, PII, or internal details leaking?</check>
    <check>Injection: SQL, XSS, command injection, path traversal?</check>
    <check>Dependency risk: are new dependencies trusted, maintained, and audited?</check>
  </category>
</phase>

<!-- ============================================ -->
<!-- PHASE 2: CONCERNS                            -->
<!-- Should address before or during implementation. -->
<!-- ============================================ -->

<phase id="concerns" priority="2" label="What might cause problems?">
  <category id="edge_cases">
    <check>Empty/null/zero inputs</check>
    <check>Boundary values (max int, empty string, single character)</check>
    <check>Unicode, special characters, emoji in text fields</check>
    <check>Concurrent access patterns</check>
    <check>Network failures, timeouts, partial responses</check>
    <check>Disk full, memory exhaustion, resource limits</check>
  </category>
  <category id="performance">
    <check>N+1 query patterns</check>
    <check>Unbounded data fetches (missing pagination/limits)</check>
    <check>Missing indexes on query patterns</check>
    <check>Expensive operations in hot paths</check>
    <check>Missing caching where reads vastly outnumber writes</check>
    <check>Large payload sizes without streaming or chunking</check>
  </category>
  <category id="maintenance">
    <check>How hard to debug when it fails at 3am?</check>
    <check>How hard to modify when requirements change?</check>
    <check>How hard to delete when no longer needed?</check>
    <check>What dependencies are added? Are they well-maintained?</check>
    <check>Does this increase coupling between modules?</check>
    <check>Does this create a new "you must know about X" for onboarding?</check>
  </category>
  <category id="testing">
    <check>Can this be tested without external services?</check>
    <check>Are there clear test cases implied by the plan?</check>
    <check>What's the minimum viable test coverage?</check>
    <check>Are there integration test requirements?</check>
  </category>
  <category id="error_handling">
    <check>What happens on failure? Is there a fallback?</check>
    <check>Are errors caught, logged, and surfaced (not swallowed)?</check>
    <check>Can the system recover without manual intervention?</check>
    <check>Are error messages actionable (not generic "something went wrong")?</check>
  </category>
</phase>

<!-- ============================================ -->
<!-- PHASE 3: QUESTIONS                           -->
<!-- Unclear items needing answers before building. -->
<!-- ============================================ -->

<phase id="questions" priority="3" label="What's unclear or unspecified?">
  <check>Ambiguous requirements: where could two developers interpret differently?</check>
  <check>Missing context: what domain knowledge is assumed but not documented?</check>
  <check>Unstated preferences: deployment target, performance budget, tech constraints?</check>
  <check>Alternative approaches: was this the simplest solution, or just the first idea?</check>
  <check>Scope boundaries: what's explicitly NOT included?</check>
  <check>User-facing behavior: what does the user see on success? On failure?</check>
</phase>

<!-- ============================================ -->
<!-- PHASE 4: ARCHITECTURE REVIEW                 -->
<!-- ============================================ -->

<phase id="architecture" priority="4" label="Structural soundness">
  <check>Separation of concerns: does each component have one job?</check>
  <check>Coupling: are modules appropriately independent?</check>
  <check>Cohesion: are related things grouped together?</check>
  <check>Interface stability: will the public API need to change soon?</check>
  <check>Pattern consistency: does this follow established patterns in the codebase, or introduce new ones?</check>
  <check>Dependency direction: do dependencies point toward stable abstractions?</check>
  <check>Distributed monolith risk: if using services, can they deploy independently?</check>
  <check>Golden hammer: is a familiar tool being used where a better fit exists?</check>
  <check>Inner platform effect: is this rebuilding something the language/framework already provides?</check>
  <check>Premature abstraction: is there enough evidence for this generalization, or are we guessing?</check>
</phase>

<!-- ============================================ -->
<!-- PHASE 5: SCALE TEST                          -->
<!-- ============================================ -->

<phase id="scale" priority="5" label="Growth behavior">
  <check>10x current usage: does design hold? What's the first bottleneck?</check>
  <check>100x: what breaks? Database, memory, API rate limits, storage?</check>
  <check>1000x: is a fundamental redesign needed, or just horizontal scaling?</check>
  <check>Data growth: what happens when the dataset is 100x larger?</check>
  <check>User growth: what happens with concurrent users at 10x?</check>
  <constraint>If this is a prototype/MVP, note scale concerns but don't block on them. Flag as "address before production."</constraint>
</phase>

<!-- ============================================ -->
<!-- PHASE 6: ROLLBACK / DEPLOYMENT               -->
<!-- ============================================ -->

<phase id="rollback" priority="6" label="Can we undo this?">
  <check>Database migrations: are they reversible?</check>
  <check>Feature flags: can this be disabled without a deploy?</check>
  <check>Data format changes: is there backward compatibility?</check>
  <check>API versioning: do existing clients break?</check>
  <check>Deployment order: does the rollout require coordinated steps?</check>
  <check>Monitoring: will we know if this breaks something in production?</check>
</phase>

<!-- ============================================ -->
<!-- VERDICT                                      -->
<!-- ============================================ -->

<verdict_options>
  <verdict id="PROCEED">Issues minor; plan is sound. List any caveats to address during implementation.</verdict>
  <verdict id="REVISE">Addressable issues found. List specific changes needed. Re-run after revision.</verdict>
  <verdict id="RETHINK">Fundamental problems. The approach needs to change. Explain why and suggest alternative direction.</verdict>
</verdict_options>

<verdict_rules>
  <rule>Any critical issue with no mitigation plan = minimum REVISE.</rule>
  <rule>Multiple critical issues or architectural unsoundness = RETHINK.</rule>
  <rule>Security vulnerability with data exposure risk = minimum REVISE, potentially RETHINK.</rule>
  <rule>Concerns alone (no criticals) can still be PROCEED with caveats.</rule>
  <rule>Unanswered questions in Phase 3 that affect implementation = REVISE until answered.</rule>
</verdict_rules>

<!-- ============================================ -->
<!-- OUTPUT FORMAT                                -->
<!-- ============================================ -->

<output_format>
Save to _meta/reviews/{feature-name}-teardown.md:

# Tear Down: {feature name}
Reviewed: {timestamp}
Plan source: {path to plan file or "conversation"}

## Critical Issues
{must fix before proceeding; each with severity and suggested fix}

## Security Review
{findings from security checks; "None found" if clean}

## Concerns
{should address; grouped by category; each with impact estimate}

## Architecture Assessment
{structural findings; pattern violations; coupling/cohesion notes}

## Questions
{need answers before building; flag which are blockers vs. nice-to-know}

## Scale Analysis
{10x/100x/1000x findings; first bottleneck identified}

## Rollback Assessment
{can this be safely undone? migration reversibility? feature flag plan?}

## Verdict: PROCEED | REVISE | RETHINK
{rationale for verdict}

## If REVISE, required changes:
1. [Specific change with file/component reference]
2. [Specific change]

## If RETHINK, suggested alternative direction:
[Alternative approach with brief rationale]
</output_format>

<!-- ============================================ -->
<!-- GIT PROTOCOL                                 -->
<!-- ============================================ -->

<git_protocol>
  <rule>Save review file to _meta/reviews/ and commit: "review: teardown for {feature}".</rule>
  <rule>If verdict is REVISE or RETHINK, do NOT commit implementation code until re-review passes.</rule>
  <rule>If a plan file exists, reference its path and git hash for traceability.</rule>
  <rule>Push review to remote so other agents/sessions can access it.</rule>
</git_protocol>

<!-- ============================================ -->
<!-- ANTI-PATTERNS                                -->
<!-- ============================================ -->

<anti_patterns priority="critical">
  <!-- Review process anti-patterns -->
  <block action="skip_review">Never skip this step. Every tier 2+ task gets a review.</block>
  <block action="ignore_critical_issues">Critical issues are blockers. No exceptions.</block>
  <block action="fix_it_later">"We'll fix it later" is how tech debt becomes permanent. Address now or document with deadline.</block>
  <block action="proceed_on_rethink">Never proceed with RETHINK verdict. The approach must change.</block>
  <block action="rubber_stamp">Never PROCEED without running every phase. Empty phases = lazy review.</block>

  <!-- Cognitive anti-patterns -->
  <block action="optimism_bias">
    Don't assume the happy path. Ask: "What's the worst realistic failure mode?"
  </block>
  <block action="familiarity_blindness">
    Don't skip review because the pattern "worked before." Context changes everything.
  </block>
  <block action="sunk_cost_attachment">
    Don't soften the verdict because effort was already invested in the plan.
  </block>
  <block action="scope_blindness">
    Don't evaluate features in isolation. Check how they interact with existing system.
  </block>
  <block action="golden_hammer">
    Flag when a tool/pattern is being used because it's familiar, not because it fits.
  </block>

  <!-- Output anti-patterns -->
  <block action="vague_findings">
    Bad: "Performance might be an issue." 
    Good: "Unbounded SELECT * on users table; will degrade past 10k rows without pagination."
  </block>
  <block action="no_suggested_fix">
    Every critical issue and concern should include a suggested mitigation or alternative.
  </block>
  <block action="missing_evidence">
    Claims must reference specific code, files, or architectural facts. No handwaving.
  </block>
  <block action="nitpicking_style">
    Review logic, architecture, security, and correctness. Not formatting, naming preferences, or style unless they cause bugs.
  </block>
  <block action="reviewing_unchanged_code">
    Only review what's in scope. Don't expand to "while we're here" improvements.
  </block>
  <block action="conflating_concern_with_critical">
    Concerns are "should address." Criticals are "must fix." Don't inflate severity.
  </block>
</anti_patterns>

<on_end>
agentdb write-end '{"command":"tearitapart","did":"critical review complete","verdict":"PROCEED|REVISE|RETHINK","review":"_meta/reviews/<feature-name>-teardown.md","critical_count":N,"concern_count":N}'
</on_end>
</command>