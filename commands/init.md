<command id="kernel:init">
<description>Set up KERNEL for your project. Run this once when starting.</description>

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
<!-- SETUP STEPS                                  -->
<!-- ============================================ -->

<steps>

<step id="1" name="Create folders">
Create these directories if they don't exist:
```
_meta/
├── agentdb/      # Memory storage
├── context/      # Current state
├── plans/        # Implementation plans
├── research/     # Research notes
├── handoffs/     # Session summaries
└── agents/       # Active agent registry
```

Run: mkdir -p _meta/{agentdb,context,plans,research,handoffs,agents}
</step>

<step id="2" name="Initialize memory">
If _meta/agentdb/agent.db doesn't exist:
Run: agentdb init

If agentdb command not found:
- Check if plugin is installed correctly
- Run: which agentdb
</step>

<step id="3" name="Verify git">
Check if project is a git repo:
Run: git status

If not a git repo and user wants version control:
Run: git init
</step>

<step id="4" name="Create context file">
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

<step id="5" name="Confirm setup">
Output to user:

---
**Setup complete!**

Your project is ready. Here's what you can do:

- **Start working**: Just describe what you want to do
- **Save progress**: Type `/kernel:handoff` before stopping
- **Get help**: Type `/kernel:help`

KERNEL will remember your progress and learn from each session.
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

Record in _meta/_learnings.md:
## {date}
**Context:** Project initialization
**Type:** pattern
**What:** Initialized KERNEL for {project name}
</after_setup>

</command>
