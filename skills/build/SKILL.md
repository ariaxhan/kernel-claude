---
name: build
description: "Solution exploration and implementation. Generate 2-3 approaches, pick simplest. Never implement first idea. Triggers: build, implement, create, feature, add."
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task
---

# PURPOSE

Minimal code through maximum research. The best code is code you don't write.
Your first solution is never right. Explore, compare, choose simplest.

**Prerequisite**: AgentDB read-start has already run. Tier classification done via /kernel:ingest.

**Reference**: skills/build/reference/build-research.md

---

# GOAL EXTRACTION

```
GOAL: [What are we building?]
CONSTRAINTS: [Limitations, requirements, must-haves]
INPUTS: [What do we have to work with?]
OUTPUTS: [What should exist when done?]
DONE-WHEN: [How do we know it's complete?]
```

<!-- Updated 2026-04-10: https://code.claude.com/docs/en/best-practices -->
**Interview pattern for large features**: For ambiguous or complex features, instead of
filling in the template manually, prompt Claude to interview you:
> "I want to build [brief description]. Interview me using the AskUserQuestion tool.
> Ask about technical implementation, UI/UX, edge cases, and tradeoffs. Don't ask
> obvious questions — dig into the hard parts. Then write a complete spec to _meta/plans/."

Start a fresh session after the spec is written. The implementation session gets clean context
focused entirely on execution, with a written spec to reference throughout.

---

# SOLUTION EXPLORATION (NEVER SKIP)

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

**Rules:**
- Write chosen solution + rejected alternatives to `_meta/plans/{feature}.md`
- Plans under 50 lines. Longer = overthinking.
- **Planning heuristic**: If you can describe the complete diff in one sentence, skip the plan and implement directly. Planning overhead is only justified for multi-file changes or uncertain approaches.
<!-- Updated 2026-03-28: https://code.claude.com/docs/en/best-practices -->

---

# RESEARCH CACHE

**RULE: Research without verification is theory fiction.** (LRN-F11)
Every research finding must be verified with a minimal test before it drives implementation.
Cached research is a starting point, not a conclusion. If the cache says "use approach X",
build a 10-line proof before committing to X across your codebase.

Before web search, check for cached research in `_meta/research/`.

**Cache format** — research files use frontmatter:
```yaml
---
query: "{original search query}"
date: "YYYY-MM-DD"
ttl: 7  # days
domain: "{tech domain}"
---
```

**TTL rules:**
- Anti-patterns/gotchas: 7 days (change slowly)
- Framework docs/APIs: 30 days (stable references)
- Package versions/compatibility: 3 days (changes fast)
- Architecture patterns: 30 days (stable)

**Cache check protocol:**
1. `ls _meta/research/` for topic matches
2. Read frontmatter date + ttl
3. If `today - date < ttl`: use cached result, skip web search
4. If stale or missing: search, then write result with frontmatter

**Cold start**: No behavior change when cache empty — search normally, create cache entry.

**Note**: Cache hits still check agentdb for learnings. Learnings are never cached — always fresh.

---

# ASSUMPTION VERIFICATION

Confirm (not guess) max 6 per category:
- Tech stack (languages, frameworks, versions)
- File locations (where code lives, where to create)
- Naming conventions (casing, patterns in existing code)
- Error handling approach (existing patterns)
- Test expectations (framework, coverage requirements)
- Dependencies (approved, version constraints)

---

# EXECUTION

**BEFORE** each step: review research doc, check if fewer lines possible.
**DURING**: use researched package, minimal changes, follow existing patterns, one commit per logical unit.
**AFTER**: verify works, count lines (can reduce?), commit, update plan.

**If tier 2+**: You are the surgeon. Follow contract scope exactly.

---

# VALIDATION

Automated (run what exists):
- Tests: `npm test` / `pytest` / `cargo test` / `go test`
- Lint: `eslint` / `ruff` / `clippy`
- Types: `tsc --noEmit` / `mypy`

Manual: walk through done-when criteria. Document how verified.

Edge cases (at least 3): empty/null, boundary, error/failure path.

---

# FAILURE HANDLING

1. STOP immediately
2. Check research doc for this error
3. If documented fix exists, apply it
4. If not: question whether simpler solution was missed
5. Rollback to last known good: `git checkout` or `git stash`
6. Re-evaluate: still simplest solution?
7. If solution feels complex: stop, search for simpler package

---

# COMPLETION

Report: feature name, branch, files changed, validation results, next steps.

```bash
agentdb write-end '{"skill":"build","feature":"X","files":["Y"],"approach":"Z"}'
```

---

# CONTEXT ENGINEERING

<!-- Updated 2026-04-25: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview, https://smartscope.blog/en/generative-ai/claude/claude-code-best-practices-advanced-2026/ -->
The field has shifted from "prompt engineering" to **context engineering**: optimizing *everything* the model sees, not just the instruction.

The context payload = system prompt + tools + examples + conversation history + available files.
Each element is a lever. Optimize all of them, not just the user message.

**Long context query position (20k+ tokens)**: When the context payload exceeds ~20K tokens
(multi-document inputs, large codebases), place your query and instructions at the END, after all
document content. Anthropic data: this improves response quality by up to 30%. Structure:
```xml
<documents>
  <document index="1"><document_content>{{CONTENT}}</document_content></document>
  ...
</documents>
[Your query and instructions HERE — after all documents, not before]
```
<!-- Updated 2026-05-04: https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/overview -->

**Explore-Plan-Act loop** (three permission-escalating phases):
1. **Explore** (read-only): Find relevant files, understand architecture, map dependencies. No writes.
2. **Plan**: Propose strategy. Human reviews and adjusts before implementation begins.
3. **Act** (full tools): Implement plan, run tests, iterate on failures.

Anthropic internal data: unguided attempts (Act only, skip Explore+Plan) succeed ~33% of the time.
Structured Explore-Plan-Act: ~80%+. The phases aren't ceremony — they're the multiplier.

**CLAUDE.md hygiene**: Reference separate files for large domain docs. Inlining >1KB into CLAUDE.md
consumes token budget before work starts. Use `_meta/reference/` and load on demand.

<!-- Updated 2026-05-10: https://smart-webtech.com/blog/claude-code-workflows-and-best-practices/, https://discuss.huggingface.co/t/10-essential-claude-code-best-practices-you-need-to-know/174731 -->
**Context7 for versioned library docs**: Use the Context7 MCP plugin instead of asking Claude to web-search documentation. Context7 indexes library docs at a precise version and serves exactly the page Claude needs — no hallucinated APIs, no stale docs from wrong versions. Install once, reference with `use context7` in prompts when working with specific library versions.

---

# AGENTIC BUILD PATTERNS

<!-- Updated 2026-04-27: https://marmelab.com/blog/2026/04/24/claude-code-tips-i-wish-id-had-from-day-one.html, https://code.claude.com/docs/en/best-practices -->
**Writer/Reviewer session split**: Implementation session and review session use separate contexts
to avoid confirmation bias. Session A implements. Session B opens a fresh context, reads only the
diff and the spec, and reviews without any memory of the implementation choices.

Without this split, the implementing agent unconsciously validates its own code. Fresh context
has no investment in prior decisions — it catches what the implementing session rationalized past.

<!-- Updated 2026-04-29: https://code.claude.com/docs/en/best-practices, https://www.builder.io/blog/claude-code-tips-best-practices -->
**Worktree isolation for parallel features**: Use `claude --worktree <branch-name>` to create
an isolated branch + context per feature. Multiple worktrees run in parallel without file conflicts.
Preferred over spawning agents on the same working tree when features touch overlapping files.

<!-- Updated 2026-05-06: https://code.claude.com/docs/en/best-practices -->
**Subagent definition files**: Define reusable subagents in `.claude/agents/<name>.md` with their own model, tools, and system prompt. Each agent gets isolated context. Use for: security review, test generation, research tasks that would pollute main session.

```markdown
# .claude/agents/security-reviewer.md
---
name: security-reviewer
description: Reviews code for security vulnerabilities
tools: Read, Grep, Glob, Bash
model: opus
---
Review for SQL injection, XSS, auth flaws, secrets, insecure data handling.
Provide line references and remediation steps.
```

**Subagent scoping**: When spawning agents for implementation, scope each agent to a
single file or function boundary. Cross-file agents produce merge conflicts and silent overrides.

**Fan-out batch pattern**: For large-scale migrations (2,000+ files), distribute work across parallel non-interactive invocations. Test on 2-3 files first, then scale.

```bash
for file in $(cat files.txt); do
  claude -p "Migrate $file from React to Vue. Return OK or FAIL." \
    --allowedTools "Edit,Bash(git commit *)"
done
```

**Prefer Read before Write**: Always read the target file before editing it, even when
the task is purely additive. Prevents format drift and ensures you match existing style.

**Minimal footprint**: Request only the permissions and file access actually needed.
Touch the minimum viable set of files. Unanticipated side effects compound across agents.

<!-- Updated 2026-05-12: https://hamy.xyz/blog/2026-02_code-reviews-claude-subagents, https://code.claude.com/docs/en/best-practices -->
**Parallel multi-aspect review**: Spin up 5–9 parallel subagents, each scoped to a single concern (security, performance, edge cases, concurrency, business logic, API contracts, etc.). Each agent gets a tight prompt describing exactly what it looks for. Aggregated feedback outperforms a single model reviewing everything — scope focus beats breadth.

**Outcomes rubric + grader pattern**: Before implementation, write a rubric of success criteria (expected behaviors, acceptance criteria). After implementation, spawn a *separate* grader agent that evaluates the output against the rubric in its own context — no memory of how the code was written. Grader failure returns specific issues; agent retakes a pass. Solves "looks good but doesn't actually work."

**Three-part prompt structure for agents**: Identity (who the agent is + its specialty) → Rules (constraints + behaviors, XML-tagged) → Output Format (structured expectations). XML tags create semantic boundaries Claude honors better than markdown headings. More precise than free-text system prompts for multi-agent chains.

<!-- Updated 2026-05-12: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents -->
**Init script session validation**: For long-running agentic builds, write `init.sh` that runs at every session start: confirms prior work didn't break the application, verifies key invariants, resets to clean state. Each new feature starts from a verified baseline. Prevents accumulated technical debt from silently compounding across sessions.

**Interrupt-safe commits**: Commit every working state, not just at milestone boundaries.
If an agent is interrupted mid-task, the last commit must be valid and buildable.

**Clarify before long tasks**: For tasks estimated >5 min, surface ambiguities before
starting. Mid-task clarification requests cause partial-state problems.

---

<!-- Updated 2026-04-02: https://code.claude.com/docs/en/best-practices, https://www.morphllm.com/claude-code-best-practices -->
# CONTEXT WINDOW HYGIENE

Long build sessions degrade model performance as context fills. Mitigate:

- **Compact at ~70% context usage**: Use `/compact` before context degrades. Signal: responses
  getting shorter, earlier instructions being ignored, more mistakes per edit.
  Use `/compact <instructions>` to control what survives: e.g. `/compact Focus on API changes only`.
  For partial compaction, use `Esc+Esc` → `/rewind`, select a checkpoint, choose "Summarize from here".
- **Scope sessions by task, not by time**: One session = one feature or one bug. Don't let a
  session sprawl across multiple concerns. Use `/clear` between unrelated tasks.
- **Delegate research to subagents**: Research subtasks consume context without adding code.
  Spawn a researcher agent for deep exploration, synthesize the result into a brief, then
  start the implementation session with that brief injected as context — not the full research.
- **Verification criteria before coding**: State done-when criteria at session START, not end.
  Claude performs dramatically better when it can run tests to verify its own output throughout
  the session, not just at the end.
- **Side questions with `/btw`**: Quick questions that don't need to stay in context go in `/btw`.
  The answer appears as a dismissible overlay and never enters conversation history.
  Use it for "what does this function do?" or "what's the flag for X?" without growing context.
- **Cross-context state persistence**: For tasks that span multiple context windows, write state to
  `_meta/context/progress.json` before context fills. Include: completed steps, current position,
  next action, key decisions made. New context reads this file first and resumes where the previous left off.
  Models now understand their own token budget in real-time — use this to trigger state saves proactively.
- **Two-failure reset rule**: If Claude makes the same mistake twice in a session (same instruction
  ignored twice, same wrong approach tried twice), run `/clear` and restart with a refined prompt
  that encodes the lessons as constraints. A clean session with a better prompt outperforms a long
  session polluted with corrections and failed attempts. Two corrections = stop, reflect, rewrite.
<!-- Updated 2026-05-04: https://code.claude.com/docs/en/best-practices, https://smartscope.blog/en/generative-ai/claude/claude-code-best-practices-advanced-2026/ -->
<!-- Updated 2026-04-19: Anthropic April 2026 prompting guide -->
<!-- Updated 2026-04-10: https://code.claude.com/docs/en/best-practices -->

---

# VELOCITY CALIBRATION
<!-- Updated 2026-04-04: METR 2025 research, https://code.claude.com/docs/en/best-practices -->

**The Velocity Paradox (METR 2025)**: Developers with AI assistance feel ~20% faster but measure ~19% slower.
Root cause: shifting to ~10% planning / ~90% implementation — AI makes coding cheap, so people skip planning.
Fix: **50-70% planning / 30-50% implementation** → 50% fewer refactors, 3x overall velocity.

Invest in:
- Goal extraction and done-when criteria BEFORE any code
- Generating 2-3 approaches and rejecting the first one
- Writing or specifying test cases before implementation

**Verification-first multiplier**: Providing tests, screenshots, or expected outputs BEFORE asking Claude to
implement changes quality dramatically. Claude can run verification against its own output throughout the
session — not just at the end. State verification criteria at session START.

**Adaptive thinking (Claude 4.6)**: Claude Opus/Sonnet 4.6 uses adaptive thinking, not `budget_tokens`.
When spawning agents for deep reasoning, guide effort via instruction:
- Complex architecture/multi-file: `"After reviewing tool results, reflect carefully before proceeding"`
- Standard implementation: no special instruction needed
- Simple edits/validation: explicitly say `"This is straightforward, implement directly"`

<!-- Updated 2026-04-19: Anthropic Opus 4.7 migration guide -->
**Effort parameter (Opus 4.7)**: Opus 4.7 uses an explicit `effort` parameter, not instruction-based guidance.
- `xhigh`: production code, architecture decisions, deep multi-file reasoning
- `high`: test generation, code review, moderate complexity tasks
- `medium`: standard implementation (default if unspecified)
- `low`: validation, linting, trivial edits — model does only what's asked, no elaboration
Use `effort: xhigh` when spawning surgeon agents for tier 2+ work. At `low`, the model won't generalize — be explicit about scope.

**Explicit scope instructions (Opus 4.7 literal following)**: Opus 4.7 interprets instructions precisely — it won't auto-generalize.
- Wrong: "Apply this validation pattern" (applies to first occurrence only)
- Right: "Apply this validation pattern to EVERY endpoint in /src/api/"
State the full scope explicitly in every agent prompt. Assume nothing is inferred.

---

# FLAGS

- `--quick`: skip confirmations, minimal prompts
- `--plan-only`: stop after planning
- `--resume`: continue in-progress work
- `--validate-only`: skip to validation
