# Research-Failures-First Protocol

Status: **enforced**
Owner: kernel-claude plugin
Last reviewed: 2026-05-14

## Why this exists

Most non-trivial implementation pain is somebody else's already-debugged pain. Finding their bruises before donating your own is a >5× return on the time spent looking. This protocol enforces failure-mode hunting *before* any non-trivial code is written.

## When this gates implementation

Mandatory before:
- Native dependency adoption (any new npm/pip/cargo/brew/swift package not already in the repo)
- Schema migrations (DB or content)
- Auth flow changes
- Sync protocol work (OTA, websocket, eventsourcing, conflict resolution)
- Store-submission gates (App Store, Play Store, marketplace)
- Cross-cutting refactors (>5 files OR multi-module)
- Any framework upgrade that changes public API surface

NOT required for: typo fixes, copy edits, comment changes, single-file bug fixes inside familiar code, test additions to existing suites.

## Channel taxonomy — empirically ranked

Source: modelmind experiment H-RFF-001 (4 parallel research agents on identical topics, each constrained to one channel).

| Channel | Unique-find rate | Run? |
|---|---|---|
| A — GitHub issues (open + closed, the project's own bug tracker) | 47% | **always** |
| B — Anti-pattern web search ("X gotchas", "X common mistakes") | 15% | **never — drop** |
| C — Forums (Reddit, HN, Stack Overflow) | 29% | optional, if channel A returns < 20 entries |
| D — Production case studies (engineering blog post-mortems) | 78% | **always** |

**Rule:** Always run A + D in parallel. Never run B alone (it mostly re-derives A). Run C only as supplement.

## Deliverable: canonical failure-mode map

Every protocol run produces ONE persistent committed file at `_meta/research/<topic>.md`. Format:

```markdown
---
topic: <topic name>
status: canonical
last_updated: YYYY-MM-DD
channels_run: [A, D]
entries: <count>
---

# <Topic> failure modes

## TL;DR
1-3 sentences: what works, what to avoid, what's the stack verdict.

## Failure-mode table
| # | Symptom | Root cause | Fix | Source URL |
|---|---|---|---|---|
| 1 | <what user sees> | <why it breaks> | <minimal fix> | <link> |
| 2 | ... | ... | ... | ... |

## Pre-flight checklist
- [ ] Item from failure-mode table that should be verified before this work starts
- [ ] ...

## Notes
Open questions, version-specific caveats, etc.
```

**Minimum 10 unique entries.** Below 10 = the channels probably weren't queried thoroughly enough; expand search or add channel C.

## Orchestration: research sprint protocol

The orchestrator never holds raw research in context. Subagents own writes.

1. **Pre-log** PENDING agentdb rows for each channel agent before spawning. Format: `{"event":"research-sprint","topic":"X","channel":"A","status":"PENDING"}`
2. **Spawn** Channel-A agent + Channel-D agent in parallel via Agent tool, single message, isolated worktrees if available. Each writes to `_meta/research/<topic>-channel-<a|d>.md`.
3. **Cap receipts at 200 words.** The agent's return-to-orchestrator summary stays small; the deliverable is on disk.
4. **Verify by file**, not by receipt. After spawn returns, the orchestrator opens the deliverable file. If the file is missing or the agentdb row is still PENDING, the orchestrator re-spawns that single channel (max 1 retry).
5. **Merge** both channel files into the canonical map at `_meta/research/<topic>.md`. Dedupe overlapping entries (cite both source URLs in the merged row).
6. **Context checkpoint at 60% fill** before the merge step — if context is heavier than that, write everything to disk and continue in a fresh agent.

## Anti-patterns

- **Skipping research because "this is quick."** The cheap-research → expensive-rebuild loop is well-documented. ~5x ROI on research time, on average, for non-trivial work.
- **Asking the LLM what could go wrong instead of searching.** Foundation models hallucinate failure modes that don't exist for the specific version you're using. Always cite a source URL.
- **Running channel B alone.** 15% unique-find rate. Time is better spent on A + D.
- **Treating the canonical map as ephemeral.** It's committed reference. Subsequent forge runs cite specific row numbers from it.
- **Letting receipts replace files.** If the failure-mode map isn't on disk, the protocol didn't run.

## Cross-references

- Spawn the `deep-diver` agent (kernel-claude `agents/deep-diver.md`) to run this protocol — it knows the channel taxonomy and the deliverable format.
- Pairs with the `kernel:tearitapart` pre-implementation review. Tearitapart consumes the failure-mode map as one of its inputs; if no map exists, tearitapart asks for one before proceeding.
- NEXUS layer references this file at `_meta/reference/research-failures-first.md` (parent CLAUDE.md ambient-ingest step 3).
