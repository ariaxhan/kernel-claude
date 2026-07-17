#!/bin/bash
# PostToolUse hook: scan tool OUTPUT for indirect prompt-injection payloads (T2/T4).
# Events: PostToolUse (matcher: WebFetch|WebSearch|mcp__.*)
#
# WARN-ONLY by design: 8.2.0 ships injection *detection* warn-first so false
# positives can be tuned on real traffic before anything ever blocks. On a finding
# it exits 2 -- for PostToolUse that does not undo the tool call; it feeds stderr
# back to the model as a visible warning to treat the content as untrusted data.
# Clean output exits 0 silently.
#
# Honest scope: heuristic phrase/character detection is a TRIPWIRE that raises
# attacker cost (literature puts detection at ~40-84%), not containment. Real
# containment is the OS sandbox + egress control this hook sits inside.
#
# Does NOT source circuit-breaker.sh: a security tripwire never auto-disables
# itself (I0.15). Degrades silently if python3 is missing (never breaks the tool
# loop -- this hook only ever warns).

command -v python3 >/dev/null 2>&1 || exit 0
exec python3 "$(dirname "$0")/scan-output.py"
