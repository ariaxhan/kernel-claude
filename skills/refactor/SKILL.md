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
For deeper context, read reference/refactor-research.md (vibe coding crisis, verification bottleneck).
</prerequisite>

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

<on_complete>
agentdb write-end '{"skill":"refactor","type":"<extract|inline|rename|simplify>","files_touched":<N>,"tests_status":"green","behavior_changed":false}'

Record what was refactored and verify tests remained green throughout.
</on_complete>

</skill>
