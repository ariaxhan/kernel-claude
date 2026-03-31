import { b as attr_class, c as escape_html, e as ensure_array_like, a as attr, a3 as derived } from "../../../chunks/index.js";
function _page($$renderer, $$props) {
  $$renderer.component(($$renderer2) => {
    let { data } = $$props;
    let activeFilter = "all";
    let expandedIds = /* @__PURE__ */ new Set();
    const allLearnings = derived(() => [
      ...data.patterns,
      ...data.failures,
      ...data.gotchas,
      ...data.preferences
    ].sort((a, b) => (b.hit_count ?? 0) - (a.hit_count ?? 0)));
    const filtered = derived(
      () => allLearnings()
    );
    function parseContent(content) {
      try {
        return JSON.parse(content);
      } catch {
        return null;
      }
    }
    function typeLabel(type) {
      return {
        pattern: "Pattern",
        failure: "Failure",
        gotcha: "Gotcha",
        preference: "Preference"
      }[type] ?? type;
    }
    function timeAgo(ts) {
      const diff = Date.now() - new Date(ts).getTime();
      const d = Math.floor(diff / 864e5);
      if (d === 0) return "today";
      if (d === 1) return "yesterday";
      return `${d}d ago`;
    }
    $$renderer2.push(`<div class="page svelte-1czmmpc"><section class="header svelte-1czmmpc"><h1 class="font-serif svelte-1czmmpc">Memory</h1> <p class="subtitle svelte-1czmmpc">Everything KERNEL has learned across sessions.</p></section> <section class="filters svelte-1czmmpc"><button${attr_class("filter-btn svelte-1czmmpc", void 0, { "active": activeFilter === "all" })}>All <span class="count svelte-1czmmpc">${escape_html(allLearnings().length)}</span></button> <button${attr_class("filter-btn filter-pattern svelte-1czmmpc", void 0, { "active": activeFilter === "pattern" })}>Patterns <span class="count svelte-1czmmpc">${escape_html(data.patterns.length)}</span></button> <button${attr_class("filter-btn filter-failure svelte-1czmmpc", void 0, { "active": activeFilter === "failure" })}>Failures <span class="count svelte-1czmmpc">${escape_html(data.failures.length)}</span></button> <button${attr_class("filter-btn filter-gotcha svelte-1czmmpc", void 0, { "active": activeFilter === "gotcha" })}>Gotchas <span class="count svelte-1czmmpc">${escape_html(data.gotchas.length)}</span></button> `);
    if (data.preferences.length > 0) {
      $$renderer2.push("<!--[0-->");
      $$renderer2.push(`<button${attr_class("filter-btn svelte-1czmmpc", void 0, { "active": activeFilter === "preference" })}>Preferences <span class="count svelte-1czmmpc">${escape_html(data.preferences.length)}</span></button>`);
    } else {
      $$renderer2.push("<!--[-1-->");
    }
    $$renderer2.push(`<!--]--></section> <section class="learnings svelte-1czmmpc"><!--[-->`);
    const each_array = ensure_array_like(filtered());
    for (let $$index = 0, $$length = each_array.length; $$index < $$length; $$index++) {
      let learning = each_array[$$index];
      $$renderer2.push(`<button class="learning-card svelte-1czmmpc"><div class="learning-header svelte-1czmmpc"><span class="type-tag svelte-1czmmpc"${attr("data-type", learning.type)}>${escape_html(typeLabel(learning.type))}</span> <span class="learning-insight svelte-1czmmpc">${escape_html(learning.insight)}</span> `);
      if (learning.hit_count > 1) {
        $$renderer2.push("<!--[0-->");
        $$renderer2.push(`<span class="hit-count font-mono svelte-1czmmpc">${escape_html(learning.hit_count)}x</span>`);
      } else {
        $$renderer2.push("<!--[-1-->");
      }
      $$renderer2.push(`<!--]--></div> `);
      if (expandedIds.has(learning.id)) {
        $$renderer2.push("<!--[0-->");
        $$renderer2.push(`<div class="learning-detail svelte-1czmmpc">`);
        if (learning.evidence) {
          $$renderer2.push("<!--[0-->");
          $$renderer2.push(`<div class="detail-row svelte-1czmmpc"><span class="detail-label svelte-1czmmpc">Evidence</span> <span class="detail-value svelte-1czmmpc">${escape_html(learning.evidence)}</span></div>`);
        } else {
          $$renderer2.push("<!--[-1-->");
        }
        $$renderer2.push(`<!--]--> `);
        if (learning.domain) {
          $$renderer2.push("<!--[0-->");
          $$renderer2.push(`<div class="detail-row svelte-1czmmpc"><span class="detail-label svelte-1czmmpc">Domain</span> <span class="detail-value font-mono svelte-1czmmpc">${escape_html(learning.domain)}</span></div>`);
        } else {
          $$renderer2.push("<!--[-1-->");
        }
        $$renderer2.push(`<!--]--> <div class="detail-row svelte-1czmmpc"><span class="detail-label svelte-1czmmpc">Last seen</span> <span class="detail-value svelte-1czmmpc">${escape_html(timeAgo(learning.last_hit || learning.ts))}</span></div></div>`);
      } else {
        $$renderer2.push("<!--[-1-->");
      }
      $$renderer2.push(`<!--]--></button>`);
    }
    $$renderer2.push(`<!--]--> `);
    if (filtered().length === 0) {
      $$renderer2.push("<!--[0-->");
      $$renderer2.push(`<p class="empty svelte-1czmmpc">No learnings recorded yet.</p>`);
    } else {
      $$renderer2.push("<!--[-1-->");
    }
    $$renderer2.push(`<!--]--></section> `);
    if (data.contracts.length > 0) {
      $$renderer2.push("<!--[0-->");
      $$renderer2.push(`<section class="section svelte-1czmmpc"><h2 class="section-title font-serif svelte-1czmmpc">Contracts</h2> <div class="context-list svelte-1czmmpc"><!--[-->`);
      const each_array_1 = ensure_array_like(data.contracts);
      for (let $$index_1 = 0, $$length = each_array_1.length; $$index_1 < $$length; $$index_1++) {
        let entry = each_array_1[$$index_1];
        const parsed = parseContent(entry.content);
        $$renderer2.push(`<div class="context-row svelte-1czmmpc"><span class="context-time font-mono svelte-1czmmpc">${escape_html(timeAgo(entry.ts))}</span> <span class="context-detail svelte-1czmmpc">`);
        if (parsed?.goal) {
          $$renderer2.push("<!--[0-->");
          $$renderer2.push(`${escape_html(parsed.goal)}`);
        } else {
          $$renderer2.push("<!--[-1-->");
          $$renderer2.push(`${escape_html(entry.content)}`);
        }
        $$renderer2.push(`<!--]--></span> `);
        if (parsed?.tier) {
          $$renderer2.push("<!--[0-->");
          $$renderer2.push(`<span class="tag svelte-1czmmpc">T${escape_html(parsed.tier)}</span>`);
        } else {
          $$renderer2.push("<!--[-1-->");
        }
        $$renderer2.push(`<!--]--></div>`);
      }
      $$renderer2.push(`<!--]--></div></section>`);
    } else {
      $$renderer2.push("<!--[-1-->");
    }
    $$renderer2.push(`<!--]--> `);
    if (data.verdicts.length > 0) {
      $$renderer2.push("<!--[0-->");
      $$renderer2.push(`<section class="section svelte-1czmmpc"><h2 class="section-title font-serif svelte-1czmmpc">Verdicts</h2> <div class="context-list svelte-1czmmpc"><!--[-->`);
      const each_array_2 = ensure_array_like(data.verdicts);
      for (let $$index_2 = 0, $$length = each_array_2.length; $$index_2 < $$length; $$index_2++) {
        let entry = each_array_2[$$index_2];
        const parsed = parseContent(entry.content);
        $$renderer2.push(`<div class="context-row svelte-1czmmpc"><span class="context-time font-mono svelte-1czmmpc">${escape_html(timeAgo(entry.ts))}</span> <span class="context-agent font-mono svelte-1czmmpc">${escape_html(entry.agent)}</span> <span class="context-detail svelte-1czmmpc">`);
        if (parsed?.result) {
          $$renderer2.push("<!--[0-->");
          $$renderer2.push(`<span class="verdict-badge svelte-1czmmpc"${attr("data-result", parsed.result)}>${escape_html(parsed.result)}</span>`);
        } else {
          $$renderer2.push("<!--[-1-->");
        }
        $$renderer2.push(`<!--]--></span></div>`);
      }
      $$renderer2.push(`<!--]--></div></section>`);
    } else {
      $$renderer2.push("<!--[-1-->");
    }
    $$renderer2.push(`<!--]--></div>`);
  });
}
export {
  _page as default
};
