#!/bin/bash
# KERNEL: warn when a component bypasses the project's design tokens.
# PreToolUse hook, advisory only, on Write/Edit of component and style files.
#
# REVISED 2026-09-01 after a usage audit: this fired 227 times across the whole
# transcript corpus (92 hex, 135 px) and not one of them changed what the agent
# did next. That is the definition of noise, and noise is not free: it trains a
# reader to skip the line, which is how a real warning gets missed later.
#
# The cause was that it matched things every stylesheet legitimately contains.
# `[0-9]+px` hits a 1px border, a media query breakpoint, a token file DEFINING
# the spacing scale. A warning that fires on correct code is a warning about
# nothing. Three changes, all narrowing:
#
#   1. Token-definition files are exempt. A file whose job is to declare
#      `--space-4: 16px` is not bypassing the scale, it IS the scale.
#   2. px is flagged only on the properties a scale actually governs (padding,
#      margin, gap, font-size). Borders, outlines, radii, media queries and
#      1-2px hairlines are left alone: those are where literal px is correct.
#   3. One line per file, naming the count and the token file to use, instead of
#      one line per category. A warning with no address is advice nobody can act
#      on, which is the other half of why the old one changed nothing.

source "$(dirname "$0")/common.sh"

INPUT=$(cat)
while IFS= read -r RECORD; do
FILE_PATH=$(printf '%s' "$RECORD" | jq -r '.path // empty' 2>/dev/null)
CONTENT=$(printf '%s' "$RECORD" | jq -r '.content // empty' 2>/dev/null)
[ -z "$FILE_PATH" ] && continue

case "$FILE_PATH" in
  *.tsx|*.jsx|*.svelte|*.vue|*.css) ;;
  *) continue ;;
esac

# A file that declares custom properties is the token source, not a consumer.
case "$FILE_PATH" in
  *token*|*theme*|*variable*|*global*|*reset*|*.config.*) continue ;;
esac
# A DECLARATION is `--name:`; a USE is `var(--name)`. Only the former exempts.
# Not anchored to line start: `:root { --gap: 8px; }` is one line and still a
# declaration.
if printf '%s' "$CONTENT" | grep -qE '(^|[[:space:]{;])--[a-zA-Z0-9-]+[[:space:]]*:' 2>/dev/null; then
  continue
fi

HEX=$(printf '%s' "$CONTENT" | grep -oE '#[0-9a-fA-F]{3,8}\b' 2>/dev/null | grep -cv '^$' || true)
# Only the properties a spacing scale governs. Hairlines (1-2px) are exempt
# everywhere: a scale does not have a 1px step and should not pretend to.
PX=$(printf '%s' "$CONTENT" \
  | grep -oE '(padding|margin|gap|font-size)[a-z-]*:[^;]*[0-9]+px' 2>/dev/null \
  | grep -vE '\b[12]px' | grep -cv '^$' || true)

[ "${HEX:-0}" -eq 0 ] && [ "${PX:-0}" -eq 0 ] && continue

TOKENS=""
for candidate in tokens.css theme.css variables.css styles/tokens.css app/styles/tokens.css; do
  [ -f "${CLAUDE_PROJECT_DIR:-.}/$candidate" ] && { TOKENS="$candidate"; break; }
done

WHERE="use the project's design tokens"
[ -n "$TOKENS" ] && WHERE="use the tokens in $TOKENS"

echo "WARN: $FILE_PATH bypasses the scale (${HEX:-0} raw colors, ${PX:-0} spacing px) — $WHERE"
done < <(kernel_hook_file_records "$INPUT")

exit 0
