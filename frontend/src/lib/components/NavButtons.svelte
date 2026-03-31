<script lang="ts">
  import { page } from '$app/state';

  const tabs = [
    { href: '/', label: 'Status' },
    { href: '/memory', label: 'Memory' },
    { href: '/files', label: 'Files' },
    { href: '/github', label: 'GitHub' },
  ];

  function isActive(href: string): boolean {
    if (href === '/') return page.url.pathname === '/';
    return page.url.pathname.startsWith(href);
  }
</script>

<nav class="nav-buttons">
  <div class="nav-left">
    <a href="/" class="brand font-serif">the interface</a>
  </div>
  <div class="nav-center">
    {#each tabs as tab}
      <a
        href={tab.href}
        class="nav-btn"
        class:active={isActive(tab.href)}
      >
        {tab.label}
      </a>
    {/each}
  </div>
  <div class="nav-right">
    <a href="/help" class="nav-btn help-btn" class:active={isActive('/help')}>
      Help
    </a>
  </div>
</nav>

<style>
  .nav-buttons {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: var(--space-4) var(--space-8);
    border-bottom: 1px solid var(--surface-2);
    background: var(--surface-0);
    position: sticky;
    top: 0;
    z-index: 50;
  }

  .nav-left {
    flex: 0 0 auto;
  }

  .brand {
    font-size: var(--text-lg);
    font-weight: 300;
    color: var(--text-primary);
    text-decoration: none;
    letter-spacing: var(--tracking-tight);
  }

  .nav-center {
    display: flex;
    gap: var(--space-1);
  }

  .nav-right {
    flex: 0 0 auto;
  }

  .nav-btn {
    font-family: var(--font-body);
    font-size: var(--text-sm);
    font-weight: 500;
    color: var(--text-tertiary);
    text-decoration: none;
    padding: var(--space-2) var(--space-4);
    border-radius: var(--radius-md);
    transition: all var(--duration-fast) var(--ease-out);
    cursor: pointer;
    user-select: none;
  }

  .nav-btn:hover {
    color: var(--text-secondary);
    background: var(--surface-1);
  }

  .nav-btn.active {
    color: var(--text-primary);
    background: var(--surface-2);
  }

  .help-btn {
    color: var(--text-tertiary);
  }

  .help-btn:hover {
    color: var(--accent);
    background: var(--accent-subtle);
  }

  .help-btn.active {
    color: var(--accent);
    background: var(--accent-subtle);
  }
</style>
