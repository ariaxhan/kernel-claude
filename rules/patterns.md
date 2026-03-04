# Patterns

**Type:** pattern

## Principle

Discovered conventions and behaviors across projects. Auto-updated as we encounter repetition. Becomes baseline for new code.

## Implementation

### Naming Conventions
- Threads: `{domain}_{concept}` (e.g., `agent_spawning`, `pdf_entropy`)
- Files: kebab-case for resources, snake_case for modules
- Git branches: `{type}/{scope}` (feature/auth-middleware, fix/query-timeout)

### Error Handling
- Try-catch patterns capture failures, never swallow silently
- Errors logged with context (function, inputs, stack)
- User-facing: clear, actionable messages

### Logging Patterns
- DEBUG: function entry/exit, variable states
- INFO: workflow transitions, user actions
- WARN: recoverable issues, degradation
- ERROR: failures, with recovery steps

### Testing Strategy
- Unit tests for isolated functions
- Integration tests for service boundaries
- E2E tests for critical paths only
- Test naming: `test_{function}_{scenario}_{expected}`

## Enforcement

- Linter checks naming conventions
- Code review validates patterns applied
- New patterns logged when discovered

## Evolution

Updated every discovery cycle. Patterns stabilize into conventions. Stale patterns (>6 months unused) archived.
