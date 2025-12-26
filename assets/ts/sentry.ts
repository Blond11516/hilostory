import { init } from "@sentry/browser";

export function initializeSentry() {
	if (process.env.NODE_ENV === "development") {
		return;
	}

	init({
		dsn: "https://28ab0dcd5287abc06761cd09c991d99c@o4508864739082240.ingest.us.sentry.io/4508864739344384",
	});
}
