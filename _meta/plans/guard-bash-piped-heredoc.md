---
type: plan
status: applied
created: 2026-08-29
---

# guard-bash: heredoc bodies that reach an executor by pipe or file

🔧 ready to build, own cycle

A heredoc body is scanned only when the executor sits BEFORE `<<`. Two shapes bypass it, both pre-existing before 9.6.7 (adversary round 2 on PR #233):

| Shape | Today | Expected |
|---|---|---|
| `cat <<EOF \| bash` / `... \| xargs bash -c` | body stripped as data, exit 0 | exit 2 |
| `cat <<EOF > s.sh` then `bash s.sh` in the same command | exit 0 | exit 2 |
| `cat <<"EOF" > x.md` with destructive prose | exit 2 (false block) | exit 0 |

## Proposal
- In `_heredoc_feeds_executor`, after the executor-before-`<<` checks, also return 0 when the same command contains `<<` and a later segment (split on `|`, `;`, `&&`) runs `bash|sh|zsh|python|perl|ruby|node|xargs|eval|source|\.`.
- Treat `<<-?["']?EOF["']?` uniformly in the awk stripper so double-quoted delimiters are data.
- Regressions: fails-before/passes-after for all three rows, probed in a temp repo with an unmerged `main`.

## Check
`bash tests/run-tests.sh security_hooks </dev/null` green; differential probe old vs new guard on the three payloads.
