import * as server from '../entries/pages/github/_page.server.ts.js';

export const index = 4;
let component_cache;
export const component = async () => component_cache ??= (await import('../entries/pages/github/_page.svelte.js')).default;
export { server };
export const server_id = "src/routes/github/+page.server.ts";
export const imports = ["_app/immutable/nodes/4.aISIIRAy.js","_app/immutable/chunks/BPazckB7.js","_app/immutable/chunks/CnnHHd9u.js","_app/immutable/chunks/_4VItRTv.js","_app/immutable/chunks/CEZ1KQol.js","_app/immutable/chunks/DMwI42Na.js"];
export const stylesheets = ["_app/immutable/assets/4.D2qIuICl.css"];
export const fonts = [];
