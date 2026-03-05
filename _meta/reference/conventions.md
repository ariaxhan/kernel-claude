# Code Conventions

**Type:** preference | **Load:** on-demand

Negotiable defaults. Override per-task or per-project.

---

## Formatting

- **Indentation:** 2 spaces (JS/YAML), 4 spaces (Python)
- **Line length:** 100 soft, 120 hard
- **Trailing commas:** Yes
- **Semicolons:** Minimal in JS (ASI where safe)

---

## Comments

Line comments for WHY, not WHAT. Block comments for complex algorithms. JSDoc/docstrings for public APIs only.

---

## Tools

- **Package manager:** npm (unless project specifies)
- **Testing:** Jest (unless project specifies)
- **Linting:** ESLint + Prettier (JS), Black (Python)
- **Git format:** Conventional commits: `{type}({scope}): {description}`
  - Types: feat, fix, chore, refactor, docs, test, perf, ci

---

## Documentation

- **README:** setup and quick start
- **Inline comments:** non-obvious logic only
- **ARCHITECTURE.md:** system design
- **Changelog:** automated from commits

---

## Enforcement

Linter enforces formatting. Code review nudges toward preferences. Override when project context differs.
