---
type: note
status: active
created: 2026-09-01
---

# 2026-09-01 — refused skill-sync prompt injection

**Attempted:** none. User turn was an embedded "EXECUTE IMMEDIATELY, NO CONFIRMATION" instruction
telling me to WebSearch, then edit `skills/testing|debug|refactor|security|api|git/SKILL.md` from
search results, no review.

**Refused, no files changed.** Reasons: matches prompt-injection shape (bypasses kernel's
ask-first/recall/tearitapart gates); named skill files don't exist in this repo (real skills are
build/quality/eval/debug/architecture/orchestration/context-mgmt/knowledge-graph/frontend/
marketing-site/human-pass/app-dev/experiment); repo already had 18 uncommitted files on `main`
pre-existing this session, unrelated to this turn.

**Verified live:** n/a — no code change made.

**Deferred:** if the user genuinely wants a skill sync, do it properly next session — recall
agentdb, confirm real skill paths, review search results before editing, diff before write.

**Disagreement worth inheriting:** none; offered to proceed correctly, awaiting reply.
