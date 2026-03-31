import { c as escape_html } from "../../chunks/index.js";
import "clsx";
import { p as page } from "../../chunks/index2.js";
function Error($$renderer, $$props) {
  $$renderer.component(($$renderer2) => {
    $$renderer2.push(`<h1>${escape_html(page.status)}</h1> <p>${escape_html(page.error?.message)}</p>`);
  });
}
export {
  Error as default
};
