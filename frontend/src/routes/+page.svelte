<script lang="ts">
  import type { SystemHealth, ContextEntry } from '$lib/types';

  let { data } = $props();

  function timeAgo(ts: string): string {
    const now = Date.now();
    const then = new Date(ts).getTime();
    const diff = now - then;
    const minutes = Math.floor(diff / 60000);
    if (minutes < 1) return 'just now';
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h ago`;
    const days = Math.floor(hours / 24);
    return `${days}d ago`;
  }

  function parseContent(content: string): Record<string, unknown> | null {
    try { return JSON.parse(content); } catch { return null; }
  }

  function healthStatus(health: SystemHealth): 'healthy' | 'attention' | 'error' {
    if (health.errors.recent > 5) return 'error';
    if (health.errors.recent > 0 || health.sessions.successRate < 70) return 'attention';
    return 'healthy';
  }

  const status = $derived(healthStatus(data.health));
</script>

<div class="page">
  <!-- Pulse -->
  <section class="pulse">
    <div class="pulse-indicator" data-status={status}></div>
    <div class="pulse-text">
      <h1 class="font-serif">
        {#if status === 'healthy'}System is healthy{/if}
        {#if status === 'attention'}Needs attention{/if}
        {#if status === 'error'}Issues detected{/if}
      </h1>
      <p class="branch font-mono">{data.git.branch}{#if data.git.uncommitted > 0}<span class="uncommitted"> +{data.git.uncommitted} uncommitted</span>{/if}</p>
    </div>
  </section>

  <!-- Health grid -->
  <section class="health-grid">
    <div class="health-card">
      <span class="health-value">{data.health.learnings.total}</span>
      <span class="health-label">Learnings</span>
      <div class="health-breakdown">
        <span class="tag tag-pattern">{data.health.learnings.patterns} patterns</span>
        <span class="tag tag-failure">{data.health.learnings.failures} failures</span>
        <span class="tag tag-gotcha">{data.health.learnings.gotchas} gotchas</span>
      </div>
    </div>

    <div class="health-card">
      <span class="health-value">{data.health.sessions.total}</span>
      <span class="health-label">Sessions</span>
      <div class="health-breakdown">
        <span class="tag">{data.health.sessions.recent} this week</span>
        {#if data.health.sessions.successRate > 0}
          <span class="tag" class:tag-pattern={data.health.sessions.successRate >= 80} class:tag-failure={data.health.sessions.successRate < 60}>{data.health.sessions.successRate}% success</span>
        {/if}
      </div>
    </div>

    <div class="health-card">
      <span class="health-value">{data.health.errors.total}</span>
      <span class="health-label">Errors</span>
      <div class="health-breakdown">
        <span class="tag" class:tag-failure={data.health.errors.recent > 0}>{data.health.errors.recent} this week</span>
      </div>
    </div>

    <div class="health-card">
      <span class="health-value">{data.health.agents.total}</span>
      <span class="health-label">Active agents</span>
      {#if data.health.lastCheckpoint}
        <div class="health-breakdown">
          <span class="tag">last checkpoint {timeAgo(data.health.lastCheckpoint)}</span>
        </div>
      {/if}
    </div>
  </section>

  <!-- Active contract -->
  {#if data.activeContract}
    <section class="section">
      <h2 class="section-title font-serif">Active Contract</h2>
      <div class="contract-card">
        {#if data.activeContract.parsed}
          <p class="contract-goal">{data.activeContract.parsed.goal}</p>
          {#if data.activeContract.parsed.tier}
            <span class="tag">Tier {data.activeContract.parsed.tier}</span>
          {/if}
          {#if data.activeContract.parsed.files}
            <div class="contract-files font-mono">
              {#each data.activeContract.parsed.files as file}
                <span class="file-pill">{file}</span>
              {/each}
            </div>
          {/if}
          {#if data.activeContract.parsed.constraints}
            <p class="contract-constraints">{data.activeContract.parsed.constraints}</p>
          {/if}
        {:else}
          <pre class="font-mono">{data.activeContract.content}</pre>
        {/if}
      </div>
    </section>
  {/if}

  <!-- Recent activity -->
  <section class="section">
    <h2 class="section-title font-serif">Recent Activity</h2>
    <div class="activity-list">
      {#each data.recentCheckpoints as cp}
        {@const parsed = parseContent(cp.content)}
        <div class="activity-row">
          <span class="activity-time font-mono">{timeAgo(cp.ts)}</span>
          <span class="activity-agent font-mono">{cp.agent}</span>
          <span class="activity-detail">
            {#if parsed?.did}
              {parsed.did}
            {:else if parsed?.event}
              {parsed.event}
            {:else}
              checkpoint
            {/if}
          </span>
        </div>
      {/each}
      {#if data.recentCheckpoints.length === 0}
        <p class="empty">No checkpoints yet. Start a session to see activity here.</p>
      {/if}
    </div>
  </section>

  <!-- Git log -->
  <section class="section">
    <h2 class="section-title font-serif">Recent Commits</h2>
    <div class="git-log">
      {#each data.git.log as commit}
        <div class="commit-row">
          <span class="commit-hash font-mono">{commit.hash}</span>
          <span class="commit-msg">{commit.message}</span>
        </div>
      {/each}
    </div>
  </section>
</div>

<style>
  .page {
    display: flex;
    flex-direction: column;
    gap: var(--space-8);
  }

  /* Pulse */
  .pulse {
    display: flex;
    align-items: center;
    gap: var(--space-4);
    padding: var(--space-6) 0;
  }

  .pulse-indicator {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .pulse-indicator[data-status="healthy"] {
    background: var(--status-healthy);
    box-shadow: 0 0 8px var(--status-healthy);
  }

  .pulse-indicator[data-status="attention"] {
    background: var(--status-attention);
    box-shadow: 0 0 8px var(--status-attention);
  }

  .pulse-indicator[data-status="error"] {
    background: var(--status-error);
    box-shadow: 0 0 8px var(--status-error);
  }

  .pulse-text h1 {
    font-size: var(--text-2xl);
    font-weight: 300;
    letter-spacing: var(--tracking-tight);
    line-height: var(--leading-tight);
  }

  .branch {
    color: var(--text-secondary);
    font-size: var(--text-sm);
    margin-top: var(--space-1);
  }

  .uncommitted {
    color: var(--status-attention);
  }

  /* Health grid */
  .health-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: var(--space-4);
  }

  .health-card {
    background: var(--surface-1);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
  }

  .health-value {
    font-family: var(--font-serif);
    font-size: var(--text-3xl);
    font-weight: 300;
    line-height: 1;
  }

  .health-label {
    font-size: var(--text-sm);
    color: var(--text-secondary);
  }

  .health-breakdown {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-1);
    margin-top: var(--space-1);
  }

  .tag {
    font-size: var(--text-xs);
    font-family: var(--font-mono);
    color: var(--text-tertiary);
    background: var(--surface-2);
    padding: 2px 8px;
    border-radius: var(--radius-sm);
  }

  .tag-pattern { color: var(--status-healthy); background: var(--status-healthy-bg); }
  .tag-failure { color: var(--status-error); background: var(--status-error-bg); }
  .tag-gotcha { color: var(--status-attention); background: var(--status-attention-bg); }

  /* Sections */
  .section {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  .section-title {
    font-size: var(--text-lg);
    font-weight: 500;
    letter-spacing: var(--tracking-tight);
  }

  /* Contract */
  .contract-card {
    background: var(--surface-1);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .contract-goal {
    font-size: var(--text-base);
    line-height: var(--leading-relaxed);
  }

  .contract-files {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-2);
  }

  .file-pill {
    font-size: var(--text-xs);
    color: var(--text-secondary);
    background: var(--surface-2);
    padding: 2px 10px;
    border-radius: var(--radius-sm);
  }

  .contract-constraints {
    font-size: var(--text-sm);
    color: var(--text-secondary);
    line-height: var(--leading-relaxed);
  }

  /* Activity */
  .activity-list {
    display: flex;
    flex-direction: column;
  }

  .activity-row {
    display: grid;
    grid-template-columns: 80px 120px 1fr;
    gap: var(--space-3);
    padding: var(--space-3) 0;
    border-bottom: 1px solid var(--surface-2);
    align-items: baseline;
  }

  .activity-row:last-child {
    border-bottom: none;
  }

  .activity-time {
    font-size: var(--text-xs);
    color: var(--text-tertiary);
  }

  .activity-agent {
    font-size: var(--text-xs);
    color: var(--text-secondary);
  }

  .activity-detail {
    font-size: var(--text-sm);
    color: var(--text-primary);
  }

  /* Git log */
  .git-log {
    display: flex;
    flex-direction: column;
  }

  .commit-row {
    display: flex;
    gap: var(--space-3);
    padding: var(--space-2) 0;
    border-bottom: 1px solid var(--surface-2);
    align-items: baseline;
  }

  .commit-row:last-child {
    border-bottom: none;
  }

  .commit-hash {
    font-size: var(--text-xs);
    color: var(--accent);
    flex-shrink: 0;
  }

  .commit-msg {
    font-size: var(--text-sm);
    color: var(--text-primary);
  }

  .empty {
    color: var(--text-tertiary);
    font-size: var(--text-sm);
    padding: var(--space-4) 0;
  }

  @media (max-width: 768px) {
    .health-grid {
      grid-template-columns: repeat(2, 1fr);
    }
    .activity-row {
      grid-template-columns: 80px 1fr;
    }
    .activity-agent {
      display: none;
    }
  }
</style>
