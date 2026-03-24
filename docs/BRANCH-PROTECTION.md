# Branch Protection

Recommended GitHub branch protection rules for the `main` branch.

## Settings

Go to **Settings > Branches > Add rule** for `main`:

1. **Require status checks to pass before merging**
   - Add required check: `shellcheck`
   - Add required check: `tests`
   - Add required check: `schema-check`
   - These come from the "Tests & Quality" workflow

2. **Require a pull request before merging**
   - Require at least 1 approval
   - Dismiss stale reviews when new commits are pushed

3. **Do not allow force pushes**

4. **Do not allow deletions**

## Why

These rules ensure that no code reaches `main` without passing
shellcheck, the full test suite, and schema consistency verification.
PR reviews catch logic and design issues that automated checks miss.
