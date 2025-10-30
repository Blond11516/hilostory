import { ViewHook } from "phoenix_live_view";
import uPlot from "uplot";

type DeviceDataPoint = {
  power: number | null
  temperature: number | null
  targetTemperature: number | null
}

type DeviceData = Record<number, DeviceDataPoint>

const sync = uPlot.sync("chartsSync")

class Chart extends ViewHook {
  private chart?: uPlot
  
	override mounted() {
		const deviceName = this.el.getAttribute("data-device-name")!
		const chartContainer = document.getElementById("chart-" + deviceName)!
		const data = parseDeviceData(this.el)
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
					value: (self, rawValue) => rawValue !== null ? rawValue + " W" : '',
					stroke: "red",
					width: 1,
					scale: "watts"
				},
				{
					show: true,
					spanGaps: false,
					label: "Temperature",
					value: (self, rawValue) => rawValue !== null ? rawValue.toFixed(1) + " C" : '',
					stroke: "green",
					width: 1,
					scale: "degrees celcius"
				},
				{
					show: true,
					spanGaps: false,
					label: "Target temperature",
					value: (self, rawValue) => rawValue !== null ? rawValue.toFixed(1) + " C" : '',
					stroke: "blue",
					width: 1,
					scale: "degrees celcius"
				}
			],
			axes: [
				{},
				{
					scale: "watts",
					values: (self, ticks) => ticks.map(it => it + ' W')
				},
				{
					scale: 'degrees celcius',
					side: 1,
					grid: { show: false },
					values: (self, ticks) => ticks.map(it => it + ' C')
				}
			],
			cursor: {
				sync: {
					key: sync.key,
					setSeries: true,
				}
			}
		};
		
		const plot = new uPlot(opts, data, chartContainer);
		this.chart = plot
		sync.sub(plot)
	}
	
	override updated() {
		const data: [number[], ...(number | null)[][]] = parseDeviceData(this.el);

		if (this.chart) {
			this.chart.setData(data)
		}
	}
	
	override destroyed() {
		if (this.chart) {
			sync.unsub(this.chart)
		}
	}
}

export default Chart

function parseDeviceData(element: HTMLElement): [number[], ...(number | null)[][]] {
	const rawData = element.getAttribute('data-data')!;
	const parsedData = JSON.parse(rawData) as DeviceData;
	const sortedPowerData = [...Object.entries(parsedData)].sort((a, b) => Number.parseInt(a[0]) - Number.parseInt(b[0]));
	const timestamps = sortedPowerData.map(it => Number.parseInt(it[0]));
	const powers = sortedPowerData.map(it => it[1].power);
	const temperatures = sortedPowerData.map(it => it[1].temperature);
	const targetTemperatures = sortedPowerData.map(it => it[1].targetTemperature);
	return [
		timestamps,
		powers,
		temperatures,
		targetTemperatures
	];
}
