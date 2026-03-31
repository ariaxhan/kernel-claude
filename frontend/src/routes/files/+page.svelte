<script lang="ts">
  import type { FileNode } from '$lib/types';

  let { data } = $props();

  let expandedPaths = $state<Set<string>>(new Set(['_meta', '_meta/agentdb', '_meta/research']));

  function toggleDir(path: string) {
    const next = new Set(expandedPaths);
    if (next.has(path)) next.delete(path); else next.add(path);
    expandedPaths = next;
  }

  function fileIcon(node: FileNode): string {
    if (node.type === 'directory') return expandedPaths.has(node.path) ? '&#9662;' : '&#9656;';
    const ext = node.name.split('.').pop();
    if (ext === 'md') return '&#9636;';
    if (ext === 'sh') return '&#9654;';
    if (ext === 'json') return '&#123;';
    if (ext === 'db') return '&#9673;';
    return '&#9643;';
  }
</script>

<div class="page">
  <section class="header">
    <h1 class="font-serif">Files</h1>
    <p class="subtitle">Project structure and _meta artifacts.</p>
  </section>

  <div class="trees">
    <section class="tree-section">
      <h2 class="tree-title font-serif">_meta/</h2>
      <p class="tree-desc">Session artifacts, AgentDB, research, handoffs.</p>
      <div class="tree">
        {#each data.metaTree as node}
          {@render treeNode(node, 0)}
        {/each}
      </div>
    </section>

    <section class="tree-section">
      <h2 class="tree-title font-serif">Repo Structure</h2>
      <p class="tree-desc">Core KERNEL components.</p>
      <div class="tree">
        {#each data.repoTree as node}
          {@render treeNode(node, 0)}
        {/each}
      </div>
    </section>
  </div>
</div>

{#snippet treeNode(node: FileNode, depth: number)}
  {#if node.type === 'directory'}
    <button
      class="tree-row dir"
      style="padding-left: {depth * 20 + 8}px"
      onclick={() => toggleDir(node.path)}
    >
      <span class="tree-icon">{@html fileIcon(node)}</span>
      <span class="tree-name">{node.name}/</span>
      {#if node.children}
        <span class="tree-count font-mono">{node.children.length}</span>
      {/if}
    </button>
    {#if expandedPaths.has(node.path) && node.children}
      {#each node.children as child}
        {@render treeNode(child, depth + 1)}
      {/each}
    {/if}
  {:else}
    <div class="tree-row file" style="padding-left: {depth * 20 + 8}px">
      <span class="tree-icon">{@html fileIcon(node)}</span>
      <span class="tree-name">{node.name}</span>
    </div>
  {/if}
{/snippet}

<style>
  .page { display: flex; flex-direction: column; gap: var(--space-8); }

  .header h1 {
    font-size: var(--text-2xl); font-weight: 300;
    letter-spacing: var(--tracking-tight);
  }
  .subtitle { color: var(--text-secondary); font-size: var(--text-sm); margin-top: var(--space-1); }

  .trees {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: var(--space-8);
  }

  .tree-section {
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .tree-title { font-size: var(--text-lg); font-weight: 500; }
  .tree-desc { font-size: var(--text-sm); color: var(--text-secondary); }

  .tree {
    background: var(--surface-1);
    border-radius: var(--radius-lg);
    padding: var(--space-3) 0;
    overflow: hidden;
  }

  .tree-row {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-1) var(--space-3);
    font-family: var(--font-mono);
    font-size: var(--text-sm);
    width: 100%;
    text-align: left;
    background: none;
    border: none;
    cursor: default;
    color: var(--text-primary);
  }

  .tree-row.dir {
    cursor: pointer;
  }
  .tree-row.dir:hover {
    background: var(--surface-2);
  }

  .tree-icon {
    color: var(--text-tertiary);
    font-size: var(--text-xs);
    width: 14px;
    text-align: center;
    flex-shrink: 0;
  }

  .tree-name {
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .tree-count {
    font-size: var(--text-xs);
    color: var(--text-tertiary);
    margin-left: auto;
    padding-right: var(--space-2);
  }

  .file .tree-name {
    color: var(--text-secondary);
  }

  @media (max-width: 768px) {
    .trees { grid-template-columns: 1fr; }
  }
</style>
