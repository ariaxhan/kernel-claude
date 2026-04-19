# Claude Code & Prompt Engineering: New Actionable Techniques (April 2026)

**Research Date:** 2026-04-19  
**Sources:** Anthropic Official Docs (April 2026), Claude Opus 4.7 Migration Guide, Claude Code Best Practices  
**Scope:** NEW concrete techniques not in existing claude-best-practices-2026.md

---

## EXECUTIVE: What's New in April 2026

Three major shifts in Claude Code and prompt engineering since early April:

1. **Effort Parameter Replaces Thinking Tokens** — More control, better results
2. **Literal Instruction Following** — Opus 4.7 interprets prompts precisely; requires explicit scope
3. **Context Awareness** — Models now track their own token budget; changes how you manage state across windows

---

## PART 1: EFFORT PARAMETER (NEW — Replaces Extended Thinking)

**What changed:** Claude Opus 4.7 introduces `effort` parameter, replacing manual `thinking: {budget_tokens}`.

**The parameter:**
```python
client.messages.create(
    model="claude-opus-4-7",
    max_tokens=64000,
    thinking={"type": "adaptive"},
    output_config={"effort": "xhigh"},  # NEW: xhigh, high, medium, low, max
    messages=[...]
)
```

**Effort levels (new guidance):**

| Level | Use Case | Token Cost | Latency | Intelligence | Recommendation |
|-------|----------|------------|---------|--------------|---|
| **xhigh** (NEW) | Coding, agentic long-horizon | Moderate | Moderate | Very high | Best for production code generation |
| **max** | Hardest problems, competitive evals | High | Higher | Very high | Test carefully; diminishing returns observed |
| **high** | Intelligence-sensitive (default for Sonnet 4.6) | Moderate | Moderate | High | Minimum for most production use |
| **medium** | Balance cost/quality | Low-moderate | Fast | Medium-high | Good for cost-sensitive + capable tasks |
| **low** | Speed-critical, simple tasks | Low | Fast | Medium | Risk of under-thinking on moderate complexity |

**April 2026 best practice:** Start with `xhigh` for coding, measure token usage, scale down if needed. Never use `max` without benchmarking — it has diminishing returns.

**Steering thinking behavior:** Opus 4.7 respects effort levels strictly now (unlike 4.6). At `low` and `medium`, model scopes work to what was asked. This is good for cost but risky on moderately complex tasks.

**Fix for under-thinking at low effort:**
```python
# Add to prompt:
"This task involves multi-step reasoning. Think carefully through the problem before responding."
```

**Fix for over-thinking at xhigh/max:**
```python
# Add to prompt:
"Thinking adds latency and should only be used when it meaningfully improves answer quality — 
typically for problems requiring multi-step reasoning. When in doubt, respond directly."
```

---

## PART 2: LITERAL INSTRUCTION FOLLOWING (April 2026 Change)

**What changed:** Opus 4.7 interprets instructions literally and explicitly. It won't silently generalize from one item to another.

**Impact:** Requires more explicit scope statements.

### Problem Examples

**Old pattern (worked in 4.6, FAILS in 4.7):**
```
Format the first section with bold headers.
```
→ In 4.7, only the first section gets bold. Others don't.

**Fixed pattern (explicit scope):**
```
Format every section with bold headers, not just the first one.
Apply this formatting consistently throughout the document.
```

**Another old pattern (implicit generalization, FAILS in 4.7):**
```
Add error handling to the authentication function.
```
→ In 4.7, only the one function mentioned gets error handling.

**Fixed pattern:**
```
Add error handling to the authentication function AND all functions it calls.
Review the entire auth flow and add try-catch with logging to every endpoint.
```

### What This Means for Prompts

**Rule:** State scope explicitly. "Apply this to X, Y, and Z" not "Apply this pattern."

**Template for Opus 4.7:**
```
Task: [action]
Scope: Apply to [specific list or "all X in Y"]
Constraint: [edge cases to handle]
Verify: [how to check it's done]
```

**Example:**
```
Add input validation to all API endpoints in /src/api/.
Use Zod for every endpoint schema.
Include: email validation, string length limits, number ranges.
After implementation, grep for "app.post|app.get" and confirm each has validation.
```

---

## PART 3: CONTEXT AWARENESS (April 2026 New)

**What changed:** Claude Opus 4.6+ models now understand their own context window limits in real-time.

**What this enables:**

1. **Self-aware context management** — Model knows how much token budget remains
2. **Multi-window state persistence** — Model can save state to external files before context fills
3. **Better prompt for long tasks:**

```python
# Add this to your prompt for long-horizon tasks:
"""
Your context window will be automatically compacted as it approaches its limit, 
allowing you to continue working indefinitely from where you left off. 
Therefore, do not stop tasks early due to token budget concerns. 

As you approach your token budget limit, save your current progress and state 
to memory (use a file like progress.json or state.md) before context resets.

Always be as persistent and autonomous as possible and complete tasks fully, 
even if the end of your budget is approaching. Never artificially stop any task early 
regardless of context remaining.
"""
```

**How to use this:**

For tasks spanning multiple context windows:
1. Claude works autonomously
2. Approaches token limit → saves state to `progress.json`
3. Context compacts → Claude resumes from saved state
4. Process repeats until done

**Working example (multi-window task):**
```
Migrate all Python 2 code to Python 3 in /src/.
Total: ~200 files expected.

Before context resets:
1. Save list of completed files to completed.json
2. Save failures to failed.json
3. Note next file to process in next_task.txt

Resume with: "Continue migration. Check completed.json and next_task.txt. 
Process remaining files."
```

---

## PART 4: RESPONSE LENGTH CALIBRATION (April 2026 Change)

**What changed:** Opus 4.7 calibrates response length to task complexity, not a fixed verbosity.

**Consequence:** Prompts need explicit verbosity guidance now.

**Pattern (if you need concise responses):**
```
Provide concise, focused responses. 
Skip non-essential context, and keep examples minimal.
```

**Pattern (if you need detailed responses):**
```
Provide detailed, thorough responses with complete examples and rationale.
Explain your reasoning step-by-step before the final answer.
```

**For code review:** Explicitly ask for structure since model may now skip interim summaries:
```
After completing code changes:
1. Summarize what files you modified
2. List any breaking changes
3. Explain how to test the changes
```

---

## PART 5: TOOL USE TRIGGERING (April 2026 Change)

**What changed:** Opus 4.7 uses tools LESS often than 4.6 (prefers reasoning). This is usually better but needs adjustment.

**Symptom:** Model reasons about a problem instead of using a web search tool you provided.

**To increase tool usage:**
1. Raise effort to `high` or `xhigh` — substantially more tool usage at higher effort
2. Add explicit instructions:
```
When you encounter a question about [domain], use the [tool] to find current information.
Do not rely on training data; use the tool to verify current facts.
```

**Example for web search:**
```
Use the web search tool to find information about recent changes to [topic].
Do not speculate about current state — always search for the latest.
```

---

## PART 6: CODE REVIEW HARNESS TUNING (April 2026)

**What changed:** Opus 4.7 finds MORE bugs than 4.6 (11pp better recall on real Anthropic PRs) but may report FEWER in your harness.

**Why:** If your review prompt says "be conservative" or "only report high-severity issues," Opus 4.7 follows that literally.

**Old pattern (may reduce reported findings):**
```
Review the code. Report only high-severity issues.
Be conservative and don't nitpick.
```

**New pattern (to get full recall):**
```
Report every issue you find, including ones you are uncertain about or consider low-severity. 
Do not filter for importance or confidence at this stage — a separate verification step will do that. 
Your goal here is coverage: surface findings, and let filtering happen downstream.

For each finding, include: confidence level and estimated severity.
```

**Workflow:** Find → Filter → Rank (separate steps, not one pass)

---

## PART 7: SUBAGENT ORCHESTRATION (April 2026 Change)

**What changed:** Opus 4.7 recognizes when subagents are helpful and spawns them proactively (less often than 4.6, but more intelligently).

**Symptom:** Model may spawn subagents for tasks you'd prefer to do directly.

**To control subagent behavior:**

```
Use subagents when tasks can run in parallel, require isolated context, 
or involve independent workstreams that don't need to share state. 

For simple tasks, sequential operations, single-file edits, or tasks where 
you need to maintain context across steps, work directly rather than delegating.

Examples of when NOT to spawn:
- Refactoring a single function you can already see
- Fixing one typo or naming issue
- Making related changes to 2-3 tightly coupled files

Examples of when TO spawn:
- Fan out across 10+ independent files
- Investigate codebase in parallel with implementation
- Review and implementation in separate contexts
```

---

## PART 8: DESIGN DEFAULTS (April 2026 Change)

**What changed:** Opus 4.7 has strong, consistent design defaults (warm cream backgrounds, serif display, terracotta accents). These suit editorial/hospitality but NOT dev tools, dashboards, fintech, enterprise.

**Problem:** Generic instructions ("make it minimal") shift to different fixed palette, not variety.

**Solution 1: Specify concrete alternative** (most reliable)
```
Design a [product type]. 

The visual direction should come from [specific mood]:
- Cold monochrome: pale silver-gray → blue-gray → near-black
- Sharp, controlled aesthetic with structure and restraint
- 4px corner radius consistently across elements
- Typography: square, angular sans-serif with wider letter spacing
- Color palette: [list specific hex codes]

Layout: clear horizontal sections, centered max-width container, generous margins
```

**Solution 2: Request comparison before building** (generates variety)
```
Before building, propose 4 distinct visual directions:
- bg hex / accent hex / typeface — one-line rationale

Ask me to pick one, then implement only that direction.
```

---

## PART 9: FRONTEND CODE QUALITY (April 2026)

**What changed:** Opus 4.7 generates less "AI slop" by default with minimal prompting. Requires less scaffolding than previous models.

**Minimal frontend guidance still needed:**
```
<frontend_aesthetics>
NEVER use:
- Overused fonts: Inter, Roboto, Arial, system fonts
- Clichéd color schemes: purple gradients on white/dark
- Predictable layouts and cookie-cutter patterns
- Generic AI-generated aesthetic

DO use:
- Unique, distinctive fonts that elevate the design
- Cohesive color themes with dominant color + sharp accents
- Context-specific character and unexpected choices
- Animations for micro-interactions (CSS or Motion library)
</frontend_aesthetics>
```

---

## PART 10: MODEL SELECTION TRADEOFF TABLE (April 2026)

**Updated recommendations based on April 2026 models:**

| Task | Model | Reasoning | Cost | Speed |
|------|-------|-----------|------|-------|
| Production code generation, long-horizon agentic | Opus 4.7 xhigh | Best capabilities, effort control | High | Moderate |
| Coding, moderate complexity | Sonnet 4.6 high | Fast, capable enough, efficient | Low-moderate | Fast |
| Code review, bug-finding | Opus 4.7 | 11pp better recall than 4.6 | High | Moderate |
| Simple tasks, high volume | Sonnet 4.6 low | Fast, cheap, sufficient | Low | Very fast |
| Frontend design | Opus 4.7 | Strong design instincts, less AI slop | High | Moderate |
| Long-document analysis | Opus 4.7 | Better context awareness, state tracking | High | Moderate |
| Latency-critical APIs | Haiku 4.5 | 4K context, on-device option | Very low | Very fast |

---

## PART 11: CHANGES FOR KERNEL-CLAUDE

### Update to CLAUDE.md template:

```markdown
# Code style
- [existing rules]

# Effort parameter (April 2026)
- Use effort: xhigh for production code generation
- Use effort: high for intelligence-sensitive tasks
- Use effort: medium for cost-sensitive balanced work

# Instruction scope (April 2026)
- State scope explicitly: "Apply to X, Y, and Z"
- Do not assume generalization; use "every", "all", "each"
- Example: "Add validation to EVERY endpoint in /src/api/"

# Context awareness (April 2026)
- On long tasks, save state to progress.json before context fills
- Do not artificially stop early for token budget
- Context will auto-compact and allow continuation

# Multi-window state (April 2026)
- Format: progress.json (completed list, next task, failures)
- Model reads this on resume and continues
```

### Update to build/SKILL.md (if exists):

- Add "effort tuning" as a consideration
- Update code review template to use "report everything, filter downstream"
- Add context-awareness best practices

### Update to testing patterns:

- No change to TDD pattern itself
- Add: "Use effort: high for test generation and bug-finding"

---

## COMPARISON: What's Actually New vs Existing Research

| Topic | Existing Doc | New (April 2026) |
|-------|--------------|------------------|
| Thinking/reasoning | Manual budget_tokens | Adaptive with effort parameter; xhigh is new |
| Response length | Fixed verbosity | Calibrated to task complexity; requires explicit guidance |
| Instruction following | Generalizes from examples | Literal interpretation; explicit scope required |
| Tool use | Always encouraged | Less frequent (prefers reasoning); need high effort to increase |
| Context limits | Static | Model now aware of budget; can self-manage across windows |
| Code review | Standard patterns | New: "report all, filter downstream" for full recall |
| Design | Generic guidance | Specific concrete palettes more reliable than abstract |

---

## SOURCES

- [Anthropic: Prompting Best Practices (April 2026)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- [Claude Code Best Practices Official](https://code.claude.com/docs/en/best-practices)
- [Anthropic: Effort Parameter Documentation](https://platform.claude.com/docs/en/build-with-claude/effort)
- [Anthropic: Adaptive Thinking Guide](https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking)
- [Claude Opus 4.7 Migration Guide](https://platform.claude.com/docs/en/about-claude/models/migration-guide#migrating-to-claude-opus-4-7)
- [Claude Sonnet 4.6 Migration Guide](https://platform.claude.com/docs/en/about-claude/models/migration-guide)

---

## NEXT STEPS FOR KERNEL-CLAUDE

1. Update CLAUDE.md template to include effort parameter and explicit scope guidance
2. Update build/SKILL.md with effort tuning for coding tasks
3. Add "context awareness" to orchestration skill
4. Test effort parameter on real tasks (xhigh vs high) and benchmark token usage
5. Update code review harness to use "report all, filter downstream" pattern
6. If using multi-window agentic workflows: implement progress.json state pattern

