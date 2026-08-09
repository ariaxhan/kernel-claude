---
type: implementation-receipt
status: complete
created: 2026-08-06
contract: CR-20260805235233-29894-26025
---

# Context usage meter implementation

## Outcome

Implemented the read-only, Python-stdlib Codex context meter and generated both host hook
adapters. The separately authored Terra contract was not changed.

- requested_model: `gpt-5.6-sol`
- requested_effort: `high`
- observed_model: `unavailable`
- observed_effort: `unavailable`

## Files

- `hooks/scripts/context-usage.py` (new, executable)
- `scripts/generate-adapters.py`
- `hooks.json` (generated)
- `hooks/hooks.json` (generated)
- `_meta/reports/context-usage-meter-implementation.md` (this receipt)

`tests/kernel9/test_context_usage.py` remained read-only and unmodified by this lane.

## Privacy boundary

The meter selects only an exact `$CODEX_THREAD_ID` filename suffix, validates line-one
`session_meta.payload.id`, and byte-prefilters structural compaction/token records before JSON
decode. Content-bearing response, prompt, tool, message, reasoning, and replacement-history
records are neither deserialized nor emitted. Output is the frozen allowlisted schema or one
bounded hook line. Reads create or modify no status files. Expected missing, ambiguous,
mismatched, unreadable, stale, and truncated states exit zero without stderr.

## Evidence

Initial red reproduction:

```text
$ python3 -m unittest tests.kernel9.test_context_usage
Ran 23 tests in 0.015s
FAILED (failures=24)
```

After the parser and canonical binding, before regeneration, only generated wiring remained red:

```text
$ python3 -m unittest tests.kernel9.test_context_usage
Ran 23 tests in 0.716s
FAILED (failures=2)
```

Generation:

```text
$ python3 scripts/generate-adapters.py
wrote hooks.json
wrote hooks/hooks.json
```

Final gates:

```text
$ python3 -m unittest tests.kernel9.test_context_usage
Ran 23 tests in 0.813s
OK

$ /usr/bin/python3 -m unittest tests.kernel9.test_context_usage
Ran 23 tests in 1.932s
OK

$ python3 scripts/generate-adapters.py --check
all 7 generated adapters are in sync

$ python3 -m unittest tests.kernel9.test_adapters tests.kernel9.test_activation
Ran 42 tests in 3.066s
OK

$ git diff --check
(no output; exit 0)

$ /usr/bin/stat -f '%Sp %N' hooks/scripts/context-usage.py
-rwxr-xr-x hooks/scripts/context-usage.py
```

No dependency, test change, network access, plugin-cache patch, Git mutation, release, install,
credential access, transcript persistence, or external mutation was used.
