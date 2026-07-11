# Tear Down: KERNEL 8.0.0 public release

reviewed: 2026-07-10T23:24:00-07:00
tier: 3
contract: CR-20260710230612-3608-15396
amendment: CR-20260710230917-7292-20019
scope: release runtime, host-link migration, public docs, metadata, tests, and release gates

## Verdict: REVISE

The release goal is right and `8.0.0` is the honest version: canonical JSON manifests,
the commands-to-skills migration, and changed resume behavior are breaking enough to warrant
a major release. The proposed `current` indirection is also the smallest viable architecture.
It is not safe to implement the plan exactly as written, however. The plan does not yet name
a trustworthy authority for what `current` means, does not make link replacement mechanically
safe, and understates the migration surface in user docs, contributor docs, workflows, and
tests. Those are quiet upgrade failures affecting real installations, so implementation must
start only after the amendments below are accepted into the surgeon contract.

## Alternatives considered

### 1. Chosen after revision: one validated `current` selector plus conservative self-heal

Host links point through one stable cache link; startup repairs only links proven to be old
KERNEL-owned cache links. This centralizes selection and preserves project data. It is the
simplest safe choice **only if** the selected version comes from the actually loaded/installed
plugin (or an explicit rollback override), not merely the numerically highest cache directory.

### 2. Require `/kernel:init` after every update

Smaller code diff, unsafe user experience. Auto-update can activate v8 before the user reads
release notes, and old numbered cache directories may disappear after the documented grace
period. Keep init as explicit recovery, never as the only migration gate.

### 3. Copy helpers into each Vaults or rediscover a version at every entry point

Copying creates a second unmanaged installation. Rediscovery duplicates version-selection
logic and can disagree between hooks, AgentDB, and orchestration. Both make drift harder to
see and rollback harder to reason about. Reject both.

## Big 5

| Check | Result | Evidence / required correction |
|---|---|---|
| Input validation | FAIL | `common.sh` accepts any semver-shaped directory and never validates `plugin.json`, expected helper paths, link ownership, or the active installed version. |
| Edge cases | FAIL | Rollback with an orphaned higher cache, concurrent old/new sessions, broken relative links, spaces/newlines in paths, missing links, read-only cache, and user-owned paths are unspecified. |
| Error handling | FAIL | `_kernel_hook_start` redirects selector output/errors and forces success. A failed migration is invisible even when it leaves mixed versions. |
| Duplication | FAIL | Vaults detection and exact-version linking are repeated with different order/behavior in `skills/init/SKILL.md`, its one-liner, and `hooks/scripts/common.sh`. |
| Complexity | PASS WITH CONSTRAINT | One selector plus one repair helper is understandable. Do not scatter migration branches across every hook. Keep pure validation/classification helpers separate from mutation. |

## Security

- No auth/network boundary is added, but this changes executable link targets and is therefore
  supply-chain sensitive. Validate the cache root, exact target shape, manifest identity/name,
  manifest version, and required executable paths before repointing anything.
- Never overwrite a regular file, directory, or unrelated symlink. Refuse and print the exact
  path plus a manual recovery command. Do not follow a symlink to classify ownership.
- Construct a temporary sibling symlink and atomically rename it only after classification.
  The temp name must be collision-safe and cleaned on failure/signals.
- Do not use `eval`, unquoted expansion, `ls | xargs`, or a path derived from writable manifest
  content. Cache discovery is hostile input even though it is local.
- Preserve `_meta/agentdb`, handoffs, checkpoints, receipts, project instructions, and all
  user repositories. No migration should rewrite their contents.

## Empirical link probe

The probe ran only under `/tmp/kernel-link-probe.*` on macOS. Results:

```text
old numbered symlink + ln -sfn -> replaced with current target
regular file + ln -sfn          -> exit 0; path became a directory containing a link
regular directory + ln -sfn     -> exit 0; link inserted inside directory
```

This proves `ln -sfn NEW DEST` is not an ownership check and cannot be the migration primitive.
It can silently mutate user-owned destinations while returning success. A separate probe also
showed `mv -f` replaces a symlink, reinforcing that classification must happen immediately
before mutation and that only a provably KERNEL-owned link may reach the rename step.

## Architecture findings

### A. `current` has no safe authority yet

`hooks/scripts/common.sh:13-46` defines `current` as the highest semver-shaped directory. The
official-source audit explicitly says cached older/newer versions may coexist and rollback must
not mean “highest directory wins.” The implementation contract must choose and test authority:

1. Prefer the plugin version/root that Claude Code actually loaded for this hook invocation.
2. Allow an explicit, documented rollback override if durable rollback needs to keep a lower
   marketplace/cache version active while a higher orphan remains.
3. Never infer active installation from directory maximum alone.

There is a concurrency hazard: an old session and a reloaded v8 session can both run hooks. If
each invocation rewrites `current` based on its own code root, the link can flap. The surgeon
must define a monotonic normal-update rule plus an explicit rollback rule, then red-test an
interleaving. “Every hook picks itself” is not sufficient.

### B. Repair ownership needs a formal predicate

For each of exactly three host paths, replacement is allowed only when `lstat` says symlink and
its lexical target resolves to:

```text
<recognized kernel cache>/<strict semver>/orchestration/agentdb/agentdb
<recognized kernel cache>/<strict semver>/orchestration
<recognized kernel cache>/<strict semver>/hooks
```

The predicate must reject regular files, directories, links to `current` with the wrong suffix,
other marketplaces/plugins, traversal, malformed semver, and unexpected cache contents. Missing
paths remain missing for explicit init. Already-current correct links are no-ops.

### C. Init currently has dangerous unrelated behavior

`skills/init/SKILL.md:65-69` can move the entire `~/.claude` directory and replace it with a
Vaults symlink. That is much broader than “initialize project memory” and can move plugin/user
configuration. The rewritten README must not present init as harmless project setup. Either
remove/split this optional migration from the v8 setup path or put it behind an explicit,
separate confirmation with backup/rollback instructions and tests. The one-liner cannot safely
contain this class of migration or overwrite links blindly.

### D. Docs are part of the runtime contract

Current public text contains claims already disproven by the audit:

- `README.md:19-29,79-101` and `docs/QUICKSTART.md:40-58,200-234` conflate Claude Code
  Desktop, Claude chat Personal plugins, and Cursor; promise unsupported unnamespaced commands;
  and say Cursor inherits configuration automatically.
- `README.md:137-142` tells contributors to delete/replace a numbered cache directory and says
  edits apply immediately. Replace with official `claude --plugin-dir ./` plus reload/restart
  expectations.
- `README.md:151` uses unprefixed `/ingest`; `README.md:177` omits `preflight`.
- `docs/QUICKSTART.md:119` revives file-count tiering that governance explicitly rejects.
- `AGENTS.md:167,179` still declares YAML canonical while `CLAUDE.md` says JSON. Contributor
  ambient context therefore disagrees with the shipped plugin context.
- `CHANGELOG.md:8,27,46,49` still calls YAML canonical and describes the removed parser chain.
- `.claude-plugin/plugin.json:4` and `marketplace.json:10` advertise “yaml-first.”
- `skills/init/SKILL.md:20-22` documents a Vaults detection order different from its code and
  from `common.sh`; teammate install uses bare `kernel` instead of the exact identifier.
- `workflows/*.md` still assume commit/push behavior and agent routing that may conflict with
  current governance (“surgeon tier 1,” “push to main,” refactor says no new tests). These are
  executable process promises, not historical prose, and must be audited.

Historical changelog entries should remain historical. Only the 8.0 section should be rewritten;
tests should distinguish historical terms from active claims instead of banning words globally.

## User-risk matrix

| User state | Failure if shipped naively | Severity | Required behavior |
|---|---|---:|---|
| Fresh install | init chooses arbitrary highest/malformed cache or overwrites an existing path | Critical | validate selected plugin; refuse user-owned paths; exact install ID |
| Normal 7.23 -> 8 update | v8 skills load while host AgentDB/hooks remain pinned to 7.23 | Critical | repair three proven KERNEL links through validated `current`; verify versions |
| Auto-update enabled | update occurs before migration docs are read | Critical | startup self-heal; visible actionable warning on refusal/failure |
| Multiple old/new sessions | competing hooks flap selector or execute mixed versions | High | define concurrency/authority rule and test interleaving |
| Intentional rollback | orphaned 8.0 cache wins over selected 7.23 | Critical | explicit rollback authority/override; never highest-cache-only |
| Custom Vaults path | docs/code choose different trees and split AgentDB | High | one `KERNEL_VAULTS`-first detection function reused everywhere |
| Existing regular file/dir | `ln -sfn` mutates it while returning 0 | Critical | `lstat` classification and refusal; no blind force link |
| Broken old KERNEL link | lexical target is recognizable but target no longer exists | Medium | safe repair permitted from lexical target; test it |
| Read-only cache/host | repair silently fails and mixed versions continue | High | one visible warning; non-destructive recovery instructions |
| Existing project data | broad init/update claim causes fear or accidental deletion | Critical | explicit preserved data list and explicit host writes/data boundaries |

## Rollback hazards

1. A selector based on maximum cached semver defeats rollback while 8.0 remains orphaned.
2. Uninstall without `--keep-data` may delete plugin data; removing the marketplace can uninstall
   its plugins. Neither is a normal refresh step.
3. Re-running current init can overwrite KERNEL host links and can move `~/.claude`; it is not
   a zero-risk rollback command.
4. Rolling code back does not convert new canonical JSON manifests into old YAML. State files
   remain user data; document that v7 may not resume v8-created state even though it is preserved.
5. Existing sessions can keep old plugin code loaded. Verification must name when reload is enough
   and when a fresh session is required.

## Red tests required before implementation

Add behavior-first tests to `tests/run-tests.sh` (or a focused sourced test helper if extraction
is needed), run them, and save the non-zero/red output before changing runtime code:

1. Upgrade: exact 7.23 links become `current/...`, and data files are byte-identical.
2. Already-current: no inode/target churn and no misleading “updated” message.
3. Missing paths: remain missing.
4. Regular file, regular directory, unrelated symlink: unchanged, non-zero/actionable repair result.
5. Broken old numbered KERNEL link: safely repaired using lexical ownership proof.
6. Malformed cache: semver-looking directory missing/invalid plugin manifest/helpers is rejected.
7. Rollback: higher orphan cache does not override explicit/installed lower authority.
8. Concurrent/interleaved old and new invocations: selector ends at the defined authoritative
   version and host links never point to a partial temp target.
9. Read-only destination/cache and interrupted temp creation: original link survives intact;
   temp artifacts are cleaned.
10. Paths with spaces and relative symlink targets are classified correctly; traversal and
    newline-containing targets are rejected.
11. Fresh init and migration preserve existing `_meta/agentdb`, manifests, receipts, `.claude`
    user config, and unrelated files via checksums.
12. Version sync asserts exactly one authoritative version declaration if marketplace version
    is removed per official guidance, or asserts equality if it is intentionally retained.
13. Active-doc sweep rejects unsupported Cursor/Desktop/short-name claims, v8 YAML-canonical
    claims, bare install IDs, cache-deletion dev setup, and omitted manifest actions without
    failing on clearly historical changelog entries.
14. Migration smoke fixture models 7.23 -> 8.0 update, reload, link repair, `agentdb status`, and
    a JSON manifest validate/resume path through the real entry points.

## Exact action items

1. **Amend the contract before surgeon spawn.** Add authority, concurrency, ownership predicate,
   refusal behavior, rollback semantics, init boundaries, and red-first evidence requirements.
2. **Runtime:** update `hooks/scripts/common.sh`, `hooks/scripts/session-start.sh` only if needed
   for visible migration output, and `skills/init/SKILL.md`. Prefer reusable shell helpers in
   `common.sh`; do not duplicate selector logic in prose snippets.
3. **Tests:** strengthen `tests/run-tests.sh`; update `.github/workflows/test.yml` if the new
   release/doc checks are otherwise absent in CI. Exercise the actual sourced hook path, not
   substring tests like the current `update_current_symlink exists` assertions.
4. **Public docs:** completely rewrite `README.md`; correct `docs/QUICKSTART.md` and
   `docs/MIGRATION-8.md`. Include supported surfaces only, exact install/update/verify/recovery,
   data preservation vs host writes, reload/session behavior, rollback limits, and migration
   from 7.23.
5. **Governance/help/workflows:** synchronize `AGENTS.md`, `CLAUDE.md`, `skills/help/SKILL.md`,
   `workflows/feature.md`, `workflows/bugfix.md`, and `workflows/refactor.md` with actual v8 rules.
6. **Metadata/release:** rewrite the 8.0 section of `CHANGELOG.md`; replace plugin and marketplace
   descriptions in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`; audit
   `scripts/bump-version.sh` so future bumps cannot reintroduce duplicate authority or stale text.
7. **Verification:** run scoped red/green migration tests, full suite, shellcheck, JSON/schema and
   version sync, secrets scan, stale active-doc sweep, fresh temp install/upgrade/rollback smoke,
   then independent adversary, reviewer, validator, and GitHub CI before any release push/tag.

## Success criteria

- A fresh install and a 7.23 -> 8.0 update both use one validated KERNEL version for skills,
  hooks, orchestration, and AgentDB.
- Automatic self-heal changes only the three proven KERNEL-owned old links, atomically; every
  other filesystem object is unchanged and gets a useful warning.
- Intentional rollback remains possible with a documented authority and does not lose data.
- Existing project `_meta`, AgentDB, manifests, receipts, repositories, and user-owned Claude
  configuration remain byte-identical through update tests.
- README, quickstart, migration guide, help, governance, workflows, changelog 8.0 entry, and
  marketplace/about copy agree on supported platforms, namespaced invocations, JSON state,
  update/reload behavior, data boundaries, recovery, and known breaking changes.
- All scoped and full checks pass through their real entry points; CI independently passes.
- No publish, tag, marketplace release, or merge occurs until a human reviews the migration
  wording and the formal adversary/reviewer/validator all approve.

