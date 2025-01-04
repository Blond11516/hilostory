// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "topbar"
import uPlot from "uplot"

// Import app.css so it is bundled by esbuild
import "../css/app.css"
import "uplot/dist/uPlot.min.css"

type DeviceDataPoint = {
  power: number | null
  temperature: number | null
  targetTemperature: number | null
}

type DeviceData = Record<number, DeviceDataPoint>

const sync = uPlot.sync("chartsSync")
const charts: Record<string, uPlot> = {}

let csrfToken = document.querySelector("meta[name='csrf-token']")!.getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {
    Chart: {
      mounted() {
        const deviceName = this.el.getAttribute("data-device-name")
        const powerData = JSON.parse(this.el.getAttribute("data-data")) as DeviceData
        const sortedPowerData = Object.entries(powerData).toSorted((a, b) => Number.parseInt(a[0]) - Number.parseInt(b[0]))
        const timestamps = sortedPowerData.map(it => Number.parseInt(it[0]))
        const powers = sortedPowerData.map(it => it[1].power)
        const temperatures = sortedPowerData.map(it => it[1].temperature)
        const targetTemperatures = sortedPowerData.map(it => it[1].targetTemperature)
        const data: [number[], ...(number | null)[][]] = [
          timestamps,
          powers,
          temperatures,
          targetTemperatures
        ];
        const opts: uPlot.Options = {
          title: deviceName,
          width: this.el.offsetWidth,
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
        
        const plot = new uPlot(opts, data, this.el);
        charts[deviceName] = plot
        sync.sub(plot)
        console.log(sync)
      },
      destroyed() {
        const deviceName = this.el.getAttribute("data-device-name")
        const plot = charts[deviceName]

        if (plot) {
          sync.unsub(plot)
          delete charts[deviceName]
        }
      },
    }
  }
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

