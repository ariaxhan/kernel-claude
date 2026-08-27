#!/bin/bash
# complexity.sh <repo-dir> [base-ref]
#
# Cyclomatic complexity per function, worst first. The measurement lane behind
# /kernel:simplify and the review skill's complexity check: a number a tool produced, not a
# question the model answers about itself.
#
# Uses lizard (polyglot: Python, JS/TS, Go, Rust, Swift, Java, C, ...). Runs it from PATH,
# else via `uvx lizard` (no install). Neither present: prints SKIPPED and exits 3, never a
# silent pass.
#
# Diff mode (base-ref given): only files changed since base-ref are measured.
# Threshold: $CCN_MAX (default 15). A project linter config with its own complexity
# threshold outranks this default; the caller passes it through CCN_MAX.
#
# Output: TSV to stdout, file<TAB>line<TAB>function<TAB>ccn<TAB>nloc, sorted by ccn desc,
#         only functions at or above CCN_MAX. Exit 0 if none, 1 if any, 3 if no tool.
set -u

REPO="${1:?usage: complexity.sh <repo-dir> [base-ref]}"
BASE="${2:-}"
CCN_MAX="${CCN_MAX:-15}"
cd "$REPO" || exit 2

if command -v lizard >/dev/null; then LIZ=(lizard)
elif command -v uvx >/dev/null; then LIZ=(uvx --quiet lizard)
else echo "lizard SKIPPED (install: pip install lizard, or have uvx on PATH)" >&2; exit 3; fi

EXCL=(-x '*/node_modules/*' -x '*/dist/*' -x '*/build/*' -x '*/.venv/*' -x '*/venv/*'
      -x '*/.svelte-kit/*' -x '*/.next/*' -x '*/vendor/*' -x '*/graphify-out/*' -x '*.min.js')

TARGETS=()
if [ -n "$BASE" ]; then
  while IFS= read -r f; do [ -n "$f" ] && [ -f "$f" ] && TARGETS+=("$f"); done < <(
    git diff --name-only --diff-filter=d "$BASE"...HEAD 2>/dev/null || git diff --name-only --diff-filter=d "$BASE"..HEAD)
  [ "${#TARGETS[@]}" -eq 0 ] && exit 0
else
  TARGETS=(.)
fi

# lizard -w prints one warning per function over the threshold:
#   path:line: warning: name has N NLOC, M CCN, ...
OUT="$("${LIZ[@]}" -w -C "$CCN_MAX" "${EXCL[@]}" "${TARGETS[@]}" 2>/dev/null \
  | sed -E 's#^\./##; s/^([^:]+):([0-9]+): warning: (.+) has ([0-9]+) NLOC, ([0-9]+) CCN.*$/\1\t\2\t\3\t\5\t\4/' \
  | awk -F'\t' 'NF==5 && $2 ~ /^[0-9]+$/ && $4 ~ /^[0-9]+$/' \
  | sort -t"$(printf '\t')" -k4,4nr -k1,1)"
[ -z "$OUT" ] && exit 0
printf '%s\n' "$OUT"
exit 1
