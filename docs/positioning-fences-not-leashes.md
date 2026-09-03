---
type: note
status: active
created: 2026-08-07
---

# Positioning: fences, not leashes

Status: DRAFT for Aria's review. No plugin.json / README / marketplace copy changed yet.

## The claim

Anthropic made Auto the default permission mode (Pro/Max/Team, 2026-08-14) after finding
automated review catches far more mistakes than per-action human approval. Verified
2026-08-07 from the sources directly:

- Testers caught a dangerous command **13.6%** of the time (143/1053); auto mode blocked
  **89%** (937/1053). Users approve **97%** of permission prompts — but reject 39% of
  plans, so the fatigue is per-action, not per-decision. Human blocking degrades from ~17%
  early-session to ~5% after 50+ prompts; auto mode doesn't tire.
  Source: https://claude.com/blog/auto-mode-default-in-claude-code
- At production severity (7+), **6.3%** of manually approved sessions contained an
  unrequested harmful action vs **2.4%** of auto-mode sessions. (Same post.)
- Independent academia agrees: **94%** of developers fail to detect deliberate AI-agent
  sabotage in realistic 5-hour tasks; even WITH a safety monitor warning them, **56%**
  still accept the malicious code ("Coding with 'Enemy'", Ye et al.,
  https://arxiv.org/abs/2606.05647). Overtrust + minimal review is the mechanism.

KERNEL's honest one-liner falls out of that:

> **Auto mode is only safe inside fences. KERNEL is the fences.**

Per-action approval is theater: a human asked to approve 200 diffs a day stops reading at
diff 12. The loop didn't die, it moved to the boundary. The agent runs free inside a fenced
yard; the human gates only the genuinely irreversible edges and reviews outcomes, not
keystrokes.

## What KERNEL already is (map to the frame)

Every headline feature is a fence, not a leash:

| fence | mechanism |
|---|---|
| Destructive ops blocked, not approved | a bash destructive-command guard; history rewrites / force pushes require a HUMAN-opened one-time token the agent cannot read. The human enters the loop exactly once, at the irreversible edge. |
| Tier by reversibility, not vibes | reversible work executes; durable work plans; irreversible work gates. File count is noise; blast radius is signal. |
| Verifiers that never saw the builder | adversary + blind-evaluator agents; the builder never grades its own protected work. Structural, not attentional, review. |
| Fail-closed everywhere | scanner fails → block. Budget exceeded → stop. Uncertain → deny. Safety never degrades to a warning. |
| Receipts over trust | requested vs observed model/effort recorded separately; manifests are canonical JSON; "done" means a verification command ran. |
| Memory that outlives the session | agentdb recall/learn — mistakes become fences automatically instead of repeating. |
| Hooks, not honor system (I0.15) | the agent cannot bypass its own rules; the hook can. Prose promises are not safety. |

Rewrite targets once copy is approved: plugin.json description, marketplace.json
description, README hero section, skills/help intro. The router/pack story stays; it
becomes "the fence that sizes itself to the task."

## Draft copy (pick / edit)

Short (plugin description):
> KERNEL makes auto mode safe. Instead of asking a tired human to approve every action, it
> fences the agent: destructive operations are blocked by hooks, irreversible edges require
> a human-held token, independent verifiers check finished work, and every claim carries a
> receipt. Review outcomes, not keystrokes.

Hero line candidates:
1. "Stop approving everything your AI does. It's making you less safe."
2. "Auto mode is only safe inside fences. KERNEL is the fences."
3. "Human at the boundary, not in the loop."

## Gap map: what the vault runs that KERNEL doesn't ship

Portable (generalize, no Vaults assumptions — candidates for 9.2):

1. **Spawn-contract guard.** Vault hook refuses write-capable subagent dispatch unless the
   prompt carries ACCEPTANCE / ESCALATE IF / OWNED PATHS; read-only recon exempt. Kernel
   documents contracts but does not enforce them at spawn time. Pure fence, trivially
   portable.
2. **Verify-live guard.** Vault blocks ending a session that changed visual files without
   once seeing them rendered. Kernel's <verification> is prose (honor system) — exactly what
   I0.15 says not to rely on.
3. **Landing pass as a first-class role.** burn-lander: a separate agent that re-verifies a
   builder's "done" (normalize git, re-run checks, push, live-check) before anything is
   reported shipped. Kernel has adversary (finds defects) but no lander (proves landed).
4. **Injection rules.** Trigger → context injection ledger (command-shaped gotchas fire as
   PreToolUse context, free, deterministic). Kernel's agentdb recall is pull; injection is
   push-at-the-moment-of-risk. This is the mechanism that just reminded the session about
   autopush 3 times.
5. **Outcome boards.** status-board / waiting-on-human surfaces: outcome review needs a
   surface to review. Kernel emits receipts but has no standing "what changed, what awaits
   you" artifact.
6. **Commit-content guards as a pattern.** Vault runs em-dash, frontmatter, sqlite,
   secret-adjacent commit guards. Kernel could ship a guard *template* (pre-commit content
   rule + installer) rather than any specific rule.

Deliberately NOT portable (vault-culture, would bloat the plugin): chronicles/commissions
ceremony, tradition/civilization machinery, Obsidian integration, email automations,
model-routing memos, taper aesthetics.

## Suggested sequencing

1. Aria edits/approves copy above.
2. Ship reposition as 9.1.x (copy-only: plugin.json, marketplace.json, README, help).
3. 9.2 builds the top gap fences (spawn-contract guard + verify-live guard are the
   cheapest high-signal ports; lander agent next).
