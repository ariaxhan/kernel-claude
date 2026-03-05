<command id="kernel:init">
<description>Set up KERNEL for your project. Run this once when starting.</description>

<!-- PREREQUISITE: Plugin installed, CLAUDE.md in .claude/, agentdb on PATH. See docs/QUICKSTART.md for full installation. -->

<!-- ============================================ -->
<!-- FOR NON-TECHNICAL USERS                      -->
<!-- ============================================ -->

<user_message>
Setting up your project to work with KERNEL. This creates the folders and files needed to:
- Remember what works and what doesn't
- Save your progress automatically
- Track what you're working on

You only need to do this once per project.
</user_message>

<!-- ============================================ -->
<!-- FILE STRUCTURE (what init creates)           -->
<!-- ============================================ -->

<file_structure>
_meta/
├── agentdb/      # Memory storage (agent.db). Learnings, contracts, checkpoints.
├── context/      # Current state (active.md). Scout/researcher findings.
├── plans/        # Implementation plans from /build.
├── research/     # Research notes from researcher agent.
├── handoffs/     # Session summaries from /kernel:handoff.
├── reviews/      # Tear-down reviews from /kernel:tearitapart.
└── agents/       # Active agent registry.
</file_structure>

<!-- ============================================ -->
<!-- SETUP STEPS                                  -->
<!-- ============================================ -->

<steps>

<step id="1" name="Create folders">
Create these directories if they don't exist:
```
_meta/{agentdb,context,plans,research,handoffs,reviews,agents}
```
Run: mkdir -p _meta/{agentdb,context,plans,research,handoffs,reviews,agents}
</step>

<step id="2" name="Initialize memory">
If _meta/agentdb/agent.db doesn't exist:
Run: agentdb init

If agentdb command not found:
- Plugin may not be installed. See docs/QUICKSTART.md for installation.
- Check: which agentdb
- Symlink: sudo ln -sf "$KERNEL_PATH/orchestration/agentdb/agentdb" /usr/local/bin/agentdb
</step>

<step id="3" name="Verify CLAUDE.md">
Ensure project has KERNEL instructions:
- .claude/CLAUDE.md must exist (copied during plugin install)
- If missing: cp "$KERNEL_PATH/CLAUDE.md" .claude/CLAUDE.md
</step>

<step id="4" name="Verify git">
Check if project is a git repo:
Run: git status

If not a git repo and user wants version control:
Run: git init
</step>

<step id="5" name="Create context file">
If _meta/context/active.md doesn't exist, create it:

```markdown
# Project Context

**Last updated**: {today's date}
**Branch**: {current branch}

## What This Project Is
{Ask user to describe in 1-2 sentences}

## Current Focus
{Ask user what they're working on}

## Important Files
{List key files discovered or ask user}
```
</step>

<step id="6" name="Confirm setup">
Output to user:

---
**Setup complete!**

Your project is ready. KERNEL provides:
- **Memory**: Remembers mistakes, patterns, progress (AgentDB + _meta/)
- **Helpers**: Surgeon (builds), Adversary (validates), Researcher, Scout, Validator (pre-commit gate)
- **Shortcuts**: /kernel:ingest (start), /kernel:handoff (save), /kernel:help

**To start working**: Describe what you want. KERNEL runs /ingest automatically: classify → tier → route.
**To save progress**: Type `/kernel:handoff` before stopping.
**Need help?**: Type `/kernel:help`
---
</step>

</steps>

<!-- ============================================ -->
<!-- OUTPUT RULES                                 -->
<!-- ============================================ -->

<output_rules>
<rule>All messages to user: plain language, no code terms unless user is technical</rule>
<rule>Never show file paths unless user asks</rule>
<rule>Never show command output unless there's an error</rule>
<rule>If something fails: explain what went wrong in simple terms + what to do</rule>
<rule>Success messages: short, clear, actionable next step</rule>
</output_rules>

<!-- ============================================ -->
<!-- AFTER SETUP                                  -->
<!-- ============================================ -->

<after_setup>
Write to AgentDB:
agentdb write-end '{"agent":"init","did":"setup_complete","project":"PROJECT_NAME"}'

If _meta/_learnings.md exists, append:
## {date}
**Context:** Project initialization
**Type:** pattern
**What:** Initialized KERNEL for {project name}
</after_setup>

</command>
