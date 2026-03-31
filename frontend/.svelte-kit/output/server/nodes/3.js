import * as server from '../entries/pages/files/_page.server.ts.js';

export const index = 3;
let component_cache;
export const component = async () => component_cache ??= (await import('../entries/pages/files/_page.svelte.js')).default;
export { server };
export const server_id = "src/routes/files/+page.server.ts";
export const imports = ["_app/immutable/nodes/3.snJ81aX3.js","_app/immutable/chunks/BPazckB7.js","_app/immutable/chunks/CnnHHd9u.js","_app/immutable/chunks/_4VItRTv.js","_app/immutable/chunks/CEZ1KQol.js","_app/immutable/chunks/DMwI42Na.js","_app/immutable/chunks/CkLfrO85.js"];
export const stylesheets = ["_app/immutable/assets/3.eQ8HaqgC.css"];
export const fonts = [];
