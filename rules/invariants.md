# Invariants

**Type:** invariant

## Principle

Non-negotiable contracts. These cannot be violated without consent from Aria. Violations are critical failures.

## Implementation

- **Security:** No hardcoded secrets (keys, tokens, credentials). Environment variables or secure vaults only.
- **Integrity:** Atomic commits. One logical change = one commit. Never cherry-pick across features.
- **Stability:** Tests pass before merge. Breaking changes require migration guides.
- **Data:** No irreversible operations without explicit confirmation. Rollback always possible.
- **Transparency:** Every decision logged. Every change has a reason. No silent failures.
- **Autonomy:** Read-only operations always permitted. Write operations: pause if ambiguous intent.

## Enforcement

- Pre-commit hook validates: no secrets, commit message format, test status
- Code review blocks merge if invariant violated
- Subagents report violations immediately
- Logging captures all invariant checks

## Evolution

Updated when business logic or security requirements change. Aria approves additions. Deletions require explicit removal request.
