---
name: kernel:init
description: "Initialize KERNEL globally. Sets up ~/Vaults structure, symlinks, CLI, database. Run once per machine."
user-invocable: true
allowed-tools: Bash
---

<command id="init">

<purpose>
Global KERNEL setup. Run once per machine.
Creates ~/Vaults structure, symlinks ~/.claude, installs agentdb CLI.
</purpose>

<requirements>
- ~/Vaults/ folder (required convention for all teammates)
- Git installed
- SQLite3 installed
</requirements>

<steps>

## Step 1: Create Vaults structure

```bash
mkdir -p ~/Vaults/_meta/{agentdb,research,plans,handoffs,agents,logs}
mkdir -p ~/Vaults/.claude/{rules,commands,skills}
```

## Step 2: Symlink ~/.claude to ~/Vaults/.claude

This makes Claude config shared via git.

```bash
# Backup existing if not a symlink
if [ -d ~/.claude ] && [ ! -L ~/.claude ]; then
  mv ~/.claude ~/.claude.backup.$(date +%Y%m%d)
  echo "Backed up existing ~/.claude"
fi

# Create symlink
ln -sfn ~/Vaults/.claude ~/.claude
echo "Symlinked ~/.claude → ~/Vaults/.claude"
```

## Step 3: Install agentdb CLI

```bash
# Find plugin location
PLUGIN_CACHE="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
LATEST=$(ls -1 "$PLUGIN_CACHE" 2>/dev/null | grep -E '^[0-9]' | sort -V | tail -1)

if [ -n "$LATEST" ]; then
  AGENTDB_SRC="$PLUGIN_CACHE/$LATEST/orchestration/agentdb/agentdb"

  # Symlink to local bin
  mkdir -p ~/Vaults/.local/bin
  ln -sf "$AGENTDB_SRC" ~/Vaults/.local/bin/agentdb

  # Add to PATH if not already
  if ! grep -q 'Vaults/.local/bin' ~/.zshrc 2>/dev/null; then
    echo 'export PATH="$HOME/Vaults/.local/bin:$PATH"' >> ~/.zshrc
  fi
  if ! grep -q 'Vaults/.local/bin' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/Vaults/.local/bin:$PATH"' >> ~/.bashrc
  fi

  echo "Installed agentdb CLI to ~/Vaults/.local/bin/"
else
  echo "WARNING: Plugin not found in cache. Install plugin first: /plugin install kernel"
fi
```

## Step 4: Initialize AgentDB

```bash
agentdb init
```

Or manually:

```bash
sqlite3 ~/Vaults/_meta/agentdb/agent.db "
PRAGMA journal_mode=WAL;
CREATE TABLE IF NOT EXISTS learnings (
  id TEXT PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  type TEXT,
  insight TEXT NOT NULL,
  evidence TEXT,
  domain TEXT,
  hit_count INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS context (
  id TEXT PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  type TEXT,
  contract_id TEXT,
  agent TEXT,
  content TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS errors (
  id INTEGER PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  tool TEXT,
  error TEXT,
  file TEXT
);
CREATE INDEX IF NOT EXISTS idx_learnings_type ON learnings(type);
CREATE INDEX IF NOT EXISTS idx_context_type ON context(type);
"
echo "AgentDB initialized at ~/Vaults/_meta/agentdb/agent.db"
```

## Step 5: Create kernel symlink for hooks

This makes hooks work with the fixed ~/Vaults path:

```bash
mkdir -p ~/Vaults/.claude/kernel
ln -sfn "$PLUGIN_CACHE/$LATEST/orchestration" ~/Vaults/.claude/kernel/orchestration
ln -sfn "$PLUGIN_CACHE/$LATEST/hooks" ~/Vaults/.claude/kernel/hooks
echo "Symlinked plugin components to ~/Vaults/.claude/kernel/"
```

## Step 6: Verify

```bash
echo ""
echo "=== KERNEL INIT COMPLETE ==="
echo ""
echo "Structure:"
ls -la ~/Vaults/_meta/
echo ""
echo "Symlinks:"
ls -la ~/.claude
ls -la ~/Vaults/.claude/kernel/
echo ""
echo "AgentDB:"
agentdb status 2>/dev/null || echo "Run: source ~/.zshrc && agentdb status"
echo ""
echo "Next: Restart terminal, then test with: agentdb read-start"
```

</steps>

<one_liner>
Run all steps:
```bash
mkdir -p ~/Vaults/_meta/{agentdb,research,plans,handoffs,agents,logs} ~/Vaults/.claude/{rules,commands,skills} ~/Vaults/.local/bin && \
[ -d ~/.claude ] && [ ! -L ~/.claude ] && mv ~/.claude ~/.claude.backup.$(date +%Y%m%d); \
ln -sfn ~/Vaults/.claude ~/.claude && \
PLUGIN_CACHE="$HOME/.claude/plugins/cache/kernel-marketplace/kernel" && \
LATEST=$(ls -1 "$PLUGIN_CACHE" 2>/dev/null | grep -E '^[0-9]' | sort -V | tail -1) && \
ln -sf "$PLUGIN_CACHE/$LATEST/orchestration/agentdb/agentdb" ~/Vaults/.local/bin/agentdb && \
mkdir -p ~/Vaults/.claude/kernel && \
ln -sfn "$PLUGIN_CACHE/$LATEST/orchestration" ~/Vaults/.claude/kernel/orchestration && \
ln -sfn "$PLUGIN_CACHE/$LATEST/hooks" ~/Vaults/.claude/kernel/hooks && \
echo 'export PATH="$HOME/Vaults/.local/bin:$PATH"' >> ~/.zshrc && \
source ~/.zshrc && \
agentdb init && \
echo "KERNEL initialized. Restart terminal."
```
</one_liner>

<troubleshooting>
**"agentdb: command not found"**
- Run: `source ~/.zshrc` or restart terminal
- Check: `ls ~/Vaults/.local/bin/agentdb`

**"Plugin not found"**
- Install plugin first: `/plugin install kernel`
- Or: `claude plugin marketplace add ariaxhan/kernel-claude && claude plugin install kernel`

**"Permission denied"**
- Check: `chmod +x ~/Vaults/.local/bin/agentdb`

**Hooks not running**
- Restart Claude Code after init
- Check: `cat ~/.claude/settings.json` for hooks section
</troubleshooting>

</command>
