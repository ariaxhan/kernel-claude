---
name: refactor
description: "Safe refactoring methodology. Behavior-preserving transformations only. Tests green before AND after. Triggers: refactor, clean, simplify, restructure, extract, inline."
allowed-tools: Read, Edit, Bash, Grep, Glob
---

<skill id="refactor">

<purpose>
Refactoring changes structure, not behavior. If behavior changes, it's not refactoring.
Tests must pass before AND after. If tests don't exist, write them FIRST.
The goal is clarity, not cleverness. Three similar lines beats a premature abstraction.
</purpose>

<prerequisite>
AgentDB read-start has run. Check for prior refactor attempts on same code.
</prerequisite>

<reference>
Skill-specific: skills/refactor/reference/refactor-research.md
General: reference/architecture-research.md
</reference>

<core_principles>
1. TESTS FIRST: Run tests before refactoring. Green → refactor → green. Red at any point = stop.
2. SMALL STEPS: One transformation per commit. Easier to revert, easier to review.
3. BEHAVIOR PRESERVATION: Observable behavior unchanged. Internal structure changes only.
4. NO FEATURE WORK: Refactoring is separate from features. Never combine in same commit.
5. SIMPLIFY, DON'T ABSTRACT: Remove complexity before adding abstraction. Delete > refactor > add.
</core_principles>

<common_refactors>
- Extract function: repeated code → named function (only if 3+ repetitions).
- Inline: wrapper that adds nothing → remove the indirection.
- Rename: unclear name → intention-revealing name.
- Move: code in wrong module → move to where it belongs.
- Simplify conditional: nested if/else → guard clauses or early return.
- Remove dead code: unused code → delete (no "just in case").
</common_refactors>

<ai_code_cleanup>
AI-generated code has specific patterns that need cleanup (GitClear 2026):
- Code cloning: 4x more duplication. Extract shared logic.
- Unused constructs: Imports, variables, functions never called. Delete.
- Hardcoded debugging: console.log, print statements left behind. Remove.
- Missing modularization: Long functions doing multiple things. Extract.
- Copy-paste over abstraction: Duplicate blocks that should be functions.

The verification bottleneck: AI generates faster than humans can review.
Refactoring must be reviewable—small, atomic, tested.
</ai_code_cleanup>

<anti_patterns>
<block id="big_bang">Large refactors in one commit. Impossible to review or revert.</block>
<block id="no_tests">Refactoring without test coverage. You can't verify behavior preservation.</block>
<block id="feature_mixing">Adding features during refactor. Separate concerns, separate commits.</block>
<block id="premature_abstraction">Abstracting before you have 3 concrete examples. Wait for patterns to emerge.</block>
<block id="refactor_while_there">"While I'm here, I'll also..." No. Separate contract.</block>
</anti_patterns>

<vibe_coding_crisis>
From research (2026): developers accept AI output without understanding.
60% decline in refactored code—velocity over health.
Copy-paste has overtaken abstraction for first time.

Refactoring is the antidote: systematically improve what AI generates.
But it requires understanding the code. No understanding = no safe refactor.
</vibe_coding_crisis>

<!-- Updated 2026-03-30: AI code review best practices, Claude Code best practices -->
<agentic_refactor_safety>
When refactoring AI-generated code, additional risks apply:

**Phantom abstraction**: AI frequently creates abstractions that look useful but are used
in only one place. Rule: if an abstraction has exactly one call site, inline it. Wait for
a second use case before abstracting.

**Comment drift**: AI comments often describe what the code WAS doing before an edit, not
what it does now. Audit every comment for accuracy during refactor — stale comments are
worse than no comments.

**Parallel agent conflicts**: If multiple agents touched the same file, check git log for
overlapping changes. The "final" file may be a merge artifact, not intentional code.

**Scope creep detection**: Before starting, write down EXACTLY what you're changing.
After finishing, diff your changes against that list. Any extras are scope creep — revert
them and open a separate task.

<!-- Updated 2026-04-19: Anthropic Opus 4.7 migration guide (literal instruction following) -->
**Explicit scope for refactor agents (Opus 4.7)**: Opus 4.7 follows instructions literally — it won't
generalize "rename this function" to all call sites. State full scope explicitly:
- Wrong: "Rename `getUserData` to `fetchUser`"
- Right: "Rename `getUserData` to `fetchUser` in ALL files across the codebase, including imports, tests, and docs"
When spawning a surgeon for a refactor, enumerate the specific files in the contract. Ambiguous scope = partial refactor.
</agentic_refactor_safety>

<!-- Updated 2026-04-25: https://www.infoq.com/news/2026/04/meta-jit-testing-ai-detection/ -->
<jit_refactor_verification>
When the code being refactored lacks test coverage, use JiT (Just-in-Time) testing:
1. Before starting: ask Claude to generate behavioral tests for the current code (what it *does*, not how).
2. Run them: they should pass (green baseline).
3. Refactor.
4. Run them again: must still pass.

These tests are disposable — they exist only to verify behavior preservation during this refactor.
Delete them after if they're not worth keeping. The 4x bug-detection improvement from Meta's JiT research
applies here: generating tests at the point of change catches regressions that pre-existing suites miss.
</jit_refactor_verification>

<!-- Updated 2026-05-06: https://getdx.com/blog/enterprise-ai-refactoring-best-practices/, https://www.augmentcode.com/tools/ai-code-refactoring-tools-tactics-and-best-practices -->
<strategic_refactoring>
**Target high-impact components**: Teams targeting critical high-ROI components see 4x better results than comprehensive refactoring sweeps. Identify by: change frequency, bug density, review time. Start there, not at the edges.

**Atomic transformations under 200 lines**: Keeping each change under 200 lines reduces code review time by 60% and lowers regression risk. Anything larger is a separate task.

**Document before refactoring**: Before starting, create an architectural diagram and document any complex business logic the AI is unlikely to understand. AI frequently mishandles domain-specific constraints and niche patterns. Organizations that prepare this context see 3x faster modernization cycles.

**Success metrics**: A successful refactor measurably reduces cyclomatic complexity by 15-25%. If it doesn't, the refactor didn't simplify — it shuffled. Organizations with systematic pre/post testing see 70% fewer post-deployment issues.

**Embed into regular development**: Refactoring as a periodic "cleanup project" fails from adoption friction. Integrate into normal PR workflow: every merge includes a small cleanup. Don't batch technical debt.

**Rollback procedure required**: Establish a clear rollback path (git SHA or stash) before every refactor. Subtle behavioral changes hide in refactored code. Never merge without the ability to undo.
</strategic_refactoring>

<on_complete>
agentdb write-end '{"skill":"refactor","type":"<extract|inline|rename|simplify>","files_touched":<N>,"tests_status":"green","behavior_changed":false}'

Record what was refactored and verify tests remained green throughout.
</on_complete>

</skill>
