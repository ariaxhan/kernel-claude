# Claude Code & Prompt Engineering Best Practices 2026

**Research Date:** 2026-04-04  
**Sources:** Anthropic Official Docs, Claude Code Docs, Community Guides  
**Purpose:** Actionable patterns for Claude Code workflows, prompt engineering, testing, debugging, and AI code review

---

## EXECUTIVE SUMMARY

### Most Important: Context is Everything

Claude Code's fundamental constraint: **context window fills fast, performance degrades as it fills.** Managing context is the single highest-leverage thing you can do.

- Track context usage continuously
- Use `/clear` between unrelated tasks
- Compact aggressively at 70% window fill
- Delegate research with subagents to keep main context clean

### Second Most Important: Verification Before Everything

Claude performs dramatically better when it can verify its work.

- Provide tests, screenshots, or expected outputs
- Ask Claude to run verification after changes
- Use Plan Mode to separate exploration from implementation
- This is a 3-5x multiplier on quality

---

## PART 1: PROMPT ENGINEERING (Anthropic Official Guidance)

### Core Principles

#### 1. Be Clear and Direct

Claude is "a brilliant but new employee who lacks context." Assume nothing.

**Anti-pattern:** "Create an analytics dashboard"  
**Pattern:** "Create an analytics dashboard. Include as many relevant features and interactions as possible. Go beyond the basics to create a fully-featured implementation."

**Rule of thumb:** Show your prompt to someone with minimal context. If they'd be confused, Claude will be too.

#### 2. Add Context to Why

Don't just state constraints; explain motivation. Claude generalizes from explanations.

**Anti-pattern:** "NEVER use ellipses"  
**Pattern:** "Your response will be read aloud by a text-to-speech engine, so never use ellipses since the engine won't know how to pronounce them."

#### 3. Use Examples Effectively (Multishot Prompting)

Examples are one of the most reliable steering mechanisms.

**Rule:** Include 3-5 examples per prompt.
- Make them relevant to your actual use case
- Cover edge cases and vary enough Claude doesn't pick up unintended patterns
- Wrap in `<example>` tags (multiple in `<examples>` tags)

#### 4. Structure Prompts with XML Tags

XML tags help Claude parse complex prompts unambiguously.

**Pattern:**
```xml
<instructions>...</instructions>
<context>...</context>
<examples>
  <example>...</example>
</examples>
<input>...</input>
```

Nest hierarchically: `<documents><document index="1"><source>...</source><document_content>...</document_content></document></documents>`

#### 5. Long Context Strategy (20k+ tokens)

When working with large documents:

1. **Put longform data at TOP** of prompt (above instructions)
   - Queries at the end improve quality by up to 30%
2. **Structure with XML tags** for clarity
3. **Ground responses in quotes** — ask Claude to quote relevant parts before analyzing

**Pattern:**
```xml
<documents>
  <document index="1">
    <source>file.pdf</source>
    <document_content>{{CONTENT}}</document_content>
  </document>
</documents>

Find quotes from the documents relevant to {{QUERY}}.
Place these in <quotes> tags. Then...
```

#### 6. Give Claude a Role

One sentence in system prompt changes behavior dramatically.

```
system="You are a security engineer. Review code for injection vulnerabilities, authentication flaws, and secrets."
```

#### 7. Control Output Format (Positively)

Tell Claude what to DO, not what NOT to do.

**Anti-pattern:** "Do not use markdown"  
**Pattern:** "Write in flowing prose. Reserve markdown for code blocks and headings only."

For strict control:
```
<avoid_excessive_markdown>
Write in clear, flowing paragraphs. Use standard paragraph breaks. 
Reserve markdown for `inline code`, code blocks (```), and simple headings (###).
Avoid **bold**, *italics*, and bullet points unless truly discrete items.
</avoid_excessive_markdown>
```

#### 8. Tool Use — Be Explicit

Claude's latest models respond to explicit direction about tools.

**Anti-pattern (Claude suggests only):** "Can you suggest changes to this function?"  
**Pattern (Claude implements):** "Change this function to improve performance."

For maximum proactivity:
```
<default_to_action>
By default, implement changes rather than only suggesting them. 
If intent is unclear, infer the most useful likely action and proceed.
</default_to_action>
```

For conservative behavior:
```
<do_not_act_before_instructions>
Do not jump into implementation unless clearly instructed. 
When intent is ambiguous, provide information and recommendations first.
Only proceed with edits when explicitly requested.
</do_not_act_before_instructions>
```

#### 9. Optimize Parallel Tool Calling

Claude Opus 4.6 and Sonnet 4.6 excel at parallel execution. For maximum efficiency:

```
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies, 
make all independent tool calls in parallel. Maximize parallel execution where possible.
However, if calls depend on previous results, execute sequentially.
Never use placeholders or guess missing parameters.
</use_parallel_tool_calls>
```

#### 10. Thinking and Reasoning (Adaptive Thinking)

Claude Opus 4.6 and Sonnet 4.6 use **adaptive thinking** — Claude dynamically decides when to think based on effort level and query complexity.

**Configuration:**
```python
client.messages.create(
    model="claude-opus-4-6",
    max_tokens=64000,
    thinking={"type": "adaptive"},
    output_config={"effort": "high"},  # or max, medium, low
    messages=[...]
)
```

**Effort levels:**
- `high` / `max`: deep reasoning, longer latency (use for complex code, long-horizon tasks)
- `medium`: balanced (most applications)
- `low`: fast responses, minimal thinking (latency-sensitive workloads)

**When to guide thinking:**
```
After receiving tool results, carefully reflect on their quality 
and determine optimal next steps before proceeding.
```

If Claude is overthinking and inflating tokens:
```
Extended thinking should only improve answer quality. 
When in doubt, respond directly rather than thinking extensively.
```

---

## PART 2: CLAUDE CODE BEST PRACTICES

### Foundation: CLAUDE.md

CLAUDE.md is loaded at the START of every session. No optional.

**What to include:**
- Bash commands Claude can't guess
- Code style rules that differ from defaults
- Testing instructions and preferred runners
- Repository etiquette (branch naming, PR conventions)
- Architectural decisions specific to your project
- Developer environment quirks
- Common gotchas or non-obvious behaviors

**What to exclude:**
- Anything Claude can figure out by reading code
- Standard language conventions Claude already knows
- Detailed API documentation (link instead)
- Information that changes frequently
- Long explanations or tutorials
- File-by-file codebase descriptions

**Length rule:** If a line wouldn't cause mistakes if removed, cut it. Bloated CLAUDE.md files cause Claude to ignore rules buried in noise.

**Example:**
```markdown
# Code style
- Use ES modules (import/export), not CommonJS
- Destructure imports when possible

# Workflow
- Run typecheck after code changes
- Run single tests, not whole suite (for performance)

# Architecture
- API handlers in /src/api/
- Business logic in /src/services/
- Database models in /src/models/
```

**Import syntax:** CLAUDE.md can import additional files:
```
See @README.md for overview and @package.json for commands.
Git workflow: @docs/git-instructions.md
```

**Locations:**
- `~/.claude/CLAUDE.md` — applies to all sessions
- `./CLAUDE.md` — project root, check into git
- `./CLAUDE.local.md` — personal project notes, add to `.gitignore`

### Verification is the Multiplier

**Single highest-leverage practice:** Give Claude a way to verify its work.

**Pattern:**
```
write a validateEmail function. 
Example test cases: user@example.com is true, invalid is false, user@.com is false.
Run the tests after implementing to verify.
```

**Verification strategies:**

| Strategy | Before | After |
|----------|--------|-------|
| Tests | "implement a validator" | "write tests for edge cases, run them, fix failures" |
| Screenshots | "make dashboard better" | "[paste screenshot] implement this design, take screenshot, compare, fix differences" |
| Root cause | "build is failing" | "build fails with [error]. fix root cause, verify build succeeds" |

Claude performs 3-5x better with explicit verification criteria.

### Explore → Plan → Code → Commit (Plan Mode)

**Four-phase workflow:**

1. **Explore** (Plan Mode)
   ```
   read /src/auth and understand how we handle sessions.
   ```

2. **Plan** (Plan Mode)
   ```
   I want to add Google OAuth. What files change? 
   What's the session flow? Create a plan.
   ```
   - Press `Ctrl+G` to edit plan in your editor

3. **Implement** (Normal Mode)
   ```
   implement the OAuth flow from your plan. 
   write tests for the callback, run suite, fix failures.
   ```

4. **Commit**
   ```
   commit with descriptive message and create PR
   ```

**When to skip planning:** If you could describe the diff in one sentence (typo fix, add log line, rename variable), skip planning. Planning overhead isn't worth it for trivial changes.

### Specific Context is Key

**Rule:** More precise instructions = fewer corrections.

| Strategy | Before | After |
|----------|--------|-------|
| Scope precisely | "add tests for foo.py" | "write tests for foo.py covering logged-out user edge case. avoid mocks" |
| Point to sources | "why does ExecutionFactory have weird api?" | "read ExecutionFactory's git history and summarize how api came to be" |
| Reference patterns | "add calendar widget" | "look at HotDogWidget.php pattern, follow it to implement calendar widget with month selection and year pagination" |
| Describe symptoms | "fix login bug" | "users report login fails after timeout. check src/auth/ token refresh. write failing test, then fix" |

### Provide Rich Content

Use `@` to reference files (Claude reads before responding):
```
review @src/auth/handler.ts for security issues
```

**Pipe data directly:**
```
cat error.log | claude "diagnose this error"
```

**Paste images:** Copy/paste screenshots directly.

**Give URLs:** Reference documentation and API references.

### Context Management is Discipline

**The constraint:** Context fills fast, performance degrades.

**Tools:**
- `Esc` — stop Claude mid-action, context preserved for redirect
- `Esc + Esc` or `/rewind` — restore previous state or summarize from checkpoint
- `/clear` — reset context between unrelated tasks
- `/compact <instructions>` — summarize with specific focus
- `/btw` — side questions that don't enter history

**Strategy:**
- Use `/clear` frequently between tasks
- When auto-compaction triggers, Claude summarizes important code and decisions
- Customize compaction in CLAUDE.md: `"When compacting, preserve full modified files list and test commands"`
- For long sessions, consider fresh context instead of compacting — Claude is great at discovering state from filesystem

**Rule:** If you've corrected Claude >2 times on same issue, `/clear` and restart with better initial prompt. Accumulated failed attempts clutter context more than they help.

### Use Subagents for Investigation

Subagents explore in separate context, returning summaries without cluttering main conversation.

```
use subagents to investigate how our auth system handles token refresh
```

Result: subagent explores, reads files, reports findings. Main context stays clean for implementation.

**Also use for verification:**
```
use subagent to review this code for edge cases
```

### Automate with Hooks

Hooks run scripts automatically at specific workflow points. Unlike CLAUDE.md (advisory), hooks are **deterministic** — guaranteed to run.

**Examples:**
```
Write a hook that runs eslint after every file edit
Write a hook that blocks writes to migrations/ folder
```

Edit `.claude/settings.json` directly or run `/hooks` to configure.

**Key difference from CLAUDE.md:**
- CLAUDE.md: instructions Claude reads and tries to follow
- Hooks: guaranteed execution, zero exceptions

---

## PART 3: TESTING PATTERNS WITH CLAUDE

### TDD with Claude (Red-Green-Refactor)

Claude's natural tendency: implement first, then test.  
TDD requires: tests first, then implementation.

**Pattern:**

1. **Red** — Explicitly write tests FIRST
   ```
   We're doing TDD. Write tests for a validateEmail function 
   that handles: valid emails, invalid emails, edge cases.
   Write tests, don't implement yet.
   ```

2. **Green** — Run tests to confirm they fail
   ```
   Run the test suite. Confirm tests fail as expected.
   ```

3. **Implement** — Make tests pass
   ```
   Now implement validateEmail to make all tests pass.
   Run the suite after each change. Debug failures.
   ```

4. **Refactor** — Clean up while keeping tests green
   ```
   Refactor for clarity. Ensure all tests still pass.
   ```

**Why TDD with Claude:**
- Tests provide clear, verifiable target
- Claude can evaluate results after each change
- Incremental improvement (write code, test, debug, repeat)
- Natural alignment with Claude's agentic capabilities
- Breaks complex problems into smaller, testable units

### Testing Rules

- Never modify existing tests to make them pass (test integrity)
- Never update snapshots without explicit instruction
- Use transactions for database tests
- Mark flaky tests appropriately rather than retrying forever
- Write failing test BEFORE fixing any reported bug

**AI-Generated Code Testing Anti-Pattern:** When AI generates both code and tests, tests often become tautological (testing what code does, not what it should do).

**Fix:** Write test cases BEFORE generating implementation code.

---

## PART 4: DEBUGGING WITH CLAUDE

### Visibility-First Debugging

Claude fails less from lack of intelligence, more from lack of visibility.

**Key insight:** You see browser dev tools, console logs, network requests, actual behavior. Claude often doesn't.

**Pattern:**
1. Show Claude WHAT you see
2. Show Claude WHERE in code
3. Ask Claude to diagnose, not patch

**Strategy:**
```
the build fails with this error: [PASTE ERROR]
1. fix the root cause
2. verify the build succeeds
3. don't just suppress the error
```

### Systematic Debugging Methodology

**Four phases:**

1. **Observe symptoms** — What does the user see? What's broken?
2. **Find immediate cause** — Where does the error occur?
3. **Map call chain** — What calls led here?
4. **Trace to original trigger** — What triggered the whole chain?

**Key rule:** NO FIXES WITHOUT ROOT CAUSE FIRST.

Treating symptoms instead of root causes leads to brittle code and recurring bugs.

### Add Loggers First

```
Add comprehensive loggers to understand the flow. 
Then paste terminal output until we find the core issue.
```

Logging creates visibility. Visibility enables diagnosis.

### CLAUDE.md for Debugging

Pre-load your CLAUDE.md with:
- Build commands that might be non-obvious
- Environment variables needed
- Known quirks or gotchas
- Test runners and debugging setup

Claude reads this at session start, shortening diagnosis cycle.

---

## PART 5: AI CODE REVIEW BEST PRACTICES

### Workflow Integration: AI Before Human

**Modern 2026 workflow:**

1. Developer opens PR
2. CI runs AI review in ~90 seconds
3. Developer fixes issues (optional but cheap)
4. Human reviewers see cleaner diff
5. Human focuses on architecture and business logic, not style

**Result:** Humans reviewing fewer dumb mistakes, more focused on hard problems.

### Managing Diff Size

**Critical finding:** AI reviewers struggle with large diffs.

- **1,000-line diff:** Overwhelms context, loses coherence
- **50-200 line diff:** Produces useful, actionable feedback
- **10-50 line diff:** Best feedback quality

**Fix:** Enforce small changes. Break large PRs into logical chunks.

### Testing Anti-Pattern: Tautological Tests

**When AI generates code + tests together:** Tests almost always test what the code does, not what it should do.

**Fix:** 
1. Write test cases manually FIRST
2. Share test cases with AI
3. AI implements to pass your tests

**Result:** Tests define behavior; code implements it.

### Standardize with Guidelines

Don't keep rules in Slack or wiki. **Check them into a file:**

```
agents.md — AI guidelines
```

Include:
- Code style rules (spacing, naming, patterns)
- What tools to prefer (linters, formatters)
- What static analysis catches (let tools catch obvious stuff)
- What AI commonly misses (your Big 5 concerns)

### Team Communication Culture

Use **"Nit:"** prefix for low-stakes comments:

```
Nit: this variable could be more descriptive
```

This signals the comment is optional, preventing authors from wasting time on non-critical issues.

### AI-Generated Code Needs Different Review

**Not more review. Different review.**

**What to look for:**

| Concern | Focus |
|---------|-------|
| Input validation | Zod/Pydantic schemas present? |
| Error handling | Empty catch blocks? Logged? |
| Edge cases | null, empty, boundary, timeout? |
| Duplication | Same logic 3+ places? |
| Complexity | Functions >30 lines? Nested ternaries? |

---

## PART 6: BIG 5 GUIDANCE FOR AI CODE

*(From ai-code-anti-patterns research)*

### 1. INPUT VALIDATION (Systematic Omission)

**Why AI misses this:** Happy path dominates training data.

**Pattern:** Every API endpoint must have Zod/Pydantic schema.

```typescript
import { z } from 'zod';

const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(255),
  age: z.number().min(0).max(150),
});

app.post('/users', (req) => {
  const validated = createUserSchema.parse(req.body); // throws if invalid
  // ... use validated data
});
```

**Checklist:**
- [ ] Zod/Pydantic for every input endpoint
- [ ] Parameterized queries (no string concat)
- [ ] File uploads validated (type, size)
- [ ] Length limits on text fields
- [ ] Null checks on API responses

### 2. EDGE CASE BLINDNESS

**Why AI misses this:** Edge cases underrepresented in training data.

**Pattern:** Test edge cases BEFORE happy path.

**Template:**
```typescript
// Test these FIRST:
- null / undefined
- empty array / string
- boundary values (0, -1, max int)
- concurrent access
- timeout scenarios
- unicode characters
```

**Detection:**
- Array access without length check
- Optional chaining chains (?.?.?. smell)
- Async without try-catch
- Promise.all without error boundaries

### 3. ERROR HANDLING GAPS

**Why AI misses this:** Error handling is boilerplate; "make it work" doesn't include "fail gracefully."

**Pattern:** Every catch block logs and returns useful message.

```typescript
try {
  // ...
} catch (error) {
  logger.error('operation failed', { 
    context: 'user creation', 
    error: error.message,
    stack: error.stack 
  });
  return { status: 500, message: 'internal error' };
}
```

**Checklist:**
- [ ] No empty catch blocks
- [ ] Errors logged with context (not console.log)
- [ ] User-facing messages generic (don't leak internals)
- [ ] Background jobs have retry logic
- [ ] React components have error boundaries

### 4. DUPLICATION EXPLOSION (8x Increase)

**Why AI does this:** Each prompt generates "complete" solution; no refactoring after.

**Pattern:** Prompt asks to check for existing utilities BEFORE implementing.

```
Before implementing, search for existing validate/email functions.
If they exist, use them. Don't duplicate.
```

**Detection:**
- jscpd or duplication detector in CI
- Functions >50 lines often contain duplication
- Identical import blocks
- Similar if/switch chains

**Fix:** 20-30% sprint time for debt reduction.

### 5. COMPLEXITY SPIRAL (+15-25% Cyclomatic)

**Why AI does this:** Generates "complete" solutions; no pressure to simplify.

**Pattern:** Keep functions <30 lines; use guard clauses for early returns.

```typescript
// Bad: nested ternaries
const status = user ? (user.active ? (user.verified ? 'ready' : 'pending') : 'inactive') : 'unknown';

// Good: guard clauses
if (!user) return 'unknown';
if (!user.active) return 'inactive';
if (!user.verified) return 'pending';
return 'ready';
```

**Detection:**
- ESLint complexity rule (threshold: <10)
- Functions with >10 parameters
- Files >500 lines
- Components with >5 useState calls
- Nested ternaries 3+ levels deep

---

## PART 7: COMMUNICATION PATTERNS

### Ask Claude Codebase Questions

Treat Claude like a senior engineer:

```
How does logging work?
How do I make a new API endpoint?
What does `async move { ... }` do on line 134?
What edge cases does CustomerOnboardingFlow handle?
Why does this code call foo() instead of bar() on line 333?
```

This is effective onboarding and reduces load on other engineers.

### Let Claude Interview You

For larger features, start with minimal prompt:

```
I want to build [brief description]. Interview me in detail.

Ask about: technical implementation, UI/UX, edge cases, concerns, tradeoffs.
Don't ask obvious questions, dig into hard parts.

Interview until we've covered everything, then write SPEC.md.
```

After spec is done, start fresh session to execute (clean context focused on implementation).

### Correct Early and Often

Tight feedback loops produce better solutions faster.

**Tools:**
- `Esc` — stop mid-action, preserve context
- `/rewind` — restore previous state
- "Undo that" — have Claude revert changes
- `/clear` — reset between unrelated tasks

---

## PART 8: ANTI-PATTERNS TO AVOID

### Context Anti-Patterns

❌ **Kitchen sink session:** Start task A, ask unrelated task B, go back to A. Context fills with noise.  
✅ **Fix:** `/clear` between unrelated tasks.

❌ **Infinite corrections:** Claude wrong, you correct, still wrong, correct again.  
✅ **Fix:** After 2 failed corrections, `/clear` and write better initial prompt.

❌ **Bloated CLAUDE.md:** Rules get lost in noise because file is too long.  
✅ **Fix:** Ruthlessly prune. Treat like code: review when things go wrong.

### Coding Anti-Patterns

❌ **Trust without verify:** Plausible-looking implementation that doesn't handle edge cases.  
✅ **Fix:** Always provide verification (tests, scripts, screenshots).

❌ **Infinite exploration:** "Investigate X" without scope. Claude reads 100s of files.  
✅ **Fix:** Scope narrowly or use subagents.

❌ **Vague prompts:** "Make it better" or "Fix it."  
✅ **Fix:** Reference specific files, describe symptoms, be precise.

### Review Anti-Patterns

❌ **AI-generated tests test implementation, not spec.**  
✅ **Fix:** Write test cases FIRST, then implementation.

❌ **Large diffs confuse reviewers.**  
✅ **Fix:** Keep diffs 50-200 lines.

❌ **Guidelines live in Slack.**  
✅ **Fix:** Check `agents.md` or guidelines into repo.

---

## PART 9: SPEED & SCOPE CALIBRATION

From existing kernel-claude benchmarks (ModelMind React Native app):

| Task | Actual Time | Scale | Speedup vs Traditional |
|------|-------------|-------|----------------------|
| Feedback system (types → storage → component → tests) | 45 min | ~500 LOC | 4-6x |
| 14 accessibility fixes | 14 min | 14 files | 5-7x |
| 4 large screens decomposed | 8 min | 4 files | 3-5x |
| Backend architecture (9 PRs) | ~12 hours | 9 PRs parallel | 4-6x |
| Full app (concept → 182 commits) | 8 days | 8,500 files | 4-6x |

**Planning-to-building ratio: 1:32.** Compact planning → aggressive execution.

**What's fast with AI:**
- Boilerplate/scaffolding: 10x
- Configuration/Docker: 8-10x
- Feature variants: 10x
- API integration: 3-5x
- Complex domain logic: 2-5x

**What's not fast with AI:**
- Architecture/design: 1x (human-led)
- Novel algorithms: 1x (human-led)

**Critical:** Speedup assumes greenfield + clear requirements + established patterns.  
Legacy refactoring is slower. Unclear requirements = no speed gain.

---

## PART 10: VELOCITY PARADOX (METR 2025)

**Finding:** Developers perceived 20% faster, measured 19% slower.

**Why:** Time saved generating code < time lost reviewing, debugging, fixing.

**Fix:**
```
Old: 10% planning, 90% coding
New: 50-70% planning, 30-50% coding

Result: 50% fewer refactors, 3x faster overall
```

**Principle:** "95% planning, 5% building"
- Humans shape product through specs
- AI handles execution
- Clear spec = fast implementation
- Vague spec = endless iteration

**Code review time increases 2-3x initially.** AI code has:
- 10.83 findings per PR vs 6.45 human
- 40% more critical issues
- 70% more major issues
- 3x more readability issues

**Solution:** Quality gates BEFORE review. Automated checks catch 80% of issues.

---

## SOURCES

- [Anthropic Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)
- [Anthropic Interactive Prompt Engineering Tutorial](https://github.com/anthropics/prompt-eng-interactive-tutorial)
- [Builder.io Claude Code Best Practices](https://www.builder.io/blog/claude-code-tips-best-practices)
- [EESEL: Claude Code Best Practices 2026](https://www.eesel.ai/blog/claude-code-best-practices)
- [Claudify: 10 Claude Code Best Practices (2026)](https://claudify.tech/blog/claude-code-best-practices)
- [Test-Driven Development with Claude Code](https://stevekinney.com/courses/ai-development/test-driven-development-with-claude)
- [Dev Community: Claude Code for Testing](https://dev.to/subprime2010/claude-code-for-testing-write-run-and-fix-tests-without-leaving-your-terminal-2gkh)
- [Stack Overflow: Coding Guidelines for AI Agents](https://stackoverflow.blog/2026/03/26/coding-guidelines-for-ai-agents-and-people-too/)
- [AI Code Review Best Practices](https://collinwilkins.com/articles/ai-code-review-best-practices-approaches-tools.html)
- [CodeAnt: Code Review Best Practices 2026](https://www.codeant.ai/blogs/good-code-review-practices-guide)

---

## NEXT STEPS FOR KERNEL-CLAUDE

1. **Validate patterns** against kernel-claude workflows (especially timing estimates)
2. **Update CLAUDE.md** with clearest prompt structure from Part 1
3. **Create skill modules** for TDD, debugging methodology, Big 5 review
4. **Add hooks** for validation before commit (linting, type checking, security scan)
5. **Document in kernel spec** how this overrides prior prompt engineering assumptions

