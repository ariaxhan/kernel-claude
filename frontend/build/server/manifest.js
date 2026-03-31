const manifest = (() => {
function __memo(fn) {
	let value;
	return () => value ??= (value = fn());
}

return {
	appDir: "_app",
	appPath: "_app",
	assets: new Set(["robots.txt"]),
	mimeTypes: {".txt":"text/plain"},
	_: {
		client: {start:"_app/immutable/entry/start.FS8tERO0.js",app:"_app/immutable/entry/app.RliNyeSf.js",imports:["_app/immutable/entry/start.FS8tERO0.js","_app/immutable/chunks/CtwRszvE.js","_app/immutable/chunks/CnnHHd9u.js","_app/immutable/chunks/B1CypB9Z.js","_app/immutable/entry/app.RliNyeSf.js","_app/immutable/chunks/CnnHHd9u.js","_app/immutable/chunks/BPazckB7.js","_app/immutable/chunks/B1CypB9Z.js","_app/immutable/chunks/_4VItRTv.js","_app/immutable/chunks/CEZ1KQol.js"],stylesheets:[],fonts:[],uses_env_dynamic_public:false},
		nodes: [
			__memo(() => import('./chunks/0-Dekyc8Gd.js')),
			__memo(() => import('./chunks/1-I5_JCwb5.js')),
			__memo(() => import('./chunks/2-C-AlbTBi.js')),
			__memo(() => import('./chunks/3-d92UH3ab.js')),
			__memo(() => import('./chunks/4-CwGkauH1.js')),
			__memo(() => import('./chunks/5-BDKQopZ8.js')),
			__memo(() => import('./chunks/6-CvorrEa8.js'))
		],
		remotes: {
			
		},
		routes: [
			{
				id: "/",
				pattern: /^\/$/,
				params: [],
				page: { layouts: [0,], errors: [1,], leaf: 2 },
				endpoint: null
			},
			{
				id: "/files",
				pattern: /^\/files\/?$/,
				params: [],
				page: { layouts: [0,], errors: [1,], leaf: 3 },
				endpoint: null
			},
			{
				id: "/github",
				pattern: /^\/github\/?$/,
				params: [],
				page: { layouts: [0,], errors: [1,], leaf: 4 },
				endpoint: null
			},
			{
				id: "/help",
				pattern: /^\/help\/?$/,
				params: [],
				page: { layouts: [0,], errors: [1,], leaf: 5 },
				endpoint: null
			},
			{
				id: "/memory",
				pattern: /^\/memory\/?$/,
				params: [],
				page: { layouts: [0,], errors: [1,], leaf: 6 },
				endpoint: null
			}
		],
		prerendered_routes: new Set([]),
		matchers: async () => {
			
			return {  };
		},
		server_assets: {}
	}
}
})();

const prerendered = new Set([]);

const base = "";

export { base, manifest, prerendered };
//# sourceMappingURL=manifest.js.map
