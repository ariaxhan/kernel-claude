import { a as attr, c as escape_html, b as attr_class, e as ensure_array_like, a3 as derived } from "../../chunks/index.js";
function _page($$renderer, $$props) {
  $$renderer.component(($$renderer2) => {
    let { data } = $$props;
    function timeAgo(ts) {
      const now = Date.now();
      const then = new Date(ts).getTime();
      const diff = now - then;
      const minutes = Math.floor(diff / 6e4);
      if (minutes < 1) return "just now";
      if (minutes < 60) return `${minutes}m ago`;
      const hours = Math.floor(minutes / 60);
      if (hours < 24) return `${hours}h ago`;
      const days = Math.floor(hours / 24);
      return `${days}d ago`;
    }
    function parseContent(content) {
      try {
        return JSON.parse(content);
      } catch {
        return null;
      }
    }
    function healthStatus(health) {
      if (health.errors.recent > 5) return "error";
      if (health.errors.recent > 0 || health.sessions.successRate < 70) return "attention";
      return "healthy";
    }
    const status = derived(() => healthStatus(data.health));
    $$renderer2.push(`<div class="page svelte-1uha8ag"><section class="pulse svelte-1uha8ag"><div class="pulse-indicator svelte-1uha8ag"${attr("data-status", status())}></div> <div class="pulse-text svelte-1uha8ag"><h1 class="font-serif svelte-1uha8ag">`);
    if (status() === "healthy") {
      $$renderer2.push("<!--[0-->");
      $$renderer2.push(`System is healthy`);
    } else {
      $$renderer2.push("<!--[-1-->");
    }
    $$renderer2.push(`<!--]--> `);
    if (status() === "attention") {
      $$renderer2.push("<!--[0-->");
      $$renderer2.push(`Needs attention`);
    } else {
      $$renderer2.push("<!--[-1-->");
    }
    $$renderer2.push(`<!--]--> `);
    if (status() === "error") {
      $$renderer2.push("<!--[0-->");
      $$renderer2.push(`Issues detected`);
    } else {
      $$renderer2.push("<!--[-1-->");
    }
    $$renderer2.push(`<!--]--></h1> <p class="branch font-mono svelte-1uha8ag">${escape_html(data.git.branch)}`);
    if (data.git.uncommitted > 0) {
      $$renderer2.push("<!--[0-->");
      $$renderer2.push(`<span class="uncommitted svelte-1uha8ag">+${escape_html(data.git.uncommitted)} uncommitted</span>`);
    } else {
      $$renderer2.push("<!--[-1-->");
    }
    $$renderer2.push(`<!--]--></p></div></section> <section class="health-grid svelte-1uha8ag"><div class="health-card svelte-1uha8ag"><span class="health-value svelte-1uha8ag">${escape_html(data.health.learnings.total)}</span> <span class="health-label svelte-1uha8ag">Learnings</span> <div class="health-breakdown svelte-1uha8ag"><span class="tag tag-pattern svelte-1uha8ag">${escape_html(data.health.learnings.patterns)} patterns</span> <span class="tag tag-failure svelte-1uha8ag">${escape_html(data.health.learnings.failures)} failures</span> <span class="tag tag-gotcha svelte-1uha8ag">${escape_html(data.health.learnings.gotchas)} gotchas</span></div></div> <div class="health-card svelte-1uha8ag"><span class="health-value svelte-1uha8ag">${escape_html(data.health.sessions.total)}</span> <span class="health-label svelte-1uha8ag">Sessions</span> <div class="health-breakdown svelte-1uha8ag"><span class="tag svelte-1uha8ag">${escape_html(data.health.sessions.recent)} this week</span> `);
    if (data.health.sessions.successRate > 0) {
      $$renderer2.push("<!--[0-->");
      $$renderer2.push(`<span${attr_class("tag svelte-1uha8ag", void 0, {
        "tag-pattern": data.health.sessions.successRate >= 80,
        "tag-failure": data.health.sessions.successRate < 60
      })}>${escape_html(data.health.sessions.successRate)}% success</span>`);
    } else {
      $$renderer2.push("<!--[-1-->");
    }
    $$renderer2.push(`<!--]--></div></div> <div class="health-card svelte-1uha8ag"><span class="health-value svelte-1uha8ag">${escape_html(data.health.errors.total)}</span> <span class="health-label svelte-1uha8ag">Errors</span> <div class="health-breakdown svelte-1uha8ag"><span${attr_class("tag svelte-1uha8ag", void 0, { "tag-failure": data.health.errors.recent > 0 })}>${escape_html(data.health.errors.recent)} this week</span></div></div> <div class="health-card svelte-1uha8ag"><span class="health-value svelte-1uha8ag">${escape_html(data.health.agents.total)}</span> <span class="health-label svelte-1uha8ag">Active agents</span> `);
    if (data.health.lastCheckpoint) {
      $$renderer2.push("<!--[0-->");
      $$renderer2.push(`<div class="health-breakdown svelte-1uha8ag"><span class="tag svelte-1uha8ag">last checkpoint ${escape_html(timeAgo(data.health.lastCheckpoint))}</span></div>`);
    } else {
      $$renderer2.push("<!--[-1-->");
    }
    $$renderer2.push(`<!--]--></div></section> `);
    if (data.activeContract) {
      $$renderer2.push("<!--[0-->");
      $$renderer2.push(`<section class="section svelte-1uha8ag"><h2 class="section-title font-serif svelte-1uha8ag">Active Contract</h2> <div class="contract-card svelte-1uha8ag">`);
      if (data.activeContract.parsed) {
        $$renderer2.push("<!--[0-->");
        $$renderer2.push(`<p class="contract-goal svelte-1uha8ag">${escape_html(data.activeContract.parsed.goal)}</p> `);
        if (data.activeContract.parsed.tier) {
          $$renderer2.push("<!--[0-->");
          $$renderer2.push(`<span class="tag svelte-1uha8ag">Tier ${escape_html(data.activeContract.parsed.tier)}</span>`);
        } else {
          $$renderer2.push("<!--[-1-->");
        }
        $$renderer2.push(`<!--]--> `);
        if (data.activeContract.parsed.files) {
          $$renderer2.push("<!--[0-->");
          $$renderer2.push(`<div class="contract-files font-mono svelte-1uha8ag"><!--[-->`);
          const each_array = ensure_array_like(data.activeContract.parsed.files);
          for (let $$index = 0, $$length = each_array.length; $$index < $$length; $$index++) {
            let file = each_array[$$index];
            $$renderer2.push(`<span class="file-pill svelte-1uha8ag">${escape_html(file)}</span>`);
          }
          $$renderer2.push(`<!--]--></div>`);
        } else {
          $$renderer2.push("<!--[-1-->");
        }
        $$renderer2.push(`<!--]--> `);
        if (data.activeContract.parsed.constraints) {
          $$renderer2.push("<!--[0-->");
          $$renderer2.push(`<p class="contract-constraints svelte-1uha8ag">${escape_html(data.activeContract.parsed.constraints)}</p>`);
        } else {
          $$renderer2.push("<!--[-1-->");
        }
        $$renderer2.push(`<!--]-->`);
      } else {
        $$renderer2.push("<!--[-1-->");
        $$renderer2.push(`<pre class="font-mono">${escape_html(data.activeContract.content)}</pre>`);
      }
      $$renderer2.push(`<!--]--></div></section>`);
    } else {
      $$renderer2.push("<!--[-1-->");
    }
    $$renderer2.push(`<!--]--> <section class="section svelte-1uha8ag"><h2 class="section-title font-serif svelte-1uha8ag">Recent Activity</h2> <div class="activity-list svelte-1uha8ag"><!--[-->`);
    const each_array_1 = ensure_array_like(data.recentCheckpoints);
    for (let $$index_1 = 0, $$length = each_array_1.length; $$index_1 < $$length; $$index_1++) {
      let cp = each_array_1[$$index_1];
      const parsed = parseContent(cp.content);
      $$renderer2.push(`<div class="activity-row svelte-1uha8ag"><span class="activity-time font-mono svelte-1uha8ag">${escape_html(timeAgo(cp.ts))}</span> <span class="activity-agent font-mono svelte-1uha8ag">${escape_html(cp.agent)}</span> <span class="activity-detail svelte-1uha8ag">`);
      if (parsed?.did) {
        $$renderer2.push("<!--[0-->");
        $$renderer2.push(`${escape_html(parsed.did)}`);
      } else if (parsed?.event) {
        $$renderer2.push("<!--[1-->");
        $$renderer2.push(`${escape_html(parsed.event)}`);
      } else {
        $$renderer2.push("<!--[-1-->");
        $$renderer2.push(`checkpoint`);
      }
      $$renderer2.push(`<!--]--></span></div>`);
    }
    $$renderer2.push(`<!--]--> `);
    if (data.recentCheckpoints.length === 0) {
      $$renderer2.push("<!--[0-->");
      $$renderer2.push(`<p class="empty svelte-1uha8ag">No checkpoints yet. Start a session to see activity here.</p>`);
    } else {
      $$renderer2.push("<!--[-1-->");
    }
    $$renderer2.push(`<!--]--></div></section> <section class="section svelte-1uha8ag"><h2 class="section-title font-serif svelte-1uha8ag">Recent Commits</h2> <div class="git-log svelte-1uha8ag"><!--[-->`);
    const each_array_2 = ensure_array_like(data.git.log);
    for (let $$index_2 = 0, $$length = each_array_2.length; $$index_2 < $$length; $$index_2++) {
      let commit = each_array_2[$$index_2];
      $$renderer2.push(`<div class="commit-row svelte-1uha8ag"><span class="commit-hash font-mono svelte-1uha8ag">${escape_html(commit.hash)}</span> <span class="commit-msg svelte-1uha8ag">${escape_html(commit.message)}</span></div>`);
    }
    $$renderer2.push(`<!--]--></div></section></div>`);
  });
}
export {
  _page as default
};
