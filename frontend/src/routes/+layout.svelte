<script lang="ts">
  import '../app.css';
  import NavButtons from '$lib/components/NavButtons.svelte';

  let { children } = $props();
</script>

<svelte:head>
  <title>the interface — KERNEL</title>
</svelte:head>

<div class="shell">
  <NavButtons />
  <main class="content">
    {@render children()}
  </main>
</div>

<style>
  .shell {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
  }

  .content {
    flex: 1;
    padding: var(--space-8);
    max-width: 1120px;
    width: 100%;
    margin: 0 auto;
  }
</style>
