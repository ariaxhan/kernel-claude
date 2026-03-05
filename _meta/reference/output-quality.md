# Output Quality

**Type:** invariant | **Load:** on-demand

Quality standards for all output: code, communication, artifacts.

---

## Code Output

- **Smallest change that works.** No gold plating.
- **Follow existing patterns** in codebase. Don't introduce new patterns without justification.
- **Error handling:** catch, log with context, surface actionable message. Never swallow.
- **Naming:** descriptive, consistent with codebase conventions.
- **No dead code,** no commented-out code, no TODO without ticket/issue reference.

---

## Communication

- **All user-facing output:** non-technical, clear, zero code knowledge required.
- **When presenting issues:** numbered, with options lettered (A, B, C). Recommended option first.
- **Surface failures,** blockers, and decisions. Never hide.
- **After each major section of work,** pause and ask for feedback before continuing.

---

## Evidence

- **Every claim** backed by actual output (paste stdout/stderr, not "it works").
- **Every decision** has a stated reason.
- **Every agent** writes evidence to AgentDB, not conversation.

---

## Output Validation

- **Validate agent output** before passing downstream. Bad output cascades.
- **Surgeon checkpoint** must include: files changed, evidence, commit hash.
- **Adversary verdict** must include: tests run, actual output, pass/fail.
- **Missing fields** → reject and re-request. Never assume completion without reading AgentDB.
