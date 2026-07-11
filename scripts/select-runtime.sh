#!/bin/bash
set -euo pipefail

ROOT="${1:-${KERNEL_RUNTIME_ROOT:-}}"
if [ -z "$ROOT" ]; then
  echo "Usage: scripts/select-runtime.sh /path/to/kernel-runtime" >&2
  exit 2
fi
ROOT=$(cd "$ROOT" 2>/dev/null && pwd) || { echo "kernel: runtime root does not exist: $ROOT" >&2; exit 1; }
[ -f "$ROOT/hooks/scripts/common.sh" ] || { echo "kernel: missing hooks/scripts/common.sh in $ROOT" >&2; exit 1; }

source "$ROOT/hooks/scripts/common.sh"
KERNEL_RUNTIME_ROOT="$ROOT"
export KERNEL_RUNTIME_ROOT
version=$(kernel_validate_runtime_root "$ROOT") || { echo "kernel: invalid KERNEL runtime: $ROOT" >&2; exit 1; }
vaults=$(detect_vaults)
kernel_reconcile_runtime "$vaults" || {
  echo "kernel: runtime selected, but one or more host links were left unchanged; run /kernel:init" >&2
  exit 1
}

echo "KERNEL runtime: $version"
echo "Runtime root: $ROOT"
echo "Vaults: $vaults"
echo "No project files, AgentDB records, manifests, or caches were deleted."
