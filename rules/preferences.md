# Preferences

**Type:** preference

## Principle

Negotiable defaults. Can be overridden per-task or per-project. These are Aria's style, not law.

## Implementation

### Formatting
- Indentation: 2 spaces (JS/YAML), 4 spaces (Python)
- Line length: 100 characters soft, 120 hard
- Trailing commas: yes (modern tooling standard)
- Semicolons: minimal in JS (rely on ASI where safe)

### Comment Style
- Line comments for why, not what (code shows what)
- Block comments for complex algorithms
- JSDoc/docstrings required for public APIs only

### Tool Choices
- Package manager: npm (unless project specifies otherwise)
- Testing: Jest (unless project specifies otherwise)
- Linting: ESLint + Prettier (JS), Black (Python)
- Version control: Git with conventional commits

### Git Commits
- No Co-Authored-By trailers. Ever. Commits are attributed to the human author only.
- Conventional commit format: `type(scope): description`
- Types: feat, fix, chore, refactor, docs, test, perf, ci
- Scope: repo name or feature area

### Documentation
- README for setup and quick start
- Inline comments for non-obvious logic
- ARCHITECTURE.md for system design
- Changelog automated from commits

## Enforcement

Linter enforces formatting. Code review nudges toward preferences. Override when project context differs.

## Evolution

Can be changed per-project without formal approval. Global changes require opt-in survey.
