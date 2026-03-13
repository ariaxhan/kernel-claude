---
name: kernel:init
description: "Initialize KERNEL globally. Sets up Vaults structure, symlinks, CLI, database. Run once per machine."
user-invocable: true
allowed-tools: Bash
---

<command id="init">

<purpose>
Global KERNEL setup. Run once per machine.
Detects existing Vaults location or creates ~/Vaults.
Sets up symlinks, installs agentdb CLI, initializes database.
</purpose>

<detection>
Hooks auto-detect Vaults at (in order):
1. `~/Vaults/_meta/agentdb/agent.db` (standard)
2. `~/Downloads/Vaults/_meta/agentdb/agent.db` (alternate)
3. `$KERNEL_VAULTS` environment variable (custom)
</detection>

<requirements>
- Git installed
- SQLite3 installed
- jq installed (for hooks)
</requirements>

<steps>

## Step 1: Detect or create Vaults

```bash
# Detect existing Vaults
if [ -d "$HOME/Vaults/_meta" ]; then
  VAULTS="$HOME/Vaults"
  echo "Found existing Vaults at $VAULTS"
elif [ -d "$HOME/Downloads/Vaults/_meta" ]; then
  VAULTS="$HOME/Downloads/Vaults"
  echo "Found existing Vaults at $VAULTS"
else
  VAULTS="$HOME/Vaults"
  echo "Creating new Vaults at $VAULTS"
fi

# Create structure
mkdir -p "$VAULTS/_meta"/{agentdb,research,plans,handoffs,agents,logs}
mkdir -p "$VAULTS/.claude"/{rules,commands,skills}
mkdir -p "$VAULTS/.local/bin"
```

## Step 2: Find plugin and install CLI

```bash
# Find plugin in cache (check BEFORE any symlink changes)
PLUGIN_CACHE="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
if [ ! -d "$PLUGIN_CACHE" ]; then
  # Try backup location
  PLUGIN_CACHE="$HOME/.claude.backup"*/plugins/cache/kernel-marketplace/kernel
fi

LATEST=$(ls -1 "$PLUGIN_CACHE" 2>/dev/null | grep -E '^[0-9]' | sort -V | tail -1)

if [ -z "$LATEST" ]; then
  echo "ERROR: Plugin not found. Install first:"
  echo "  claude plugin marketplace add ariaxhan/kernel-claude"
  echo "  claude plugin install kernel"
  exit 1
fi

PLUGIN_ROOT="$PLUGIN_CACHE/$LATEST"
echo "Found plugin at $PLUGIN_ROOT"

# Install agentdb CLI
ln -sf "$PLUGIN_ROOT/orchestration/agentdb/agentdb" "$VAULTS/.local/bin/agentdb"
chmod +x "$VAULTS/.local/bin/agentdb"
echo "Installed agentdb CLI"
```

## Step 3: Set up kernel symlinks for hooks

```bash
mkdir -p "$VAULTS/.claude/kernel"
ln -sfn "$PLUGIN_ROOT/orchestration" "$VAULTS/.claude/kernel/orchestration"
ln -sfn "$PLUGIN_ROOT/hooks" "$VAULTS/.claude/kernel/hooks"
echo "Symlinked kernel components"
```

## Step 4: Symlink ~/.claude (optional but recommended)

This shares Claude config via git across machines.

```bash
# Only if not already symlinked
if [ ! -L "$HOME/.claude" ]; then
  if [ -d "$HOME/.claude" ]; then
    # Preserve plugins before backup
    if [ -d "$HOME/.claude/plugins" ]; then
      cp -r "$HOME/.claude/plugins" "$VAULTS/.claude/plugins"
    fi
    mv "$HOME/.claude" "$HOME/.claude.backup.$(date +%Y%m%d)"
    echo "Backed up ~/.claude"
  fi
  ln -sfn "$VAULTS/.claude" "$HOME/.claude"
  echo "Symlinked ~/.claude → $VAULTS/.claude"
fi
```

## Step 5: Add to PATH

```bash
SHELL_RC="$HOME/.zshrc"
[ -f "$HOME/.bashrc" ] && SHELL_RC="$HOME/.bashrc"

if ! grep -q 'Vaults/.local/bin' "$SHELL_RC" 2>/dev/null; then
  echo '' >> "$SHELL_RC"
  echo '# KERNEL' >> "$SHELL_RC"
  echo 'export PATH="$HOME/Vaults/.local/bin:$PATH"' >> "$SHELL_RC"
  # Also support alternate location
  echo '[ -d "$HOME/Downloads/Vaults/.local/bin" ] && export PATH="$HOME/Downloads/Vaults/.local/bin:$PATH"' >> "$SHELL_RC"
  echo "Added to PATH in $SHELL_RC"
fi

# For current session
export PATH="$VAULTS/.local/bin:$PATH"
```

## Step 6: Initialize AgentDB

```bash
"$VAULTS/.local/bin/agentdb" init 2>/dev/null || \
sqlite3 "$VAULTS/_meta/agentdb/agent.db" "
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
echo "AgentDB initialized"
```

## Step 7: Verify

```bash
echo ""
echo "=== KERNEL INIT COMPLETE ==="
echo ""
echo "Vaults: $VAULTS"
echo ""
echo "Structure:"
ls "$VAULTS/_meta/"
echo ""
echo "AgentDB:"
"$VAULTS/.local/bin/agentdb" status 2>/dev/null || sqlite3 "$VAULTS/_meta/agentdb/agent.db" "SELECT 'Tables:', COUNT(*) FROM sqlite_master WHERE type='table';"
echo ""
echo "Next steps:"
echo "  1. Restart terminal (or: source ~/.zshrc)"
echo "  2. Test: agentdb read-start"
echo "  3. Start Claude Code in any project"
```

</steps>

<one_liner>
Run everything:
```bash
VAULTS="${KERNEL_VAULTS:-$HOME/Vaults}"; \
[ -d "$HOME/Downloads/Vaults/_meta" ] && VAULTS="$HOME/Downloads/Vaults"; \
mkdir -p "$VAULTS/_meta"/{agentdb,research,plans,handoffs,agents,logs} "$VAULTS/.claude"/{rules,commands,skills,kernel} "$VAULTS/.local/bin" && \
PLUGIN_CACHE="$HOME/.claude/plugins/cache/kernel-marketplace/kernel" && \
LATEST=$(ls -1 "$PLUGIN_CACHE" 2>/dev/null | grep -E '^[0-9]' | sort -V | tail -1) && \
[ -n "$LATEST" ] && ln -sf "$PLUGIN_CACHE/$LATEST/orchestration/agentdb/agentdb" "$VAULTS/.local/bin/agentdb" && \
ln -sfn "$PLUGIN_CACHE/$LATEST/orchestration" "$VAULTS/.claude/kernel/orchestration" && \
ln -sfn "$PLUGIN_CACHE/$LATEST/hooks" "$VAULTS/.claude/kernel/hooks" && \
grep -q 'Vaults/.local/bin' ~/.zshrc 2>/dev/null || echo 'export PATH="$HOME/Vaults/.local/bin:$HOME/Downloads/Vaults/.local/bin:$PATH"' >> ~/.zshrc && \
export PATH="$VAULTS/.local/bin:$PATH" && \
"$VAULTS/.local/bin/agentdb" init 2>/dev/null || sqlite3 "$VAULTS/_meta/agentdb/agent.db" "PRAGMA journal_mode=WAL; CREATE TABLE IF NOT EXISTS learnings (id TEXT PRIMARY KEY, ts TEXT DEFAULT CURRENT_TIMESTAMP, type TEXT, insight TEXT NOT NULL, evidence TEXT, domain TEXT, hit_count INTEGER DEFAULT 0); CREATE TABLE IF NOT EXISTS context (id TEXT PRIMARY KEY, ts TEXT DEFAULT CURRENT_TIMESTAMP, type TEXT, contract_id TEXT, agent TEXT, content TEXT NOT NULL); CREATE TABLE IF NOT EXISTS errors (id INTEGER PRIMARY KEY, ts TEXT DEFAULT CURRENT_TIMESTAMP, tool TEXT, error TEXT, file TEXT);" && \
echo "KERNEL initialized at $VAULTS. Restart terminal."
```
</one_liner>

<teammate_onboarding>
For new teammates:

1. Clone Vaults repo (if shared):
   ```bash
   git clone <vaults-repo> ~/Vaults
   ```

2. Install plugin:
   ```bash
   claude plugin marketplace add ariaxhan/kernel-claude
   claude plugin install kernel
   ```

3. Run init:
   ```bash
   /kernel:init
   ```

4. Restart terminal and Claude Code
</teammate_onboarding>

<troubleshooting>
**"agentdb: command not found"**
- Run: `source ~/.zshrc` or restart terminal
- Check: `ls ~/Vaults/.local/bin/agentdb` or `ls ~/Downloads/Vaults/.local/bin/agentdb`

**"Plugin not found"**
- Install plugin first:
  ```bash
  claude plugin marketplace add ariaxhan/kernel-claude
  claude plugin install kernel
  ```

**"Permission denied"**
- Fix: `chmod +x ~/Vaults/.local/bin/agentdb`

**Hooks not running**
- Restart Claude Code after init
- Check: `cat ~/.claude/settings.json` should have hooks section

**Wrong Vaults location**
- Set env var: `export KERNEL_VAULTS="$HOME/path/to/Vaults"`
- Add to ~/.zshrc for persistence
</troubleshooting>

</command>
