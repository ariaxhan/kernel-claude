---
name: build
description: "Solution exploration and implementation. Generate 2-3 approaches, pick simplest. Never implement first idea. Triggers: build, implement, create, feature, add."
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task
---

# BUILD SKILL

**Prerequisite**: AgentDB read-start has already run. Tier classification done via /kernel:ingest.

**Reference**: skills/build/reference/build-research.md

---

## STEPS

### 1. GOAL EXTRACTION

```
GOAL: [What are we building?]
CONSTRAINTS: [Limitations, requirements, must-haves]
INPUTS: [What do we have to work with?]
OUTPUTS: [What should exist when done?]
DONE-WHEN: [How do we know it's complete?]
```

(gate: all 5 fields filled before continuing)

For ambiguous features, use interview pattern: `"I want to build [X]. Interview me using AskUserQuestion. Ask about implementation, UI/UX, edge cases, tradeoffs. Write spec to _meta/plans/."`
Start fresh session after spec is written — implementation gets clean context.

---

### 2. RESEARCH CACHE CHECK

1. `ls _meta/research/` for topic matches
2. Read frontmatter date + ttl
3. If `today - date < ttl`: use cached result, skip web search
4. If stale or missing: search, write result with frontmatter

```yaml
---
query: "{original search query}"
date: "YYYY-MM-DD"
ttl: 7  # days — anti-patterns/gotchas=7, framework docs=30, package versions=3, architecture=30
domain: "{tech domain}"
---
```

(gate: cache checked — either hit confirmed or new entry written)

**Rule**: Research without verification is theory fiction. (LRN-F11)
Cache finding → build 10-line proof before committing to it across the codebase.
Always check agentdb for learnings after cache check — learnings are never cached.

---

### 3. ASSUMPTION VERIFICATION

Confirm (not guess) max 6 per category:
- Tech stack (languages, frameworks, versions)
- File locations (where code lives, where to create)
- Naming conventions (casing, patterns in existing code)
- Error handling approach (existing patterns)
- Test expectations (framework, coverage requirements)
- Dependencies (approved, version constraints)

(gate: assumptions documented before implementation)

---

### 4. SOLUTION EXPLORATION

**Rule: Generate 2-3 approaches minimum. Never implement first idea.**

Per solution, document:
- Approach name and brief description
- Code required (~lines)
- Dependencies (name, version, weekly downloads)
- Pros, cons, complexity (simple/medium/complex)

Evaluation criteria (ordered):
1. **Minimal code**: fewest lines, simplest logic
2. **Battle-tested package**: most downloads = most reliable
3. **Reliability**: fewer edge cases, fewer bugs
4. **Maintenance**: active, clear docs
5. **Performance**: only if bottleneck exists

Write chosen solution + rejected alternatives to `_meta/plans/{feature}.md`.
Plans under 50 lines. Longer = overthinking.
**Skip plan if diff can be described in one sentence** — planning overhead only justified for multi-file or uncertain approaches.

(gate: ≥2 approaches compared, one chosen with rationale)

---

### 5. EXECUTION

**BEFORE** each step: review research doc, check if fewer lines possible.
**DURING**: use researched package, minimal changes, follow existing patterns, one commit per logical unit.
**AFTER**: verify works, count lines (can reduce?), commit, update plan.

**If tier 2+**: You are the surgeon. Follow contract scope exactly.

Context discipline:
- State DONE-WHEN criteria at session START, not end
- Compact at ~60% context usage — degradation begins at 20-40% fill; don't wait for signals
- Scope sessions by task, not time — one session = one feature or one bug
- Two-failure reset: same mistake twice → `/clear` and restart with refined prompt
- Plan Mode for features with >5 decision points: plan first, then implement in a fresh session. A feature with 20 decision points at 80% per-decision accuracy has a 1.2% chance all land correctly without an upfront plan. <!-- Updated 2026-06-04: https://code.claude.com/docs/en/best-practices -->
- Explore-Plan-Act loop: Phase 1 (read-only codebase exploration) → Phase 2 (propose strategy, confirm) → Phase 3 (full tool access, implement, run tests, iterate). Canonical three-phase sequence for non-trivial features. <!-- Updated 2026-06-06: https://code.claude.com/docs/en/best-practices -->
- Context engineering: the field has moved beyond "prompt engineering" — optimize everything Claude sees: system prompt, tools list, examples, conversation history, CLAUDE.md. The full context is the prompt. <!-- Updated 2026-06-08: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview -->
- Tool sprawl: each tool added is context overhead. Keep the active set small and high-signal. More than ~8-10 tools degrades context quality and Claude's tool-selection accuracy. <!-- Updated 2026-06-08: https://code.claude.com/docs/en/best-practices -->
- Hooks vs CLAUDE.md: behaviors that must fire every time → hook (deterministic, 100%); guidance Claude should consider → CLAUDE.md (~80% adherence). Never rely on CLAUDE.md for safety-critical enforcement. <!-- Updated 2026-06-09: https://code.claude.com/docs/en/best-practices -->
- Subagent isolation for exploration: use subagents for investigation/research tasks to avoid polluting the main session context. Only the summary returns — keeps the working context clean. <!-- Updated 2026-06-09: https://smartscope.blog/en/generative-ai/claude/claude-code-best-practices-advanced-2026/ -->

(gate: each logical unit committed before moving to next)

---

### 6. VALIDATION

Automated (run what exists):
- Tests: `npm test` / `pytest` / `cargo test` / `go test`
- Lint: `eslint` / `ruff` / `clippy`
- Types: `tsc --noEmit` / `mypy`

Manual: walk through done-when criteria. Document how verified.
Edge cases (at least 3): empty/null, boundary, error/failure path.

(gate: all automated checks green, ≥3 edge cases covered)

---

### 7. FAILURE HANDLING

1. STOP immediately
2. Check research doc for this error
3. If documented fix exists, apply it
4. If not: question whether simpler solution was missed
5. Rollback to last known good: `git checkout` or `git stash`
6. Re-evaluate: still simplest solution?
7. If solution feels complex: stop, search for simpler package

---

### 8. COMPLETION

Report: feature name, branch, files changed, validation results, next steps.

```bash
agentdb write-end '{"skill":"build","feature":"X","files":["Y"],"approach":"Z"}'
```

---

## FLAGS

- `--quick`: skip confirmations, minimal prompts
- `--plan-only`: stop after planning
- `--resume`: continue in-progress work
- `--validate-only`: skip to validation
