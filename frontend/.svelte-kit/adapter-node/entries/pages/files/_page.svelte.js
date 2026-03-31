import { e as ensure_array_like, a4 as attr_style, c as escape_html, a5 as stringify } from "../../../chunks/index.js";
function html(value) {
  var html2 = String(value ?? "");
  var open = "<!---->";
  return open + html2 + "<!---->";
}
function _page($$renderer, $$props) {
  $$renderer.component(($$renderer2) => {
    let { data } = $$props;
    let expandedPaths = /* @__PURE__ */ new Set(["_meta", "_meta/agentdb", "_meta/research"]);
    function fileIcon(node) {
      if (node.type === "directory") return expandedPaths.has(node.path) ? "&#9662;" : "&#9656;";
      const ext = node.name.split(".").pop();
      if (ext === "md") return "&#9636;";
      if (ext === "sh") return "&#9654;";
      if (ext === "json") return "&#123;";
      if (ext === "db") return "&#9673;";
      return "&#9643;";
    }
    function treeNode($$renderer3, node, depth) {
      if (node.type === "directory") {
        $$renderer3.push("<!--[0-->");
        $$renderer3.push(`<button class="tree-row dir svelte-5hf2uo"${attr_style(`padding-left: ${stringify(depth * 20 + 8)}px`)}><span class="tree-icon svelte-5hf2uo">${html(fileIcon(node))}</span> <span class="tree-name svelte-5hf2uo">${escape_html(node.name)}/</span> `);
        if (node.children) {
          $$renderer3.push("<!--[0-->");
          $$renderer3.push(`<span class="tree-count font-mono svelte-5hf2uo">${escape_html(node.children.length)}</span>`);
        } else {
          $$renderer3.push("<!--[-1-->");
        }
        $$renderer3.push(`<!--]--></button> `);
        if (expandedPaths.has(node.path) && node.children) {
          $$renderer3.push("<!--[0-->");
          $$renderer3.push(`<!--[-->`);
          const each_array = ensure_array_like(node.children);
          for (let $$index_2 = 0, $$length = each_array.length; $$index_2 < $$length; $$index_2++) {
            let child = each_array[$$index_2];
            treeNode($$renderer3, child, depth + 1);
          }
          $$renderer3.push(`<!--]-->`);
        } else {
          $$renderer3.push("<!--[-1-->");
        }
        $$renderer3.push(`<!--]-->`);
      } else {
        $$renderer3.push("<!--[-1-->");
        $$renderer3.push(`<div class="tree-row file svelte-5hf2uo"${attr_style(`padding-left: ${stringify(depth * 20 + 8)}px`)}><span class="tree-icon svelte-5hf2uo">${html(fileIcon(node))}</span> <span class="tree-name svelte-5hf2uo">${escape_html(node.name)}</span></div>`);
      }
      $$renderer3.push(`<!--]-->`);
    }
    $$renderer2.push(`<div class="page svelte-5hf2uo"><section class="header svelte-5hf2uo"><h1 class="font-serif svelte-5hf2uo">Files</h1> <p class="subtitle svelte-5hf2uo">Project structure and _meta artifacts.</p></section> <div class="trees svelte-5hf2uo"><section class="tree-section svelte-5hf2uo"><h2 class="tree-title font-serif svelte-5hf2uo">_meta/</h2> <p class="tree-desc svelte-5hf2uo">Session artifacts, AgentDB, research, handoffs.</p> <div class="tree svelte-5hf2uo"><!--[-->`);
    const each_array_1 = ensure_array_like(data.metaTree);
    for (let $$index = 0, $$length = each_array_1.length; $$index < $$length; $$index++) {
      let node = each_array_1[$$index];
      treeNode($$renderer2, node, 0);
    }
    $$renderer2.push(`<!--]--></div></section> <section class="tree-section svelte-5hf2uo"><h2 class="tree-title font-serif svelte-5hf2uo">Repo Structure</h2> <p class="tree-desc svelte-5hf2uo">Core KERNEL components.</p> <div class="tree svelte-5hf2uo"><!--[-->`);
    const each_array_2 = ensure_array_like(data.repoTree);
    for (let $$index_1 = 0, $$length = each_array_2.length; $$index_1 < $$length; $$index_1++) {
      let node = each_array_2[$$index_1];
      treeNode($$renderer2, node, 0);
    }
    $$renderer2.push(`<!--]--></div></section></div></div>`);
  });
}
export {
  _page as default
};
