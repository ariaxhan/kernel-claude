<!-- ============================================ -->
<!-- KERNEL INVARIANTS                            -->
<!-- Non-negotiable contracts. Always loaded.     -->
<!-- ============================================ -->

<!-- Heuristics, conventions, and extended rules: _meta/reference/ -->
<!-- Load on demand: heuristics.md, conventions.md, context-discipline.md, output-quality.md -->

<!-- Skills (methodology): skills/*/SKILL.md. Reference docs: skills/*/reference/*-research.md -->
<!-- Load relevant skill before acting. Agents must reference skills and research when applicable. -->

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

<!-- ============================================ -->
<!-- FRONTMATTER PROTECTION                       -->
<!-- Critical: Breaking frontmatter breaks plugin -->
<!-- ============================================ -->

<rule id="frontmatter_protection" type="invariant" load="always">

## Frontmatter Format (Commands, Skills, Agents)

<invariant id="exact_frontmatter">
YAML frontmatter MUST be exact. Claude Code plugin fails silently on malformed frontmatter.

**Required format:**
```yaml
---
name: kernel:{name}
description: "{description with triggers}"
user-invocable: true|false
allowed-tools: Tool1, Tool2, ...
---
```

**On edit:** Preserve frontmatter EXACTLY as-is. Never:
- Change field order
- Add/remove fields
- Modify quotes or formatting
- Add blank lines within frontmatter
</invariant>

<invariant id="frontmatter_validation">
Before committing any command/skill/agent edit:
1. Check frontmatter starts at line 1 with `---`
2. Check frontmatter ends with `---` before content
3. Verify `name:` field matches filename pattern
4. Verify `description:` is quoted string

**On violation:** Block commit. Broken frontmatter = broken plugin.
</invariant>

## Learning (from previous session failure)

Previous session broke agents by editing frontmatter incorrectly.
Result: Claude Code couldn't load plugins, silent failure.

**Rule:** When trimming files for token budget, preserve frontmatter byte-for-byte.
Only modify content AFTER the closing `---`.

</rule>
