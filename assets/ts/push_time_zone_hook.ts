import { ViewHook } from "phoenix_live_view";

class PushTimeZone extends ViewHook {
	override mounted(): void {
		this.pushTimezone();
	}

	override reconnected(): void {
		this.pushTimezone();
	}

	private pushTimezone() {
		const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
		this.pushEvent("set-default-timezone", { "time-zone": timeZone });
	}
}

export default PushTimeZone;
