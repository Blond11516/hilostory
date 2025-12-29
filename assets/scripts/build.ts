import { $ } from "bun";
import esbuild, { type BuildOptions } from "esbuild";

const args = process.argv.slice(2);
const watch = args.includes("--watch");
const deploy = args.includes("--deploy");

const MIX_ENV = process.env.MIX_ENV ?? "dev";
const mixBuildPath = `../_build/${MIX_ENV}`;

const release = (
	MIX_ENV === "prod"
		? await Bun.file("../priv/release.txt").text()
		: await $`git rev-parse HEAD`.text()
).trim();

const loader: BuildOptions["loader"] = {
	// Add loaders for images/fonts/etc, e.g. { '.svg': 'file' }
};

const plugins: BuildOptions["plugins"] = [
	// Add and configure plugins here
];

// Define esbuild options
let opts: BuildOptions = {
	entryPoints: ["ts/app.ts"],
	bundle: true,
	logLevel: "debug",
	target: "es2022",
	outdir: "../priv/static/assets",
	external: ["fonts/*", "images/*"],
	alias: { "@": "." },
	sourcemap: true,
	define: { "process.env.HILOSTORY_RELEASE": `'${release}'` },
	nodePaths: ["../deps", mixBuildPath],
	tsconfig: "./ts/tsconfig.json",
	loader: loader,
	plugins: plugins,
};

if (deploy) {
	opts = {
		...opts,
		minify: true,
	};
}

if (watch) {
	const context = await esbuild.context(opts);
	setTimeout(async () => {
		try {
			for await (const _ of Bun.stdin.stream()) {
				// noop, wait for stdin to close
			}
		} catch (e) {
			console.error(e);
		} finally {
			await context.dispose();
		}
	});

	console.log("Starting esbuild in watch mode");
	context.watch();
} else {
	esbuild.build(opts);
}
