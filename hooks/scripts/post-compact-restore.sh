#!/bin/bash
# KERNEL: Restore context after compaction
# Event: UserPromptSubmit (fires on every user message)
# Fast exit (~1ms) when no compaction marker exists

# Load shared functions
source "$(dirname "$0")/common.sh"

# Detect paths
PROJECT_ROOT=$(get_project_root)
MARKER="$PROJECT_ROOT/_meta/.compact-marker"

# Fast exit if no compaction happened
[ ! -f "$MARKER" ] && exit 0

# Restore context
echo "## Context Restored After Compaction"
echo ""
cat "$MARKER"
echo ""

# Clean up marker (one-shot restoration)
rm -f "$MARKER"

exit 0
