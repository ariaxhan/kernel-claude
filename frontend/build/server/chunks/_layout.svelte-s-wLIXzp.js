import { h as head, c as ensure_array_like, d as attr, f as attr_class, j as escape_html } from './index-CRCf3C_i.js';
import { p as page } from './index2-1Y3qGKzj.js';
import './exports-Dvcjkzxc.js';

function NavButtons($$renderer, $$props) {
  $$renderer.component(($$renderer2) => {
    const tabs = [
      { href: "/", label: "Status" },
      { href: "/memory", label: "Memory" },
      { href: "/files", label: "Files" },
      { href: "/github", label: "GitHub" }
    ];
    function isActive(href) {
      if (href === "/") return page.url.pathname === "/";
      return page.url.pathname.startsWith(href);
    }
    $$renderer2.push(`<nav class="nav-buttons svelte-1429x72"><div class="nav-left svelte-1429x72"><a href="/" class="brand font-serif svelte-1429x72">the interface</a></div> <div class="nav-center svelte-1429x72"><!--[-->`);
    const each_array = ensure_array_like(tabs);
    for (let $$index = 0, $$length = each_array.length; $$index < $$length; $$index++) {
      let tab = each_array[$$index];
      $$renderer2.push(`<a${attr("href", tab.href)}${attr_class("nav-btn svelte-1429x72", void 0, { "active": isActive(tab.href) })}>${escape_html(tab.label)}</a>`);
    }
    $$renderer2.push(`<!--]--></div> <div class="nav-right svelte-1429x72"><a href="/help"${attr_class("nav-btn help-btn svelte-1429x72", void 0, { "active": isActive("/help") })}>Help</a></div></nav>`);
  });
}
function _layout($$renderer, $$props) {
  let { children } = $$props;
  head("12qhfyh", $$renderer, ($$renderer2) => {
    $$renderer2.title(($$renderer3) => {
      $$renderer3.push(`<title>the interface — KERNEL</title>`);
    });
  });
  $$renderer.push(`<div class="shell svelte-12qhfyh">`);
  NavButtons($$renderer);
  $$renderer.push(`<!----> <main class="content svelte-12qhfyh">`);
  children($$renderer);
  $$renderer.push(`<!----></main></div>`);
}

export { _layout as default };
//# sourceMappingURL=_layout.svelte-s-wLIXzp.js.map
