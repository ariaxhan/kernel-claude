---
name: kernel:init
description: "Initialize KERNEL globally. Sets up Vaults, symlinks, CLI, database."
user-invocable: true
allowed-tools: Bash
---

<command id="init">

<purpose>
Global KERNEL setup. Run once per machine. Detects existing Vaults or creates ~/Vaults.
</purpose>

<detection>
Hooks auto-detect: `~/Vaults` → `~/Downloads/Vaults` → `$KERNEL_VAULTS`
</detection>

<requirements>Git, SQLite3, jq</requirements>

<steps>

## Step 1: Detect/create Vaults + find plugin

```bash
# Detect existing
if [ -d "$HOME/Vaults/_meta" ]; then VAULTS="$HOME/Vaults"
elif [ -d "$HOME/Downloads/Vaults/_meta" ]; then VAULTS="$HOME/Downloads/Vaults"
else VAULTS="$HOME/Vaults"; fi
echo "Vaults: $VAULTS"

# Create structure
mkdir -p "$VAULTS/_meta"/{agentdb,research,plans,handoffs,agents,logs}
mkdir -p "$VAULTS/.claude"/{rules,commands,skills,kernel}
mkdir -p "$VAULTS/.local/bin"

# Find plugin
PLUGIN_CACHE="$HOME/.claude/plugins/cache/kernel-marketplace/kernel"
LATEST=$(ls -1 "$PLUGIN_CACHE" 2>/dev/null | grep -E '^[0-9]' | sort -V | tail -1)
[ -z "$LATEST" ] && echo "ERROR: Install plugin first" && exit 1
PLUGIN_ROOT="$PLUGIN_CACHE/$LATEST"
```

## Step 2: Install CLI + symlinks

```bash
# CLI
ln -sf "$PLUGIN_ROOT/orchestration/agentdb/agentdb" "$VAULTS/.local/bin/agentdb"
chmod +x "$VAULTS/.local/bin/agentdb"

# Kernel symlinks (for hooks)
ln -sfn "$PLUGIN_ROOT/orchestration" "$VAULTS/.claude/kernel/orchestration"
ln -sfn "$PLUGIN_ROOT/hooks" "$VAULTS/.claude/kernel/hooks"
```

## Step 3: Symlink ~/.claude (optional)

```bash
if [ ! -L "$HOME/.claude" ]; then
  [ -d "$HOME/.claude/plugins" ] && cp -r "$HOME/.claude/plugins" "$VAULTS/.claude/"
  [ -d "$HOME/.claude" ] && mv "$HOME/.claude" "$HOME/.claude.backup.$(date +%Y%m%d)"
  ln -sfn "$VAULTS/.claude" "$HOME/.claude"
fi
```

## Step 4: PATH + init DB

```bash
SHELL_RC="$HOME/.zshrc"
grep -q 'Vaults/.local/bin' "$SHELL_RC" 2>/dev/null || \
  echo 'export PATH="$HOME/Vaults/.local/bin:$HOME/Downloads/Vaults/.local/bin:$PATH"' >> "$SHELL_RC"
export PATH="$VAULTS/.local/bin:$PATH"

agentdb init
```

<ask_user>
  Use AskUserQuestion when: detection complete, before creating/modifying directories
  Ask: "Detected Vaults at {path}. Proceed with setup, or use a different location?"
  Options: proceed, use different path, abort
</ask_user>

## Step 5: Verify

```bash
echo "=== KERNEL INIT COMPLETE ==="
echo "Vaults: $VAULTS"
ls "$VAULTS/_meta/"
agentdb status
echo "Next: restart terminal, then: agentdb read-start"
```

</steps>

<one_liner>
```bash
VAULTS="${KERNEL_VAULTS:-$HOME/Vaults}"; [ -d "$HOME/Downloads/Vaults/_meta" ] && VAULTS="$HOME/Downloads/Vaults"; \
mkdir -p "$VAULTS/_meta"/{agentdb,research,plans,handoffs,agents,logs} "$VAULTS/.claude"/{rules,commands,skills,kernel} "$VAULTS/.local/bin" && \
PLUGIN_CACHE="$HOME/.claude/plugins/cache/kernel-marketplace/kernel" && \
LATEST=$(ls -1 "$PLUGIN_CACHE" 2>/dev/null | grep -E '^[0-9]' | sort -V | tail -1) && \
ln -sf "$PLUGIN_CACHE/$LATEST/orchestration/agentdb/agentdb" "$VAULTS/.local/bin/agentdb" && \
ln -sfn "$PLUGIN_CACHE/$LATEST/orchestration" "$VAULTS/.claude/kernel/orchestration" && \
ln -sfn "$PLUGIN_CACHE/$LATEST/hooks" "$VAULTS/.claude/kernel/hooks" && \
grep -q 'Vaults/.local/bin' ~/.zshrc 2>/dev/null || echo 'export PATH="$HOME/Vaults/.local/bin:$HOME/Downloads/Vaults/.local/bin:$PATH"' >> ~/.zshrc && \
export PATH="$VAULTS/.local/bin:$PATH" && agentdb init && echo "Done. Restart terminal."
```
</one_liner>

<teammate_onboarding>
1. `git clone <vaults-repo> ~/Vaults` (if shared)
2. `claude plugin marketplace add ariaxhan/kernel-claude && claude plugin install kernel`
3. `/kernel:init`
4. Restart terminal + Claude Code
</teammate_onboarding>

<troubleshooting>
- **agentdb not found**: `source ~/.zshrc` or restart terminal
- **plugin not found**: install plugin first (see step 2 above)
- **permission denied**: `chmod +x ~/Vaults/.local/bin/agentdb`
- **wrong Vaults**: `export KERNEL_VAULTS="$HOME/path/to/Vaults"` in ~/.zshrc
</troubleshooting>

</command>
