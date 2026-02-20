# v5.4.0 - Hooks + Article Alignment

## What's New

### Hooks (Now Included!)
- **SessionStart**: Outputs git state, KERNEL philosophy, and runs `agentdb read-start`
- **PostToolUseFailure**: Automatically captures tool errors to the errors table

### AgentDB Improvements
- `agentdb read-start` now shows **Recent Errors** alongside failures, patterns, contracts, and checkpoints
- Install prompt now copies CLAUDE.md to your project's `.claude/` directory

### Article Alignment
This release aligns the plugin with the Medium article: *I Replaced Endless AI-Generated Markdown With One SQLite DB*

The startup hook now outputs the same format shown in the article:
- Git state (branch, changes, recent commits)
- Philosophy summary
- Failures, patterns, errors, contracts, checkpoints

## Install

```
/install-plugin https://github.com/ariaxhan/kernel-claude
```

Then paste the full install prompt from the README.
