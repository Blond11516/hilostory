import type LiveSocket from "phoenix_live_view";

declare global {
	interface Window {
		// biome-ignore lint/suspicious/noExplicitAny: Don't have a type definition for Phoenix's reloader
		liveReloader: any;
		liveSocket: LiveSocket;
	}
}
