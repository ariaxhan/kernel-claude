---
query: Codex compatibility mapping SessionEnd autopush into Stop timeout
date: 2026-07-15
ttl: 30
status: reproduced
---

# Failure-mode map: SessionEnd autopush under Codex

## Evidence priority

This is an owned plugin defect reproduced against the published 8.1.3 payload. Repository issues
and production case studies were searched, but no external report was needed or used to infer the
cause. The exact installed command and process tree are stronger evidence.

| Symptom | Root cause | Fix | Source |
|---|---|---|---|
| Codex reports `Stop hook timed out after 60s` after an otherwise completed turn | The shared compatibility manifest wires `SessionEnd` to `autopush.sh sweep`; Codex maps the lifecycle behavior onto Stop, which runs at the end of each turn. | Remove automatic SessionEnd autopush from the published manifest. Push remains explicit. | `hooks/hooks.json`; https://learn.chatgpt.com/docs/hooks.md |
| Timed-out hook leaves Git work running | `autopush.sh sweep` starts unbounded `git fetch` children across the outermost repository tree; killing the hook parent does not reliably kill descendants. | Never start repository-wide network work from a lifecycle hook. | `hooks/scripts/autopush.sh`; live PPID-1 fetch observed 2026-07-15 |
| Cross-loader regression tests previously required SessionEnd | Tests encoded the historical auto-push behavior rather than the current explicit-push doctrine. | Replace positive SessionEnd assertions with negative automatic-push assertions and exercise the installed Codex payload. | `tests/run-tests.sh`; `hooks/scripts/autopush-postcommit` |

## Exact reproduction

- Vaults chronicle Stop: 0.022 seconds, exit 0.
- Vaults checkpoint Stop: 0.229 seconds, exit 0.
- Kernel 8.1.3 autopush sweep: hung in the first root-repo `git fetch`; user-visible run reached
  the 60-second hook timeout and left an orphaned fetch.

## Rejected fixes

- Raising the hook timeout preserves unbounded work.
- Per-fetch timeouts preserve an inappropriate network side effect on every turn.
- Codex-only environment checks inside `autopush.sh` leave loader detection brittle and retain
  automatic push behavior that conflicts with the plugin's explicit-push policy.

## Chosen fix

Remove SessionEnd autopush from the canonical plugin manifest, keep the script available only for
explicit/manual invocation, add negative regression coverage, and release as patch version 8.1.4.
