#!/bin/bash
# deterministic-review.sh <repo-dir> [base-ref]
#
# The deterministic lane of a code review: runs every installed free analyzer in parallel,
# normalizes findings to one TSV, and exits nonzero only on HIGH-signal classes (secrets,
# security SAST, high CVEs, workflow injection). Missing tools skip their lane and are
# REPORTED as skipped, never silently dropped — the LLM lane must know what was not checked.
#
# Diff mode (base-ref given): only changed files feed file-scoped lanes; semgrep uses
# --baseline-commit so only NEW findings surface. Full-repo mode otherwise.
#
# Output: $OUT_DIR/findings.tsv (file<TAB>line<TAB>tool<TAB>severity<TAB>message),
#         $OUT_DIR/lanes.txt (per-lane RAN/SKIPPED), both echoed to stdout.
#
# Install the lanes (all free; any subset works, missing ones are reported as SKIPPED):
#   brew install gitleaks semgrep actionlint zizmor osv-scanner shellcheck jq
#   project ESLint or lizard/uvx (complexity lane; .ccnrc budgets apply)
# Licensing: semgrep Community rules are internal-use only (no resale/SaaS on top of them);
# gitleaks/actionlint/zizmor MIT, osv-scanner Apache-2.0, shellcheck GPL-3.0 (tool-only).
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="${1:?usage: deterministic-review.sh <repo-dir> [base-ref]}"
BASE="${2:-}"
cd "$REPO" || exit 2
git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repo: $REPO" >&2; exit 2; }

OUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/detreview.$$.XXXXXX")"
T="$OUT_DIR/raw"; mkdir -p "$T"
echo "output: $OUT_DIR"

CHANGED=""
if [ -n "$BASE" ]; then
  CHANGED="$(git diff --name-only --diff-filter=d "$BASE"...HEAD 2>/dev/null || git diff --name-only --diff-filter=d "$BASE"..HEAD)"
fi
filter_ext() { # filter_ext 'regex' — changed files matching, or empty in full-repo mode
  [ -n "$CHANGED" ] && printf '%s\n' "$CHANGED" | grep -E "$1" || true
}

LANES="$OUT_DIR/lanes.txt"; : > "$LANES"
note() { printf '%-12s %s\n' "$1" "$2" >> "$LANES"; }

# --- lanes, all backgrounded -----------------------------------------------------------
if command -v gitleaks >/dev/null; then
  ( if [ -n "$BASE" ]; then gitleaks git --no-banner -f json -r "$T/gitleaks.json" --log-opts="$BASE..HEAD" . >/dev/null 2>&1
    else gitleaks detect --source . --no-banner -f json -r "$T/gitleaks.json" >/dev/null 2>&1; fi ) &
  note gitleaks RAN
else note gitleaks SKIPPED; fi

if command -v semgrep >/dev/null; then
  ( semgrep scan --config p/security-audit --json --quiet ${BASE:+--baseline-commit "$BASE"} > "$T/semgrep.json" 2>/dev/null ) &
  note semgrep RAN
else note semgrep SKIPPED; fi

TS_FILES="$(filter_ext '\.(ts|tsx|js|jsx|mjs)$')"
if npx --no-install eslint --version >/dev/null 2>&1 && { [ -z "$BASE" ] || [ -n "$TS_FILES" ]; }; then
  ( if [ -n "$TS_FILES" ]; then printf '%s\n' "$TS_FILES" | xargs npx --no-install eslint -f json > "$T/eslint.json" 2>/dev/null
    else npx --no-install eslint -f json . > "$T/eslint.json" 2>/dev/null; fi; true ) &
  note eslint RAN
else note eslint SKIPPED; fi

PY_FILES="$(filter_ext '\.py$')"
if command -v ruff >/dev/null && { [ -z "$BASE" ] || [ -n "$PY_FILES" ]; }; then
  ( if [ -n "$PY_FILES" ]; then printf '%s\n' "$PY_FILES" | xargs ruff check --select E9,F,S,B --output-format json > "$T/ruff.json" 2>/dev/null
    else ruff check --select E9,F,S,B --output-format json . > "$T/ruff.json" 2>/dev/null; fi; true ) &
  note ruff RAN
else note ruff SKIPPED; fi

SH_FILES="$(filter_ext '\.(sh|bash)$')"
if command -v shellcheck >/dev/null; then
  if [ -n "$SH_FILES" ]; then ( printf '%s\n' "$SH_FILES" | xargs shellcheck -f json > "$T/shellcheck.json" 2>/dev/null; true ) & note shellcheck RAN
  elif [ -z "$BASE" ]; then ( git ls-files '*.sh' '*.bash' | xargs -r shellcheck -f json > "$T/shellcheck.json" 2>/dev/null; true ) & note shellcheck RAN
  else note shellcheck SKIPPED; fi
else note shellcheck SKIPPED; fi

if command -v actionlint >/dev/null && [ -d .github/workflows ]; then
  ( actionlint -format '{{json .}}' > "$T/actionlint.json" 2>/dev/null; true ) &
  note actionlint RAN
else note actionlint SKIPPED; fi

if command -v zizmor >/dev/null && [ -d .github/workflows ]; then
  ( zizmor --format json .github/workflows > "$T/zizmor.json" 2>/dev/null; true ) &
  note zizmor RAN
else note zizmor SKIPPED; fi

if command -v osv-scanner >/dev/null; then
  ( osv-scanner scan --format json -r . > "$T/osv.json" 2>/dev/null; true ) &
  note osv-scanner RAN
else note osv-scanner SKIPPED; fi

CX_SH="$SCRIPT_DIR/complexity.sh"
CX_AVAILABLE=0
if [ -x "$CX_SH" ]; then
  CX_AVAILABLE=1
  ( rc=0; "$CX_SH" . ${BASE:+"$BASE"} > "$T/complexity.tsv" 2>"$T/complexity.err" || rc=$?; printf '%s\n' "$rc" > "$T/complexity.rc" ) &
else note complexity SKIPPED; fi

wait

if [ "$CX_AVAILABLE" -eq 1 ]; then
  CX_RC="$(cat "$T/complexity.rc" 2>/dev/null || echo 2)"
  if [ "$CX_RC" -eq 0 ] || [ "$CX_RC" -eq 1 ]; then
    note complexity RAN
  else
    note complexity NOT_CHECKED
    sed 's/^/complexity: /' "$T/complexity.err" >&2
  fi
fi

# --- normalize -------------------------------------------------------------------------
F="$OUT_DIR/findings.tsv"; : > "$F"
J() { command -v jq >/dev/null && [ -s "$1" ]; }

J "$T/gitleaks.json" && jq -r '.[] | [.File, (.StartLine|tostring), "gitleaks", "HIGH", ("secret: " + .RuleID)] | @tsv' "$T/gitleaks.json" >> "$F" 2>/dev/null
J "$T/semgrep.json" && jq -r '.results[]? | [.path, (.start.line|tostring), "semgrep", (if .extra.severity=="ERROR" then "HIGH" else "MED" end), .check_id] | @tsv' "$T/semgrep.json" >> "$F" 2>/dev/null
J "$T/eslint.json" && jq -r '.[] | .filePath as $f | .messages[]? | [$f, ((.line//0)|tostring), "eslint", (if .severity==2 then "MED" else "LOW" end), (.ruleId // "parse") + ": " + .message] | @tsv' "$T/eslint.json" >> "$F" 2>/dev/null
J "$T/ruff.json" && jq -r '.[] | [.filename, (.location.row|tostring), "ruff", (if (.code//"" | startswith("S")) then "HIGH" else "MED" end), (.code//"") + ": " + .message] | @tsv' "$T/ruff.json" >> "$F" 2>/dev/null
J "$T/shellcheck.json" && jq -r '.[] | [.file, (.line|tostring), "shellcheck", (if .level=="error" then "MED" else "LOW" end), ("SC" + (.code|tostring) + ": " + .message)] | @tsv' "$T/shellcheck.json" >> "$F" 2>/dev/null
J "$T/actionlint.json" && jq -r '.[] | [.filepath, (.line|tostring), "actionlint", "MED", .message] | @tsv' "$T/actionlint.json" >> "$F" 2>/dev/null
J "$T/zizmor.json" && jq -r '.[]? | (.locations[0].symbolic.key.Local.given_path // "workflow") as $f | [$f, "0", "zizmor", (if .determinations.severity=="High" then "HIGH" else "MED" end), .ident] | @tsv' "$T/zizmor.json" >> "$F" 2>/dev/null
J "$T/osv.json" && jq -r '.results[]?.packages[]? | .package.name as $p | .vulnerabilities[]? | [$p, "0", "osv-scanner", (if ((.database_specific.severity//"")|ascii_downcase)=="critical" or ((.database_specific.severity//"")|ascii_downcase)=="high" then "HIGH" else "MED" end), .id] | @tsv' "$T/osv.json" >> "$F" 2>/dev/null

[ -s "$T/complexity.tsv" ] && awk -F'\t' 'BEGIN{OFS="\t"} {print $1, $2, "complexity", "MED", $3 " CCN " $4 " (over declared budget)"}' "$T/complexity.tsv" >> "$F"

sort -t"$(printf '\t')" -k4,4 -k1,1 -o "$F" "$F"

echo "=== lanes ==="; cat "$LANES"
echo "=== findings ($(wc -l < "$F" | tr -d ' ')) ==="; cat "$F"

grep -q "$(printf '\t')HIGH$(printf '\t')" "$F" && exit 1 || exit 0
