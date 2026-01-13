---
description: Ship branch - commit, push, create PR, and optionally release
allowed-tools: Bash, Read, AskUserQuestion
---

# Ship Command

Commit remaining work, push branch, create PR. Optionally tag a release.

## Steps

1. **Check state**
   ```bash
   git status --short
   git branch --show-current
   git log origin/main..HEAD --oneline
   ```

2. **If on main** → Error: "Cannot ship from main. Create a branch first."

3. **If uncommitted changes**
   - Stage all: `git add -A`
   - Generate commit message from changes
   - Commit with conventional format

4. **Push branch**
   ```bash
   git push -u origin $(git branch --show-current)
   ```

5. **Create PR**
   - Generate title from branch name
   - Generate body from commit history
   ```bash
   gh pr create --title "..." --body "..."
   ```

6. **Check for release intent**

   If branch name contains version (e.g., `v1.4.0`) or user requests release:
   - Ask: "Create a release after PR merge?"

   If yes, provide release instructions:
   ```
   After PR is merged, run:

   git checkout main && git pull
   git tag -a v1.4.0 -m "Release v1.4.0: <description>"
   git push origin v1.4.0
   gh release create v1.4.0 --title "v1.4.0" --notes-file RELEASE_NOTES.md
   ```

7. **Report**
   - PR URL
   - Release instructions (if applicable)
   - Ask: "Switch to main and create new branch for next task?"

---

## Release Workflow (When Requested)

If user explicitly requests a release with `/ship`:

### Pre-release Checks
1. Verify version consistency across files:
   - `.claude-plugin/plugin.json`
   - `kernel/.claude-plugin/plugin.json`
   - `RELEASE_NOTES.md`

2. Ensure RELEASE_NOTES.md documents the version

### After PR Merge
```bash
# Switch to main and pull
git checkout main && git pull

# Create annotated tag
git tag -a v<VERSION> -m "Release v<VERSION>: <summary>"

# Push tag
git push origin v<VERSION>

# Create GitHub release
gh release create v<VERSION> \
  --title "v<VERSION>" \
  --notes "See RELEASE_NOTES.md for full changelog"
```

### Version Consistency Check
```bash
# Verify all version references match
grep -r '"version"' .claude-plugin/ kernel/.claude-plugin/ | grep -o '"[0-9.]*"'
head -1 RELEASE_NOTES.md
```

---

## Commit Message Format

```
<type>(<scope>): <description>

- Change 1
- Change 2

Co-Authored-By: Claude <noreply@anthropic.com>
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
