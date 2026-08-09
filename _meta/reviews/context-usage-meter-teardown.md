---
type: review
status: active
created: 2026-08-06
updated: 2026-08-06
contract: CR-20260805235233-29894-26025
---

# Tear Down: context usage meter

reviewed: 2026-08-06
tier: 2
scope: 5 implementation/test surfaces plus generated adapters

## Big 5

- input_validation: revise until thread-id and line-1 metadata mismatch fixtures exist
- edge_cases: revise until stale, truncated, rotation, transitional-record and threshold fixtures exist
- error_handling: pass if every ambiguity returns `stale` or `unknown`, never green
- duplication: pass only with one parser and thin hook wiring
- complexity: pass if the parser is stdlib-only and the hook remains a separate bounded command

## Security

- No credential is needed or permitted.
- The parser may select only by validated `$CODEX_THREAD_ID`.
- Output is an allowlisted numeric/status object. Prompts, replacement history, messages, tool
  results and reasoning are forbidden in stdout, stderr, fixtures, or persisted state.
- The secret-canary fixture must fail before implementation and pass afterward.

## Verdict: REVISE, then proceed

The architecture is sound, but implementing before a separately authored red suite would repeat
the exact self-affirming-checker failure this feature exists to prevent. Aria already directed us
to proceed with that fix, so the next action is the red test lane, not another approval question.

## Action items

1. Terra writes only `tests/kernel9/test_context_usage.py` and proves it red.
2. Sol implements the minimum parser and hook wiring without changing test intent.
3. A fresh verifier corrupts selection and one threshold in isolated copies and proves red.
4. Run the full KERNEL suite, generate adapters, then prove the installed release in a fresh nested
   Codex task. Do not patch the installed cache.

## Protocol defect discovered

KERNEL 9.0.0's `tearitapart` skill requires `quality`, `testing`, and `security` skills plus a
quality research file that are absent from the installed package. This review applies the rubric
embedded in `tearitapart/SKILL.md`; the missing dependency references require a separate upstream
packaging repair and are not silently treated as loaded.
