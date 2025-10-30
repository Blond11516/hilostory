import { ViewHook } from "phoenix_live_view";

class PushTimeZone extends ViewHook {
	override mounted() {
		const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
		this.pushEvent("set-timezone", { "time-zone": timeZone });
	}
}

export default PushTimeZone;
