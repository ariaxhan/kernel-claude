<!-- ============================================ -->
<!-- KERNEL INVARIANTS                            -->
<!-- Non-negotiable contracts. Always loaded.     -->
<!-- ============================================ -->

<!-- Heuristics, conventions, and extended rules moved to _meta/reference/ -->
<!-- Load on demand: heuristics.md, conventions.md, context-discipline.md, output-quality.md -->

<rule id="invariants" type="invariant" load="always">

## Security

<invariant id="no_hardcoded_secrets">
No hardcoded secrets (keys, tokens, credentials). Environment variables or secure vaults only.
**On violation:** Block commit.
</invariant>

<invariant id="no_data_exposure">
No PII, internal URLs, or debug info in user-facing output.
**On violation:** Revert.
</invariant>

---

## Integrity

<invariant id="atomic_commits">
One logical change = one commit. Never mix feature + refactor + fix.
</invariant>

<invariant id="tests_before_merge">
Tests pass before merge. Breaking changes require migration guides. No exceptions.
</invariant>

---

## Data Safety

<invariant id="no_irreversible_ops">
No irreversible operations (delete, drop, truncate, overwrite) without explicit user confirmation.
Rollback must always be possible.

**On ambiguous:** Pause. Ask user.
</invariant>

---

## Transparency

<invariant id="no_silent_failures">
Every decision logged. Every change has a reason. No swallowed errors.
If something fails, surface it. Never hide.
</invariant>

<invariant id="read_only_default">
Read-only operations always permitted.
Write operations: pause if ambiguous intent.
</invariant>

---

## Attribution

<invariant id="no_ai_attribution">
No Co-Authored-By trailers. No "Generated with Claude Code." No tool signatures in commits.
Commits attributed to human author only.
</invariant>

---

## Parallel Execution

<invariant id="parallel_first">
Serial execution is the exception. Parallel is the default.

**Detection:** Before taking action, ask: "Can this be split into 2+ independent steps?"
- If yes → spawn parallel agents with separate contracts
- If no → execute directly

**Pattern:** Single message with multiple Task calls. All agents write files directly. Wait for all agents. Merge/review results.

**Exceptions:**
- Task is single file edit or single command
- User explicitly says "just do X" or "quick"
- Steps are dependent (output of A feeds into B)
</invariant>

---

## Enforcement

- Pre-commit hooks validate: no secrets, commit message format, test status
- Agents report violations immediately via AgentDB
- User must explicitly approve any invariant override

</rule>
