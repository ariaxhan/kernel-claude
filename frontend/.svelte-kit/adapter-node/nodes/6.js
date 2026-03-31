import * as server from '../entries/pages/memory/_page.server.ts.js';

export const index = 6;
let component_cache;
export const component = async () => component_cache ??= (await import('../entries/pages/memory/_page.svelte.js')).default;
export { server };
export const server_id = "src/routes/memory/+page.server.ts";
export const imports = ["_app/immutable/nodes/6.BNXnv58V.js","_app/immutable/chunks/BPazckB7.js","_app/immutable/chunks/CnnHHd9u.js","_app/immutable/chunks/_4VItRTv.js","_app/immutable/chunks/CEZ1KQol.js","_app/immutable/chunks/DMwI42Na.js","_app/immutable/chunks/BfcSgKlm.js","_app/immutable/chunks/CMsK9DGT.js","_app/immutable/chunks/CkLfrO85.js"];
export const stylesheets = ["_app/immutable/assets/6.DtN_KqsA.css"];
export const fonts = [];
