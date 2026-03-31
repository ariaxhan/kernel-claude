import { c as escape_html, e as ensure_array_like } from "../../../chunks/index.js";
function _page($$renderer, $$props) {
  $$renderer.component(($$renderer2) => {
    let { data } = $$props;
    function timeAgo(ts) {
      const diff = Date.now() - new Date(ts).getTime();
      const d = Math.floor(diff / 864e5);
      if (d === 0) return "today";
      if (d === 1) return "yesterday";
      return `${d}d ago`;
    }
    $$renderer2.push(`<div class="page svelte-1ma5hcs"><section class="header svelte-1ma5hcs"><h1 class="font-serif svelte-1ma5hcs">GitHub</h1> `);
    if (data.connected) {
      $$renderer2.push("<!--[0-->");
      $$renderer2.push(`<p class="subtitle font-mono svelte-1ma5hcs">${escape_html(data.remote)}</p>`);
    } else {
      $$renderer2.push("<!--[-1-->");
      $$renderer2.push(`<p class="subtitle svelte-1ma5hcs">No git remote configured, or gh CLI not authenticated.</p>`);
    }
    $$renderer2.push(`<!--]--></section> `);
    if (data.connected) {
      $$renderer2.push("<!--[0-->");
      $$renderer2.push(`<section class="section svelte-1ma5hcs"><h2 class="section-title font-serif svelte-1ma5hcs">Issues</h2> `);
      if (data.issues.length > 0) {
        $$renderer2.push("<!--[0-->");
        $$renderer2.push(`<div class="list svelte-1ma5hcs"><!--[-->`);
        const each_array = ensure_array_like(data.issues);
        for (let $$index_1 = 0, $$length = each_array.length; $$index_1 < $$length; $$index_1++) {
          let issue = each_array[$$index_1];
          $$renderer2.push(`<div class="row svelte-1ma5hcs"><span class="row-num font-mono svelte-1ma5hcs">#${escape_html(issue.number)}</span> <span class="row-title svelte-1ma5hcs">${escape_html(issue.title)}</span> <div class="row-meta svelte-1ma5hcs"><!--[-->`);
          const each_array_1 = ensure_array_like(issue.labels);
          for (let $$index = 0, $$length2 = each_array_1.length; $$index < $$length2; $$index++) {
            let label = each_array_1[$$index];
            $$renderer2.push(`<span class="label-tag svelte-1ma5hcs">${escape_html(label)}</span>`);
          }
          $$renderer2.push(`<!--]--> <span class="row-time font-mono svelte-1ma5hcs">${escape_html(timeAgo(issue.createdAt))}</span></div></div>`);
        }
        $$renderer2.push(`<!--]--></div>`);
      } else {
        $$renderer2.push("<!--[-1-->");
        $$renderer2.push(`<p class="empty svelte-1ma5hcs">No open issues.</p>`);
      }
      $$renderer2.push(`<!--]--></section> <section class="section svelte-1ma5hcs"><h2 class="section-title font-serif svelte-1ma5hcs">Pull Requests</h2> `);
      if (data.prs.length > 0) {
        $$renderer2.push("<!--[0-->");
        $$renderer2.push(`<div class="list svelte-1ma5hcs"><!--[-->`);
        const each_array_2 = ensure_array_like(data.prs);
        for (let $$index_2 = 0, $$length = each_array_2.length; $$index_2 < $$length; $$index_2++) {
          let pr = each_array_2[$$index_2];
          $$renderer2.push(`<div class="row svelte-1ma5hcs"><span class="row-num font-mono svelte-1ma5hcs">#${escape_html(pr.number)}</span> <span class="row-title svelte-1ma5hcs">${escape_html(pr.title)}</span> <div class="row-meta svelte-1ma5hcs"><span class="branch-tag font-mono svelte-1ma5hcs">${escape_html(pr.headRefName)}</span> <span class="row-time font-mono svelte-1ma5hcs">${escape_html(timeAgo(pr.createdAt))}</span></div></div>`);
        }
        $$renderer2.push(`<!--]--></div>`);
      } else {
        $$renderer2.push("<!--[-1-->");
        $$renderer2.push(`<p class="empty svelte-1ma5hcs">No open pull requests.</p>`);
      }
      $$renderer2.push(`<!--]--></section>`);
    } else {
      $$renderer2.push("<!--[-1-->");
      $$renderer2.push(`<section class="disconnected svelte-1ma5hcs"><p>To connect GitHub, make sure:</p> <ol class="svelte-1ma5hcs"><li>This repo has a git remote (<code class="font-mono svelte-1ma5hcs">git remote add origin ...</code>)</li> <li>GitHub CLI is installed and authenticated (<code class="font-mono svelte-1ma5hcs">gh auth login</code>)</li></ol></section>`);
    }
    $$renderer2.push(`<!--]--></div>`);
  });
}
export {
  _page as default
};
