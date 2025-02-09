import type { ViewHook } from "phoenix_live_view";

const PushTimeZone: ViewHook = {
	mounted() {
		const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
		this.pushEvent("set-timezone", {"time-zone": timeZone})
	}
}

export default PushTimeZone