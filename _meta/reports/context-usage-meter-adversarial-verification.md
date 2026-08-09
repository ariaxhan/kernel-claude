---
type: adversarial-verification
status: complete
created: 2026-08-06
contract: CR-20260805235233-29894-26025
requested_model: gpt-5.6-terra
requested_effort: high
observed_model: unavailable
observed_effort: unavailable
verdict: PASS
---

# Context usage meter adversarial verification

## Verdict

**PASS.** The meter passed its contract suites, every required seeded defect made a
previously green check fail in an isolated disposable copy, and the live numeric
reading exactly matched an independent structural `jq` query. No implementation,
test, or adapter file was changed by this verification.

## Baseline gates

Configured `python3` is Python 3.14.6; `/usr/bin/python3` is Python 3.9.6.

```text
$ PYTHONDONTWRITEBYTECODE=1 python3 -m unittest tests.kernel9.test_context_usage
Ran 23 tests in 0.742s
OK

$ PYTHONDONTWRITEBYTECODE=1 /usr/bin/python3 -m unittest tests.kernel9.test_context_usage
Ran 23 tests in 1.829s
OK

$ PYTHONDONTWRITEBYTECODE=1 python3 -m unittest tests.kernel9.test_adapters tests.kernel9.test_activation
Ran 42 tests in 3.012s, then 2.704s on repeat
OK

$ python3 scripts/generate-adapters.py --check
all 7 generated adapters are in sync

$ git diff --check
exit 0, no output
```

## Seeded defect evidence

Each check was first run green against a copied meter and copied contract in
`/tmp/context-meter-adversary.fIpCX8/repo`, then the copy alone was changed.

| Defect seeded | Exact changed behavior | Previously green contract that turned red | Result |
|---|---|---|---|
| Wrong-thread selection | Selector accepted every `.jsonl` and returned the newest mtime rather than the exact thread suffix. | `ContextUsageContract.test_competing_newer_rollout_cannot_steal_thread_selection` | Red, exit 1: expected `last.total_tokens == 499`, got `None` after the newer `thread-b` rollout was selected then rejected by metadata validation. |
| One boundary | Changed only `elif used_percent < 60` to `< 61`. | `ContextUsageContract.test_threshold_60_is_compact_at_boundary` | Red, exit 1: `checkpoint` instead of `compact_at_boundary` at 60.0%. |
| Privacy output | Appended the existing `context-meter-canary-NOT-A-REAL-SECRET-7f3a9c` to JSON output. | `ContextUsageContract.test_content_canary_never_leaks_to_output_or_json` | Red, exit 1: JSON extra-data failure printed the injected canary, proving the privacy test blocks this leak. |

The untouched copies passed those same three tests individually before mutation.

Commands that produced the red results:

```text
$ PYTHONDONTWRITEBYTECODE=1 python3 /tmp/context-meter-adversary.fIpCX8/repo/tests/kernel9/test_context_usage.py ContextUsageContract.test_competing_newer_rollout_cannot_steal_thread_selection
exit 1
$ PYTHONDONTWRITEBYTECODE=1 python3 /tmp/context-meter-adversary.fIpCX8/repo/tests/kernel9/test_context_usage.py ContextUsageContract.test_threshold_60_is_compact_at_boundary
exit 1
$ PYTHONDONTWRITEBYTECODE=1 python3 /tmp/context-meter-adversary.fIpCX8/repo/tests/kernel9/test_context_usage.py ContextUsageContract.test_content_canary_never_leaks_to_output_or_json
exit 1
```

## Live, metadata-only parity

With this verifier's `$CODEX_THREAD_ID`, I selected the single filename-suffix
rollout, validated only line-one `session_meta.payload.id`, then ran the real meter:

```text
$ PYTHONDONTWRITEBYTECODE=1 python3 hooks/scripts/context-usage.py --json
meter total=58799, window=258400, percent=22.75503095975232
```

The independent query byte-filtered only `event_msg`/`token_count` lines before
`jq`, emitted only `{total, window, percent}`, and did not emit content-bearing
records:

```text
independent total=58799, window=258400, percent=22.75503095975232
exact=true
```

The exact independent numeric command was:

```sh
LC_ALL=C awk '/"type"[[:space:]]*:[[:space:]]*"event_msg"/ && /"type"[[:space:]]*:[[:space:]]*"token_count"/' "$rollout" |
  jq -cs 'map(select(.type == "event_msg" and .payload.type == "token_count") | {total: .payload.info.last_token_usage.total_tokens, window: .payload.info.model_context_window}) | last | . + {percent: (.total * 100 / .window)}'
```

No lag was observed. The ordinary hook invocation took `real 0.03s`; it emitted
one 58-character line, within the 240-character limit:

```text
[context] green 22.8% used, 199601 tokens remain, window 1
```

## Read-only and wiring checks

Using an isolated `$HOME` and `PYTHONDONTWRITEBYTECODE=1`, I hashed every repo
file and every fixture-home file immediately before and after a `--json` status
read. Both comparisons were identical: `repo_files_unchanged=yes` and
`home_files_unchanged=yes`.

Both generated adapters invoke the meter at `UserPromptSubmit`:

- Codex: `hooks.json:112-120`, command at `hooks.json:118`.
- Claude: `hooks/hooks.json:124-132`, command at `hooks/hooks.json:130`.
- Canonical ownership is `scripts/generate-adapters.py:60`; generation synchronization
  was green, so neither generated file is a hand-maintained exception.

## Code and diff review

No blocking findings.

- Exact suffix selection and ambiguity refusal: `hooks/scripts/context-usage.py:69-100`.
- Metadata identity validation before event use: `hooks/scripts/context-usage.py:103-113`.
- Numeric allowlist and type validation: `hooks/scripts/context-usage.py:116-144`.
- Byte prefilter before decoding token records: `hooks/scripts/context-usage.py:154-181`.
- Exact 50/60/70 boundaries: `hooks/scripts/context-usage.py:194-205`.
- Bounded single-line renderer and allowlisted JSON only: `hooks/scripts/context-usage.py:223-262`.

The implementation diff adds only Python standard-library imports. Targeted diff
scans found no hardcoded user path, private transcript value, network/dependency
addition, or prompt-field parsing. `git diff --check` was clean.

## Scope receipt

Only this report was written in the repository. The three intentional changes were
limited to the disposable fixture copy and were discarded after verification.
