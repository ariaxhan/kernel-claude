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

---

# RESEARCH CACHE

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

# FLAGS

- `--quick`: skip confirmations, minimal prompts
- `--plan-only`: stop after planning
- `--resume`: continue in-progress work
- `--validate-only`: skip to validation
