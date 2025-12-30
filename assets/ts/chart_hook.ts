import { ViewHook } from "phoenix_live_view";
import uPlot from "uplot";

type DeviceDataPoint = {
	power: number | null;
	temperature: number | null;
	targetTemperature: number | null;
};

type DeviceData = Record<number, DeviceDataPoint>;

const sync = uPlot.sync("chartsSync");

class Chart extends ViewHook {
	private chart?: uPlot;
	private resizeObserver?: ResizeObserver;

	override mounted() {
		// biome-ignore lint/style/noNonNullAssertion: Hook is only used once on elements known to have this attribute
		const deviceName = this.el.getAttribute("data-device-name")!;
		// biome-ignore lint/style/noNonNullAssertion: App is known to have this element
		const chartContainer = document.getElementById(`chart-${deviceName}`)!;
		const data = parseDeviceData(this.el);
		const opts: uPlot.Options = {
			title: deviceName,
			width: chartContainer.offsetWidth,
			height: 400,
			series: [
				{},
				{
					show: true,
					spanGaps: false,
					label: "Power",
					value: (_self, rawValue) =>
						rawValue !== null ? `${rawValue} W` : "",
					stroke: "red",
					width: 1,
					scale: "watts",
				},
				{
					show: true,
					spanGaps: false,
					label: "Temperature",
					value: (_self, rawValue) =>
						rawValue !== null ? `${rawValue.toFixed(1)} C` : "",
					stroke: "green",
					width: 1,
					scale: "degrees celcius",
				},
				{
					show: true,
					spanGaps: false,
					label: "Target temperature",
					value: (_self, rawValue) =>
						rawValue !== null ? `${rawValue.toFixed(1)} C` : "",
					stroke: "blue",
					width: 1,
					scale: "degrees celcius",
				},
			],
			axes: [
				{},
				{
					scale: "watts",
					values: (_self, ticks) => ticks.map((it) => `${it} W`),
					size: 60,
				},
				{
					scale: "degrees celcius",
					side: 1,
					grid: { show: false },
					values: (_self, ticks) => ticks.map((it) => `${it} C`),
				},
			],
			scales: {
				x: {
					range: () => {
						const { startDate, endDate } = this.parseDates();

						return [
							this.dateToEpochSeconds(startDate),
							this.dateToEpochSeconds(endDate),
						];
					},
				},
			},
			cursor: {
				sync: {
					key: sync.key,
					setSeries: true,
				},
			},
		};

		const plot = new uPlot(opts, data, chartContainer);
		this.chart = plot;
		sync.sub(plot);

		this.resizeObserver = new ResizeObserver(this.handleResize.bind(this));
		this.resizeObserver.observe(chartContainer);
	}

	override updated() {
		const data: [number[], ...(number | null)[][]] = parseDeviceData(this.el);

		if (this.chart) {
			this.chart.setData(data);
		}
	}

	override destroyed() {
		if (this.chart) {
			sync.unsub(this.chart);
		}
		if (this.resizeObserver) {
			this.resizeObserver.disconnect();
		}
	}

	private handleResize(
		entries: ResizeObserverEntry[],
		_observer: ResizeObserver,
	) {
		if (this.chart === undefined) {
			return;
		}

		if (entries.length !== 1) {
			console.error("Received a resize event with number of entries != 1");
		}

		// biome-ignore lint/style/noNonNullAssertion: Length was asserted just before
		const entry = entries[0]!;
		this.chart.setSize({
			width: entry.contentRect.width,
			height: this.chart.height,
		});
	}

	private parseDates() {
		const startDate = new Date(
			// biome-ignore lint/style/noNonNullAssertion: Element is known to have this data attribute
			Number.parseInt(this.el.dataset.startDate!, 10) * 1000,
		);
		const endDate = new Date(
			// biome-ignore lint/style/noNonNullAssertion: Element is known to have this data attribute
			Number.parseInt(this.el.dataset.endDate!, 10) * 1000,
		);

		return { startDate, endDate };
	}

	private dateToEpochSeconds(date: Date): number {
		return date.valueOf() / 1000;
	}
}

export default Chart;

function parseDeviceData(
	element: HTMLElement,
): [number[], ...(number | null)[][]] {
	// biome-ignore lint/style/noNonNullAssertion: Hook is only used once on elements know to have this attribute
	const rawData = element.getAttribute("data-data")!;
	const parsedData = JSON.parse(rawData) as DeviceData;
	const sortedPowerData = [...Object.entries(parsedData)].sort(
		(a, b) => Number.parseInt(a[0], 10) - Number.parseInt(b[0], 10),
	);
	const timestamps = sortedPowerData.map((it) => Number.parseInt(it[0], 10));
	const powers = sortedPowerData.map((it) => it[1].power);
	const temperatures = sortedPowerData.map((it) => it[1].temperature);
	const targetTemperatures = sortedPowerData.map(
		(it) => it[1].targetTemperature,
	);
	return [timestamps, powers, temperatures, targetTemperatures];
}
