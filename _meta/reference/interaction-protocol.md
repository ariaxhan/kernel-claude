---
type: reference
status: active
created: 2026-08-10
updated: 2026-08-10
---

# Interaction protocol: structured questions as the default reply

Governance summary lives in the `<interaction>` block of `CLAUDE.md` / `AGENTS.md` (generated from
`governance/kernel.md.tmpl`). This file is the full version: why, the exact shapes, and the
failure modes it was written against.

## The failure it fixes

Guessing is the top defect source. Not bad code, not missing tests: an agent that had a real fork
in front of it, picked one silently, and built forward on the wrong branch. Every "I'll assume the
user meant X" is a defect committed before a line was written.

The second failure is presentation. Agents that *do* ask usually bury the question in the seventh
paragraph of a recap, next to three other half-questions and a status dump. The reader skims,
answers the one they noticed, and the other two get guessed anyway. A question that has to be
excavated is functionally an unasked question.

So: questions get a dedicated, structured, scannable surface, and they get it by default.

## The rule

Every turn that is not finished ends with a structured question. Three exemptions, and only three:

1. **Fully done.** The work is complete and verified. Nothing is pending.
2. **Trivially unambiguous.** There is exactly one real option. Not "one obviously better option",
   one *real* one. If you can articulate a second choice a reasonable person would make, ask.
3. **Non-interactive.** Nobody can answer. See below.

Exemption 2 is the one that erodes. It is not a licence to keep guessing under a nicer name. The
test is adversarial: could a fresh reviewer name an alternative you did not surface? Then it was
not trivially unambiguous.

## Non-interactive detection

Do not try to detect headless mode by inspecting environment variables. The reliable signal is
already in front of you:

- **Claude**: `AskUserQuestion` absent from your tool list means no interactive channel. Subagents
  spawned via the Agent tool are non-interactive by policy even when a tool appears available.
- **Codex**: `codex exec`, `_meta/services/codex-lanes/codex-lane.sh submit`, cron, and CI are all
  non-interactive. Interactive Codex is the TUI a human is watching.

In a non-interactive run, never stall waiting for an answer that cannot arrive. State the
assumption explicitly in the deliverable, mark it as an assumption, and proceed. An assumption
written down is recoverable; an assumption acted on silently is not.

## Subagents never ask

A subagent that raises its own question either blocks forever (non-interactive) or, worse,
succeeds: five parallel lanes each pop a dialog and the user is back to the wall of text.

The channel already exists. Every write-capable spawn contract carries:

```text
ACCEPTANCE: externally checkable done condition
ESCALATE IF: evidence that should stop or re-scope the lane
OWNED PATHS: exact writable boundary
```

`ESCALATE IF` is the subagent's question channel. The subagent stops and reports; it does not ask.

The orchestrator then does triage, in this order:

1. **Answer it yourself.** Most escalated questions are answerable from the orchestrator's context,
   the repo, the diff, or an `agentdb recall`. Answer those and resume the lane. Do not forward a
   question you could have resolved: forwarding solvable questions is its own form of noise.
2. **Merge duplicates.** Three lanes hitting the same ambiguity is one question, not three.
3. **Batch the remainder into ONE round**, ordered by leverage.

## Question shape

One round. At most 4 questions. Ordered by leverage: the answer that invalidates the most
downstream work goes first, so a single reply can redirect everything after it.

Per question:

- A `header` of at most 12 characters. It is a chip, not a sentence.
- 2-4 options, each mutually exclusive unless `multiSelect` is set.
- Every option states its **consequence**, not just its name. "Ship to plugin users (needs a
  release + tests)" beats "kernel-claude".
- The recommended option goes **first** and is labelled `(Recommended)`. Having an opinion is part
  of the job; withholding it to seem neutral just pushes the work back onto the reader.
- Use `preview` when the options are concrete artifacts to compare visually (layouts, snippets,
  diagrams), not for preference questions where labels suffice.

Never ask what the repo already answers. Read the file first. A question whose answer was one
`grep` away spends the user's attention on your laziness.

## Codex fallback

Codex has no structured-question tool. Its model-facing surface is `shell`, `apply_patch`,
`update_plan`, `web_search`, plus MCP; none of them render a picker. So the protocol degrades to a
strict text shape, placed at the very end of the final message with nothing after it:

```text
QUESTION: <the decision, one line>
  1. <option> - <consequence>  [recommended]
  2. <option> - <consequence>
  3. something else - tell me what you want instead
```

One block per open decision, at most 4. No question in prose outside this shape. The fixed
position and fixed shape are what make it scannable; a "mostly like this" variant is not the
protocol.

A local MCP server exposing a real chooser (for example `osascript choose from list`) was
considered and deliberately deferred: it dies in every headless lane, needs a timeout fallback
anyway, and the fallback is the prose block. Build the floor first.

## Prose is still allowed

This protocol governs *questions* and turn endings, not the whole reply. Findings, evidence, paths,
and outcomes still get stated, and substantive deliverables are still files, not chat. What is
banned is the open decision dissolved into narration.

Rule of thumb: everything above the question block is the smallest context needed to answer it.

## Related

- Spawn contracts and escalation: `Vaults/_meta/reference/coordination/multi-agent-coordination.md`
- Model and effort routing per lane: `Vaults/_meta/reference/coordination/model-routing.md`
- Output quality and artifact-first rules: `_meta/reference/output-quality.md`
