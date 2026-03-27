<script lang="ts">
  import type { Learning, ContextEntry } from '$lib/types';

  let { data } = $props();

  let activeFilter = $state<'all' | 'pattern' | 'failure' | 'gotcha' | 'preference'>('all');
  let expandedIds = $state<Set<string>>(new Set());

  function toggleExpand(id: string) {
    const next = new Set(expandedIds);
    if (next.has(id)) next.delete(id); else next.add(id);
    expandedIds = next;
  }

  const allLearnings = $derived(
    [...data.patterns, ...data.failures, ...data.gotchas, ...data.preferences]
      .sort((a, b) => (b.hit_count ?? 0) - (a.hit_count ?? 0))
  );

  const filtered = $derived(
    activeFilter === 'all' ? allLearnings : allLearnings.filter(l => l.type === activeFilter)
  );

  function parseContent(content: string): Record<string, unknown> | null {
    try { return JSON.parse(content); } catch { return null; }
  }

  function typeLabel(type: string): string {
    return { pattern: 'Pattern', failure: 'Failure', gotcha: 'Gotcha', preference: 'Preference' }[type] ?? type;
  }

  function timeAgo(ts: string): string {
    const diff = Date.now() - new Date(ts).getTime();
    const d = Math.floor(diff / 86400000);
    if (d === 0) return 'today';
    if (d === 1) return 'yesterday';
    return `${d}d ago`;
  }
</script>

<div class="page">
  <section class="header">
    <h1 class="font-serif">Memory</h1>
    <p class="subtitle">Everything KERNEL has learned across sessions.</p>
  </section>

  <!-- Filter buttons -->
  <section class="filters">
    <button class="filter-btn" class:active={activeFilter === 'all'} onclick={() => activeFilter = 'all'}>
      All <span class="count">{allLearnings.length}</span>
    </button>
    <button class="filter-btn filter-pattern" class:active={activeFilter === 'pattern'} onclick={() => activeFilter = 'pattern'}>
      Patterns <span class="count">{data.patterns.length}</span>
    </button>
    <button class="filter-btn filter-failure" class:active={activeFilter === 'failure'} onclick={() => activeFilter = 'failure'}>
      Failures <span class="count">{data.failures.length}</span>
    </button>
    <button class="filter-btn filter-gotcha" class:active={activeFilter === 'gotcha'} onclick={() => activeFilter = 'gotcha'}>
      Gotchas <span class="count">{data.gotchas.length}</span>
    </button>
    {#if data.preferences.length > 0}
      <button class="filter-btn" class:active={activeFilter === 'preference'} onclick={() => activeFilter = 'preference'}>
        Preferences <span class="count">{data.preferences.length}</span>
      </button>
    {/if}
  </section>

  <!-- Learnings list -->
  <section class="learnings">
    {#each filtered as learning (learning.id)}
      <button class="learning-card" onclick={() => toggleExpand(learning.id)}>
        <div class="learning-header">
          <span class="type-tag" data-type={learning.type}>{typeLabel(learning.type)}</span>
          <span class="learning-insight">{learning.insight}</span>
          {#if learning.hit_count > 1}
            <span class="hit-count font-mono">{learning.hit_count}x</span>
          {/if}
        </div>
        {#if expandedIds.has(learning.id)}
          <div class="learning-detail">
            {#if learning.evidence}
              <div class="detail-row">
                <span class="detail-label">Evidence</span>
                <span class="detail-value">{learning.evidence}</span>
              </div>
            {/if}
            {#if learning.domain}
              <div class="detail-row">
                <span class="detail-label">Domain</span>
                <span class="detail-value font-mono">{learning.domain}</span>
              </div>
            {/if}
            <div class="detail-row">
              <span class="detail-label">Last seen</span>
              <span class="detail-value">{timeAgo(learning.last_hit || learning.ts)}</span>
            </div>
          </div>
        {/if}
      </button>
    {/each}
    {#if filtered.length === 0}
      <p class="empty">No learnings recorded yet.</p>
    {/if}
  </section>

  <!-- Contracts & Verdicts -->
  {#if data.contracts.length > 0}
    <section class="section">
      <h2 class="section-title font-serif">Contracts</h2>
      <div class="context-list">
        {#each data.contracts as entry}
          {@const parsed = parseContent(entry.content)}
          <div class="context-row">
            <span class="context-time font-mono">{timeAgo(entry.ts)}</span>
            <span class="context-detail">
              {#if parsed?.goal}{parsed.goal}{:else}{entry.content}{/if}
            </span>
            {#if parsed?.tier}
              <span class="tag">T{parsed.tier}</span>
            {/if}
          </div>
        {/each}
      </div>
    </section>
  {/if}

  {#if data.verdicts.length > 0}
    <section class="section">
      <h2 class="section-title font-serif">Verdicts</h2>
      <div class="context-list">
        {#each data.verdicts as entry}
          {@const parsed = parseContent(entry.content)}
          <div class="context-row">
            <span class="context-time font-mono">{timeAgo(entry.ts)}</span>
            <span class="context-agent font-mono">{entry.agent}</span>
            <span class="context-detail">
              {#if parsed?.result}
                <span class="verdict-badge" data-result={parsed.result}>{parsed.result}</span>
              {/if}
            </span>
          </div>
        {/each}
      </div>
    </section>
  {/if}
</div>

<style>
  .page { display: flex; flex-direction: column; gap: var(--space-8); }

  .header h1 {
    font-size: var(--text-2xl);
    font-weight: 300;
    letter-spacing: var(--tracking-tight);
  }
  .subtitle {
    color: var(--text-secondary);
    font-size: var(--text-sm);
    margin-top: var(--space-1);
  }

  /* Filters */
  .filters { display: flex; gap: var(--space-2); flex-wrap: wrap; }

  .filter-btn {
    font-family: var(--font-body);
    font-size: var(--text-sm);
    color: var(--text-tertiary);
    background: none;
    border: 1px solid var(--surface-3);
    padding: var(--space-2) var(--space-4);
    border-radius: var(--radius-md);
    cursor: pointer;
    transition: all var(--duration-fast) var(--ease-out);
    display: flex; align-items: center; gap: var(--space-2);
  }
  .filter-btn:hover { color: var(--text-secondary); border-color: var(--text-tertiary); }
  .filter-btn.active { color: var(--text-primary); background: var(--surface-2); border-color: var(--surface-3); }
  .filter-pattern.active { color: var(--status-healthy); border-color: var(--status-healthy); background: var(--status-healthy-bg); }
  .filter-failure.active { color: var(--status-error); border-color: var(--status-error); background: var(--status-error-bg); }
  .filter-gotcha.active { color: var(--status-attention); border-color: var(--status-attention); background: var(--status-attention-bg); }
  .count { font-family: var(--font-mono); font-size: var(--text-xs); opacity: 0.7; }

  /* Learnings */
  .learnings { display: flex; flex-direction: column; gap: var(--space-2); }

  .learning-card {
    text-align: left;
    width: 100%;
    background: var(--surface-1);
    border: none;
    border-radius: var(--radius-md);
    padding: var(--space-4) var(--space-6);
    cursor: pointer;
    transition: background var(--duration-fast) var(--ease-out);
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
    font-family: inherit;
  }
  .learning-card:hover { background: var(--surface-2); }

  .learning-header {
    display: flex;
    align-items: baseline;
    gap: var(--space-3);
  }

  .type-tag {
    font-size: var(--text-xs);
    font-family: var(--font-mono);
    padding: 1px 6px;
    border-radius: var(--radius-sm);
    flex-shrink: 0;
  }
  .type-tag[data-type="pattern"] { color: var(--status-healthy); background: var(--status-healthy-bg); }
  .type-tag[data-type="failure"] { color: var(--status-error); background: var(--status-error-bg); }
  .type-tag[data-type="gotcha"] { color: var(--status-attention); background: var(--status-attention-bg); }
  .type-tag[data-type="preference"] { color: var(--text-secondary); background: var(--surface-2); }

  .learning-insight {
    font-size: var(--text-sm);
    color: var(--text-primary);
    line-height: var(--leading-normal);
  }

  .hit-count {
    font-size: var(--text-xs);
    color: var(--text-tertiary);
    flex-shrink: 0;
  }

  .learning-detail {
    padding-top: var(--space-2);
    border-top: 1px solid var(--surface-2);
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
  }

  .detail-row {
    display: flex;
    gap: var(--space-3);
    font-size: var(--text-sm);
  }
  .detail-label {
    color: var(--text-tertiary);
    flex-shrink: 0;
    min-width: 80px;
  }
  .detail-value { color: var(--text-secondary); }

  /* Sections */
  .section { display: flex; flex-direction: column; gap: var(--space-4); }
  .section-title { font-size: var(--text-lg); font-weight: 500; letter-spacing: var(--tracking-tight); }

  .context-list { display: flex; flex-direction: column; }
  .context-row {
    display: flex;
    gap: var(--space-3);
    padding: var(--space-3) 0;
    border-bottom: 1px solid var(--surface-2);
    align-items: baseline;
  }
  .context-row:last-child { border-bottom: none; }
  .context-time { font-size: var(--text-xs); color: var(--text-tertiary); min-width: 60px; }
  .context-agent { font-size: var(--text-xs); color: var(--text-secondary); min-width: 100px; }
  .context-detail { font-size: var(--text-sm); color: var(--text-primary); }
  .tag { font-size: var(--text-xs); font-family: var(--font-mono); color: var(--text-tertiary); background: var(--surface-2); padding: 2px 8px; border-radius: var(--radius-sm); }

  .verdict-badge { font-family: var(--font-mono); font-size: var(--text-xs); padding: 2px 8px; border-radius: var(--radius-sm); }
  .verdict-badge[data-result="pass"] { color: var(--status-healthy); background: var(--status-healthy-bg); }
  .verdict-badge[data-result="fail"] { color: var(--status-error); background: var(--status-error-bg); }

  .empty { color: var(--text-tertiary); font-size: var(--text-sm); padding: var(--space-4) 0; }
</style>
