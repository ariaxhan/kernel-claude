<command id="kernel:ingest">
<description>Universal entry. Classify → Tier → Route. No shortcuts.</description>

<!-- ============================================ -->
<!-- MANDATORY STARTUP (cannot skip)             -->
<!-- ============================================ -->

<startup>
STEP 1: Read AgentDB
```
agentdb read-start
```
Output what you learned: failures to avoid, patterns to follow, active contracts.
If AgentDB empty or missing: note it, continue.

STEP 2: Show task understanding
```
TASK: {what user asked, one sentence}
TYPE: {bug|feature|refactor|question|verify|handoff|review}
```
</startup>

<!-- ============================================ -->
<!-- MANDATORY TIER DECISION (cannot skip)       -->
<!-- ============================================ -->

<tier_decision>
STEP 3: Count files
List every file that WILL be changed. Not might. WILL.
```
FILES:
1. {path}
2. {path}
...
COUNT: {N}
```

STEP 4: Declare tier
```
TIER: {1|2|3}
```
- 1-2 files = Tier 1 → you execute
- 3-5 files = Tier 2 → contract + surgeon
- 6+ files = Tier 3 → contract + surgeon + adversary

If unsure about file count: TIER 2 (safer)
</tier_decision>

<!-- ============================================ -->
<!-- TIER 1: Execute directly                    -->
<!-- ============================================ -->

<tier_1>
You do the work. No agents needed.

Flow:
1. Do the work
2. Test it works
3. Commit
4. `agentdb write-end '{"tier":1,"did":"X","files":["Y"]}'`

Output to user: plain language summary of what changed.
</tier_1>

<!-- ============================================ -->
<!-- TIER 2+: You are ORCHESTRATOR only          -->
<!-- ============================================ -->

<tier_2_plus>
**YOU DO NOT WRITE CODE. YOU DO NOT EDIT FILES.**

STEP 5: Create contract
```
agentdb contract '{"goal":"X","files":["Y"],"tier":N}'
```

STEP 6: Create branch (if not exists)
```
git checkout -b {type}/{name}
```

STEP 7: Spawn surgeon
Use Task tool with:
- subagent_type: kernel:surgeon
- Contract ID from step 5
- File list from step 3
- Clear success criteria

STEP 8: Wait for surgeon checkpoint
```
agentdb query "SELECT content FROM context WHERE type='checkpoint' ORDER BY ts DESC LIMIT 1"
```

STEP 9 (Tier 3 only): Spawn adversary
Use Task tool with:
- subagent_type: kernel:adversary
- Surgeon's checkpoint content
- Test criteria

STEP 10: Report to user
Plain language: what was done, what to check, next steps.

STEP 11: Checkpoint
```
agentdb write-end '{"tier":N,"contract":"CR-X","result":"Y"}'
```
</tier_2_plus>

<!-- ============================================ -->
<!-- OUTPUT FORMAT (always)                      -->
<!-- ============================================ -->

<output_format>
Every response must include:

```
---
TASK: {one sentence}
TYPE: {bug|feature|refactor|question}
TIER: {1|2|3}
FILES: {count}
STATUS: {working|complete|blocked}
---
```

All explanations: plain language, no code terms unless user is technical.
</output_format>

<!-- ============================================ -->
<!-- VIOLATIONS (self-check)                     -->
<!-- ============================================ -->

<violations>
Before ANY action, check:

❌ Am I writing code for tier 2+? STOP. Spawn surgeon.
❌ Did I skip AgentDB read? GO BACK.
❌ Did I skip tier declaration? GO BACK.
❌ Am I guessing file count? COUNT THEM.
❌ Is my output technical? SIMPLIFY.

If any violation: stop, correct, continue.
</violations>

<!-- ============================================ -->
<!-- REFERENCE (load when needed)                -->
<!-- ============================================ -->

<reference>
MANDATORY before classifying/routing:
- skills/orchestration/SKILL.md, skills/orchestration/reference/orchestration-research.md
- skills/build/SKILL.md (solution exploration)
- skills/git/reference/git-research.md

Agent templates: agents/surgeon.md, agents/adversary.md
Classification signals: see CLAUDE.md classification section
</reference>

</command>
