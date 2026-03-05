<command id="kernel:handoff">
<description>Generate token-optimized context handoff brief for session/system continuation.</description>
<allowed_tools>Read, Glob, Bash</allowed_tools>

<!-- Load before generating: skills/context/SKILL.md -->
<!-- Reference: skills/context/reference/context-research.md -->

<on_start>
agentdb read-start
</on_start>

<trigger terms="create a handoff,context handoff,prepare handoff,pause and resume,session summary,continue later"/>

<!-- ============================================ -->
<!-- PHASE 1: EXTRACT STATE                       -->
<!-- ============================================ -->

<extract>
  <field id="goal">What is the user trying to achieve? Include success criteria if defined.</field>
  <field id="position">Where are we in the workflow? What phase/step/milestone?</field>
  <field id="decisions">Choices made and why. Include rejected alternatives with rejection reason.</field>
  <field id="open_threads">Unfinished or unresolved items. Flag blockers vs. nice-to-haves.</field>
  <field id="artifacts">Files, code, frameworks created (with full paths and brief purpose).</field>
  <field id="context">Critical background needed to continue. Domain knowledge, constraints, user preferences.</field>
  <field id="warnings">Failed approaches, pitfalls to avoid, dead ends explored.</field>
  <field id="dependencies">External services, APIs, libraries, credentials, environment requirements.</field>
  <field id="mental_model">Key abstractions, naming conventions, or architectural patterns established this session.</field>
</extract>

<!-- ============================================ -->
<!-- PHASE 2: GATHER EVIDENCE                     -->
<!-- ============================================ -->

<recon>
<!-- Git state -->
git status --short
git diff --stat
git log --oneline -10
git branch --list
git stash list

<!-- Recent file activity -->
find . -type f -mmin -120 | grep -v node_modules | grep -v .git | grep -v __pycache__

<!-- Check for uncommitted work -->
git diff --name-only
git diff --cached --name-only

<!-- Check AgentDB for active contracts -->
agentdb query "SELECT contract_id, type, content FROM context WHERE type IN ('contract','checkpoint','verdict') ORDER BY ts DESC LIMIT 5"
</recon>

<!-- ============================================ -->
<!-- PHASE 3: GIT HYGIENE                         -->
<!-- ============================================ -->

<git_protocol>
  <rule>Before generating handoff: check for uncommitted changes.</rule>
  <rule>If uncommitted changes exist: commit with message "wip: checkpoint before handoff" or stage and stash.</rule>
  <rule>If on a feature branch: note branch name, base branch, and merge status in handoff.</rule>
  <rule>If there are stashed changes: document stash contents in handoff.</rule>
  <rule>Push current branch to remote so receiving session can access it.</rule>
  <rule>Never leave dirty working tree undocumented in handoff.</rule>
</git_protocol>

<!-- ============================================ -->
<!-- PHASE 4: GENERATE HANDOFF                    -->
<!-- ============================================ -->

<output_format>
## CONTEXT HANDOFF
Generated: {timestamp}
Session duration: {approximate}

**Summary**: [One sentence capturing the entire situation, outcome, and state]

**Goal**: [What user is trying to achieve, including success criteria]

**Current state**: [Where things stand now; concrete, specific, verifiable]

**Branch**: [Current git branch, base branch, clean/dirty status]

**Decisions made**:
- [Decision: choice + rationale + what was rejected and why]

**Artifacts created**:
- [path/to/file: brief purpose, current state (complete/partial/stub)]

**Architecture / mental model**:
- [Key abstractions, patterns, naming conventions to preserve]

**Dependencies**:
- [External service/lib/tool: version, purpose, any gotchas]

**Open threads**:
- [BLOCKER: item that must resolve before continuing]
- [TODO: item that should happen next]
- [QUESTION: unresolved question needing user input]

**Next steps** (ordered by priority):
1. [Specific, actionable, includes which files to touch]
2. [Second priority action]
3. [Third priority action]

**Context essentials**:
- [Only what's needed to act; no redundancy with above sections]

**Warnings**:
- [Failed approach: what was tried, why it failed, what to do instead]

**Active AgentDB contracts**:
- [Contract ID: status, last checkpoint summary]

**File paths to read first**:
- [Key file 1: why it matters]
- [Key file 2: why it matters]

**Uncommitted / stashed work**:
- [Description of any WIP not yet committed]

**Handoff saved to**: _meta/handoffs/{feature}-{date}.md

**Continuation prompt**:
> /kernel:ingest [goal statement]. [Current position]. [Immediate next action]. Read _meta/handoffs/{filename} for full context.
</output_format>

<!-- ============================================ -->
<!-- CONSTRAINTS                                  -->
<!-- ============================================ -->

<constraints>
  <rule>One sentence max per bullet.</rule>
  <rule>No redundancy between sections.</rule>
  <rule>Omit empty sections entirely.</rule>
  <rule>Actionable over descriptive: "Created 6 banks in kernel/banks/" not "Made progress on banks".</rule>
  <rule>Concrete over vague: include paths, counts, specific names.</rule>
  <rule>All output clear to non-technical readers. Zero code knowledge required.</rule>
  <rule>Decisions section must include rejected alternatives (prevents re-exploring dead ends).</rule>
  <rule>Warnings section must include what was tried, not just what to avoid.</rule>
  <rule>Next steps must reference specific files or commands, not abstract goals.</rule>
  <rule>If session touched more than 5 files, include a file manifest with status (new/modified/deleted).</rule>
</constraints>

<!-- ============================================ -->
<!-- CONTINUATION PROMPT SPEC                     -->
<!-- ============================================ -->

<continuation_prompt_spec>
  <rule>2-3 sentences max.</rule>
  <rule>Must contain: goal, current position, immediate next action.</rule>
  <rule>Must be prefaced with /kernel:ingest.</rule>
  <rule>Must reference the handoff file path for full context.</rule>
  <rule>Self-contained: new instance can act on it with zero prior context.</rule>
  <rule>Never assume the receiving agent has any memory of this session.</rule>
  <rule>Include branch name if work is on a non-main branch.</rule>
</continuation_prompt_spec>

<!-- ============================================ -->
<!-- VALIDATION                                   -->
<!-- ============================================ -->

<validation>
  <check>Could a new AI instance continue productively with ONLY this brief?</check>
  <check>Are there gaps that would cause confusion or re-exploration of dead ends?</check>
  <check>Is the continuation prompt self-contained?</check>
  <check>Does the git state section accurately reflect current repo state?</check>
  <check>Are all uncommitted changes documented or committed?</check>
  <check>Does decisions section include rejected alternatives?</check>
  <check>Does warnings section explain WHY approaches failed, not just WHAT failed?</check>
  <check>Are file paths absolute or relative-to-root (not ambiguous)?</check>
  <check>If AgentDB has active contracts, are they referenced?</check>
  <on_gap>Add missing context or flag as [NEEDS CLARIFICATION: ...]</on_gap>
</validation>

<!-- ============================================ -->
<!-- ANTI-PATTERNS                                -->
<!-- ============================================ -->

<anti_patterns priority="critical">
  <block action="vague_state_description">
    Bad: "Made progress on the feature." 
    Good: "Implemented auth middleware in src/middleware/auth.ts; token validation works, role-based access not started."
  </block>
  <block action="missing_rejection_rationale">
    Bad: "Decided to use PostgreSQL." 
    Good: "Decided PostgreSQL over SQLite (need concurrent writes) and MongoDB (relational schema fits better)."
  </block>
  <block action="orphaned_wip">
    Never leave uncommitted work undocumented. Commit, stash, or describe explicitly.
  </block>
  <block action="abstract_next_steps">
    Bad: "Continue working on the API." 
    Good: "Add rate limiting to src/routes/api.ts; use express-rate-limit; test with curl."
  </block>
  <block action="redundant_sections">
    If info appears in Decisions, don't repeat in Context Essentials.
  </block>
  <block action="assuming_shared_memory">
    The receiving agent knows NOTHING. Every critical fact must be in the handoff.
  </block>
  <block action="skipping_git_state">
    Always document branch, uncommitted changes, stashes, remote sync status.
  </block>
  <block action="no_failure_context">
    Dead ends without explanation guarantee re-exploration. Always say WHY it failed.
  </block>
  <block action="handoff_without_file">
    Always save to _meta/handoffs/. Never deliver handoff only in conversation.
  </block>
  <block action="oversized_handoff">
    If handoff exceeds 500 words, compress. The receiving agent has limited context too.
  </block>
  <block action="missing_dependency_versions">
    "Uses Redis" is insufficient. "Uses Redis 7.2, connection string in .env, required for session store" is correct.
  </block>
  <block action="no_mental_model_transfer">
    If session established naming conventions, architectural patterns, or key abstractions, these must transfer.
  </block>
</anti_patterns>

<!-- ============================================ -->
<!-- DELIVERY                                     -->
<!-- ============================================ -->

<delivery>
  <rule>Present in code block for copy-paste.</rule>
  <rule>Save to _meta/handoffs/{feature}-{YYYY-MM-DD}.md as file.</rule>
  <rule>Provide user the file path.</rule>
  <rule>If git is available, commit the handoff file: "docs: context handoff for {feature}".</rule>
  <rule>Push to remote if possible.</rule>
</delivery>

<on_end>
agentdb write-end '{"command":"handoff","did":"generated context handoff brief","saved_to":"<path>","git_state":"clean|dirty|committed","branch":"<branch>"}'
</on_end>
</command>