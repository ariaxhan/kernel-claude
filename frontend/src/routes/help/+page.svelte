<script lang="ts">
  let expandedSections = $state<Set<string>>(new Set());

  function toggle(id: string) {
    const next = new Set(expandedSections);
    if (next.has(id)) next.delete(id); else next.add(id);
    expandedSections = next;
  }

  const sections = [
    {
      id: 'what',
      title: 'What is KERNEL?',
      content: `KERNEL is a plugin for Claude Code that gives your AI assistant persistent memory, specialized agents, and structured workflows. Without it, every session starts from zero. With it, your AI remembers what worked, what broke, and what to avoid.`,
    },
    {
      id: 'philosophy',
      title: 'Philosophy',
      content: `Every AI-written line is a liability. KERNEL exists because AI code is 1.7x buggier than human code. The solution isn't to stop using AI — it's to add structure: research before coding, tests before implementation, and a memory system that prevents repeating mistakes.`,
    },
    {
      id: 'tiers',
      title: 'How Tiers Work',
      content: `KERNEL sizes up every task before starting.

Tier 1 (1–2 files): Small enough to handle directly. No extra process needed.

Tier 2 (3–5 files): Brings in a Surgeon agent — a specialist that makes the smallest possible change. A Validator checks the work.

Tier 3 (6+ files): Full team. Surgeon implements, Adversary attacks the result looking for bugs, Validator runs quality gates. Nothing ships without evidence it works.

The tier is determined by counting how many files need to change. When in doubt, KERNEL assumes higher tier (more safety).`,
    },
    {
      id: 'agents',
      title: 'The Agents',
      items: [
        { name: 'Surgeon', desc: 'The careful implementer. Makes the smallest possible change. Only touches files listed in the contract. Commits every working state.' },
        { name: 'Adversary', desc: 'The skeptic. Assumes every change is broken until proven otherwise. Tests edge cases, boundary conditions, error paths. Pass or fail — no middle ground.' },
        { name: 'Reviewer', desc: 'Code review specialist. Checks logic, security, performance. Only reports issues it\'s 80%+ confident about.' },
        { name: 'Researcher', desc: 'Finds proven solutions before coding starts. Searches for anti-patterns first (what breaks), then solutions. Prevents reinventing the wheel.' },
        { name: 'Scout', desc: 'Maps unfamiliar codebases. Detects tooling, conventions, risk zones. Runs on first contact with a new project.' },
        { name: 'Validator', desc: 'Pre-commit gate. Runs build, types, lint, tests, security scan. Blocks if anything fails. No exceptions.' },
        { name: 'Dreamer', desc: 'Generates competing perspectives for non-trivial decisions. Minimalist vs maximalist vs pragmatist. The approach that survives criticism wins.' },
      ]
    },
    {
      id: 'commands',
      title: 'Commands',
      items: [
        { name: '/kernel:ingest', desc: 'Guided entry point. Walks through research, scoping, testing, and implementation step by step. Human confirms each phase.' },
        { name: '/kernel:forge', desc: 'Autonomous mode. Runs without intervention — generates approaches, implements, tests, attacks, iterates. Come back to finished work.' },
        { name: '/kernel:validate', desc: 'Pre-commit check. Build, types, lint, tests, security. Blocks on any failure.' },
        { name: '/kernel:dream', desc: 'Creative exploration. Three perspectives compete, a council of four critics stress-tests each one. Best survivor wins.' },
        { name: '/kernel:diagnose', desc: 'Systematic debugging. Reproduce the bug, form a hypothesis, isolate with binary search, fix the root cause.' },
        { name: '/kernel:tearitapart', desc: 'Pre-implementation review. Finds what could go wrong before any code is written. Verdict: proceed, revise, or rethink.' },
        { name: '/kernel:review', desc: 'Code review for pull requests. Checks for the Big 5 quality issues. Approve, request changes, or comment.' },
        { name: '/kernel:handoff', desc: 'Save session context for next time. Captures decisions, progress, open threads, and next steps.' },
        { name: '/kernel:retrospective', desc: 'Learning synthesis. Groups related learnings, resolves contradictions, promotes strong patterns.' },
        { name: '/kernel:metrics', desc: 'Observability dashboard. Session stats, agent performance, hook health, learning trends.' },
      ]
    },
    {
      id: 'skills',
      title: 'Skills (Methodologies)',
      content: `Skills are HOW agents work. They're loaded on demand based on what the task requires.

Build — Solution exploration. Always generates 2–3 approaches before picking one.
Testing — Edge cases over happy paths. Tests prove behavior, not implementation.
Quality — The Big 5: input validation, edge cases, error handling, duplication, complexity.
Security — OWASP prevention: injection, XSS, CSRF, secrets management.
Architecture — Modular design, interface stability, dependency management.
Orchestration — Multi-agent coordination with fault tolerance.
Debug — Scientific method: reproduce, hypothesize, isolate, fix.
Git — Atomic commits, conventional messages, branch strategies.
Design — Anti-convergence aesthetic system with 9 mood variants.

Plus: API, Backend, E2E, TDD, Eval, Refactor, Performance, Context Management.`,
    },
    {
      id: 'agentdb',
      title: 'AgentDB (Memory)',
      content: `AgentDB is a SQLite database that persists across every session. It stores:

Learnings — Patterns (what works), failures (what breaks), gotchas (traps to avoid).
Context — Contracts, checkpoints, handoffs, verdicts from agents.
Errors — Automatic capture of every failure with context.
Sessions — When work happened, what tier, which skills loaded, success/failure.
Graph — Which skills and agents work well together (learned from experience).

Every session starts by reading AgentDB (what do I already know?) and ends by writing to it (what did I learn?). This is how KERNEL gets smarter over time.`,
    },
    {
      id: 'big5',
      title: 'The Big 5 (Quality)',
      content: `AI-generated code has 5 recurring weaknesses. KERNEL checks all of them before any code ships:

1. Input Validation — Are all inputs checked? Zod schemas for external data?
2. Edge Cases — What happens with null, empty, zero, negative, max values?
3. Error Handling — Do catch blocks log and handle errors? No silent failures?
4. Duplication — Is the same logic repeated in 3+ places?
5. Complexity — Any functions over 30 lines? Nested ternaries? Deep nesting?

Any Big 5 violation = not ready to ship. No exceptions.`,
    },
    {
      id: 'hooks',
      title: 'Hooks (Automation)',
      content: `Hooks fire automatically at lifecycle events:

Session Start — Load AgentDB context, detect profile, show git state.
Session End — Write checkpoint, clean up agents, emit telemetry.
Pre-Bash — Guard against dangerous commands (force push, rm -rf).
Pre-Write — Block secrets from being written to files.
Post-Failure — Automatically capture errors to AgentDB.
Post-Compaction — Restore context after Claude Code compresses conversation.

All hooks are fire-and-forget. If a hook fails, the session continues.`,
    },
  ];
</script>

<div class="page">
  <section class="header">
    <h1 class="font-serif">Help</h1>
    <p class="subtitle">How KERNEL works, and why each piece exists.</p>
  </section>

  <div class="sections">
    {#each sections as section}
      <button class="section-card" onclick={() => toggle(section.id)} class:expanded={expandedSections.has(section.id)}>
        <div class="section-header">
          <h2 class="section-title font-serif">{section.title}</h2>
          <span class="chevron">{expandedSections.has(section.id) ? '−' : '+'}</span>
        </div>

        {#if expandedSections.has(section.id)}
          <div class="section-body">
            {#if section.content}
              <p class="section-text">{section.content}</p>
            {/if}
            {#if section.items}
              <div class="item-list">
                {#each section.items as item}
                  <div class="item">
                    <span class="item-name font-mono">{item.name}</span>
                    <span class="item-desc">{item.desc}</span>
                  </div>
                {/each}
              </div>
            {/if}
          </div>
        {/if}
      </button>
    {/each}
  </div>
</div>

<style>
  .page { display: flex; flex-direction: column; gap: var(--space-8); }

  .header h1 { font-size: var(--text-2xl); font-weight: 300; letter-spacing: var(--tracking-tight); }
  .subtitle { color: var(--text-secondary); font-size: var(--text-sm); margin-top: var(--space-1); }

  .sections { display: flex; flex-direction: column; gap: var(--space-2); }

  .section-card {
    width: 100%;
    text-align: left;
    background: var(--surface-1);
    border: none;
    border-radius: var(--radius-lg);
    padding: var(--space-6);
    cursor: pointer;
    transition: background var(--duration-fast) var(--ease-out);
    font-family: inherit;
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }
  .section-card:hover { background: var(--surface-2); }

  .section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .section-title {
    font-size: var(--text-lg);
    font-weight: 500;
    letter-spacing: var(--tracking-tight);
  }

  .chevron {
    color: var(--text-tertiary);
    font-size: var(--text-xl);
    font-weight: 300;
    width: 24px;
    text-align: center;
  }

  .section-body {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .section-text {
    font-size: var(--text-sm);
    color: var(--text-secondary);
    line-height: var(--leading-relaxed);
    white-space: pre-line;
  }

  .item-list {
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .item {
    display: flex;
    flex-direction: column;
    gap: var(--space-1);
    padding: var(--space-3);
    background: var(--surface-0);
    border-radius: var(--radius-md);
  }

  .item-name {
    font-size: var(--text-sm);
    font-weight: 500;
    color: var(--text-primary);
  }

  .item-desc {
    font-size: var(--text-sm);
    color: var(--text-secondary);
    line-height: var(--leading-relaxed);
  }
</style>
