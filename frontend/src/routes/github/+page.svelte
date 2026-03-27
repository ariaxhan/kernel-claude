<script lang="ts">
  let { data } = $props();

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
    <h1 class="font-serif">GitHub</h1>
    {#if data.connected}
      <p class="subtitle font-mono">{data.remote}</p>
    {:else}
      <p class="subtitle">No git remote configured, or gh CLI not authenticated.</p>
    {/if}
  </section>

  {#if data.connected}
    <!-- Issues -->
    <section class="section">
      <h2 class="section-title font-serif">Issues</h2>
      {#if data.issues.length > 0}
        <div class="list">
          {#each data.issues as issue}
            <div class="row">
              <span class="row-num font-mono">#{issue.number}</span>
              <span class="row-title">{issue.title}</span>
              <div class="row-meta">
                {#each issue.labels as label}
                  <span class="label-tag">{label}</span>
                {/each}
                <span class="row-time font-mono">{timeAgo(issue.createdAt)}</span>
              </div>
            </div>
          {/each}
        </div>
      {:else}
        <p class="empty">No open issues.</p>
      {/if}
    </section>

    <!-- PRs -->
    <section class="section">
      <h2 class="section-title font-serif">Pull Requests</h2>
      {#if data.prs.length > 0}
        <div class="list">
          {#each data.prs as pr}
            <div class="row">
              <span class="row-num font-mono">#{pr.number}</span>
              <span class="row-title">{pr.title}</span>
              <div class="row-meta">
                <span class="branch-tag font-mono">{pr.headRefName}</span>
                <span class="row-time font-mono">{timeAgo(pr.createdAt)}</span>
              </div>
            </div>
          {/each}
        </div>
      {:else}
        <p class="empty">No open pull requests.</p>
      {/if}
    </section>
  {:else}
    <section class="disconnected">
      <p>To connect GitHub, make sure:</p>
      <ol>
        <li>This repo has a git remote (<code class="font-mono">git remote add origin ...</code>)</li>
        <li>GitHub CLI is installed and authenticated (<code class="font-mono">gh auth login</code>)</li>
      </ol>
    </section>
  {/if}
</div>

<style>
  .page { display: flex; flex-direction: column; gap: var(--space-8); }

  .header h1 { font-size: var(--text-2xl); font-weight: 300; letter-spacing: var(--tracking-tight); }
  .subtitle { color: var(--text-secondary); font-size: var(--text-sm); margin-top: var(--space-1); }

  .section { display: flex; flex-direction: column; gap: var(--space-4); }
  .section-title { font-size: var(--text-lg); font-weight: 500; letter-spacing: var(--tracking-tight); }

  .list { display: flex; flex-direction: column; }

  .row {
    display: flex;
    align-items: baseline;
    gap: var(--space-3);
    padding: var(--space-3) 0;
    border-bottom: 1px solid var(--surface-2);
    flex-wrap: wrap;
  }
  .row:last-child { border-bottom: none; }

  .row-num { font-size: var(--text-sm); color: var(--accent); flex-shrink: 0; min-width: 40px; }
  .row-title { font-size: var(--text-sm); color: var(--text-primary); flex: 1; min-width: 200px; }

  .row-meta {
    display: flex; gap: var(--space-2); align-items: center;
    margin-left: auto;
  }

  .row-time { font-size: var(--text-xs); color: var(--text-tertiary); }

  .label-tag {
    font-size: var(--text-xs); font-family: var(--font-mono);
    color: var(--accent); background: var(--accent-subtle);
    padding: 1px 8px; border-radius: var(--radius-sm);
  }

  .branch-tag {
    font-size: var(--text-xs);
    color: var(--text-secondary); background: var(--surface-2);
    padding: 1px 8px; border-radius: var(--radius-sm);
  }

  .empty { color: var(--text-tertiary); font-size: var(--text-sm); }

  .disconnected {
    background: var(--surface-1);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
    font-size: var(--text-sm);
    color: var(--text-secondary);
    line-height: var(--leading-relaxed);
  }
  .disconnected ol {
    margin-top: var(--space-3);
    padding-left: var(--space-6);
    display: flex; flex-direction: column; gap: var(--space-2);
  }
  .disconnected code {
    background: var(--surface-2);
    padding: 1px 6px;
    border-radius: var(--radius-sm);
  }
</style>
