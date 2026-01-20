---
description: Bump version, update release notes, tag, and push a new release
allowed-tools: Bash, Read, Edit, Write, AskUserQuestion
---

# Release Command

Create a new versioned release of KERNEL.

## Prerequisites

- Must be on `main` branch
- Working tree must be clean (all changes committed)
- GitHub CLI (`gh`) installed for release creation

## Steps

### 1. Verify State

```bash
git branch --show-current
git status --short
```

**If not on main** → Error: "Must be on main branch to release. Merge your changes first."
**If uncommitted changes** → Error: "Working tree not clean. Commit or stash changes first."

### 2. Get Current Version

Read version from `.claude-plugin/plugin.json`:

```bash
cat .claude-plugin/plugin.json | grep '"version"'
```

Parse current version (e.g., `1.2.0` → major=1, minor=2, patch=0).

### 3. Ask for Version Bump

Prompt user:
- **patch** (1.2.0 → 1.2.1) - Bug fixes, small changes
- **minor** (1.2.0 → 1.3.0) - New features, backwards compatible
- **major** (1.2.0 → 2.0.0) - Breaking changes

### 4. Ask for Release Summary

Prompt user for a brief description of what's new in this release.
Use this for the commit message and release notes.

### 5. Update Version Files

Update BOTH version locations:

1. `.claude-plugin/plugin.json`
2. `kernel/.claude-plugin/plugin.json`

Replace the old version string with the new version.

### 6. Update RELEASE_NOTES.md (Optional)

Ask if user wants to prepend release notes.
If yes, add section at top:

```markdown
# KERNEL vX.Y.Z

**Release Date**: [current date]

## What's New

- [User-provided summary items]

---

[Previous content below]
```

### 7. Commit

```bash
git add -A
git commit -m "$(cat <<'EOF'
Bump version to X.Y.Z

New in this release:
- [summary items]

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### 8. Tag

```bash
git tag vX.Y.Z
```

### 9. Push

```bash
git push origin main
git push origin vX.Y.Z
```

### 10. Create GitHub Release (Optional)

Ask if user wants to create a GitHub release:

```bash
gh release create vX.Y.Z --title "KERNEL vX.Y.Z" --notes "[release summary]"
```

### 11. Report

Display:
- Previous version → New version
- Git tag created
- Release URL (if created)
- Reminder: "Users can update via plugin marketplace"

## Version Locations

Both files must stay in sync:

| File | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | Root plugin manifest |
| `kernel/.claude-plugin/plugin.json` | Distributed plugin manifest |

## Example Run

```
Current version: 1.2.0
Bump type: minor
New version: 1.3.0

Summary: Added /release command for automated versioning

✓ Updated .claude-plugin/plugin.json
✓ Updated kernel/.claude-plugin/plugin.json
✓ Committed: "Bump version to 1.3.0"
✓ Tagged: v1.3.0
✓ Pushed to origin
✓ Created GitHub release

Release v1.3.0 complete!
```
