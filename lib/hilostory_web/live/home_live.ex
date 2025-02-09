defmodule HilostoryWeb.HomeLive do
  alias Phoenix.LiveView.AsyncResult
  alias Hilostory.Infrastructure.DeviceRepository
  alias Hilostory.DeviceValue.TargetTemperature
  alias Hilostory.DeviceValue.Temperature
  alias Hilostory.DeviceValue.Power
  alias Hilostory.Infrastructure.DeviceValueRepository

  use HilostoryWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> start_async(:fetch_devices, &fetch_devices/0)
      |> assign(devices: AsyncResult.loading())
      |> assign(
        period:
          {DateTime.utc_now() |> DateTime.shift(Duration.new!(hour: -1)), DateTime.utc_now()}
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    device_data_loaded? =
      assigns.devices.ok? and
        Enum.all?(assigns.devices.result, fn device ->
          Map.has_key?(assigns, device.id |> Integer.to_string() |> String.to_existing_atom())
        end)

    assigns =
      if device_data_loaded? do
        assign(assigns,
          devices_data:
            Map.filter(assigns, fn {device_id, _} ->
              device_id |> Atom.to_string() |> Integer.parse() != :error
            end)
        )
      else
        assign(assigns, devices_data: nil)
      end

    ~H"""
    <span id="time-zone-hook-target" style="display: none;" phx-hook="PushTimeZone" />

    <form phx-submit="period-changed">
      <div>Select data period to display</div>
      <label for="datetime-start-input">From</label>
      <input
        type="datetime-local"
        id="datetime-start-input"
        name="start"
        value={format_date_time_for_input(elem(@period, 0))}
      />
      <label for="datetime-end-input">To</label>
      <input
        type="datetime-local"
        id="datetime-end-input"
        name="end"
        value={format_date_time_for_input(elem(@period, 1))}
      />
      <button type="submit">Apply</button>
    </form>

    <.async_result :let={devices} assign={@devices}>
      <:loading>Loading data</:loading>
      <:failed :let={error}>Failed to fetch data: {inspect(error)}</:failed>

      <button phx-click="refresh">Refresh</button>
      <div class="chart-grid">
        <div :for={device <- devices} id={"chart-#{device.name}"} phx-update="ignore" />
      </div>
    </.async_result>
    <div :if={@devices_data != nil}>
      <div :for={{_, device_data_result} <- @devices_data}>
        <.async_result :let={{device, device_data}} assign={device_data_result}>
          <:loading>Loading data</:loading>
          <:failed :let={error}>Failed to fetch data: {inspect(error)}</:failed>

          <div
            id={"chart-#{device.name}-data"}
            phx-hook="Chart"
            data-data={device_data}
            data-device-name={device.name}
          />
        </.async_result>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("refresh", _, socket) do
    {:noreply, refresh(socket)}
  end

  def handle_event("period-changed", params, socket) do
    period_start =
      params
      |> Map.fetch!("start")
      |> parse_date_time_input_value(socket.assigns.time_zone)

    period_end =
      params
      |> Map.fetch!("end")
      |> parse_date_time_input_value(socket.assigns.time_zone)

    socket =
      socket
      |> assign(period: {period_start, period_end})
      |> refresh()

    {:noreply, socket}
  end

  def handle_event("set-timezone", params, socket) do
    time_zone = params["time-zone"]
    {period_start, period_end} = socket.assigns.period

    socket =
      socket
      |> assign(
        period:
          {DateTime.shift_zone!(period_start, time_zone),
           DateTime.shift_zone!(period_end, time_zone)}
      )
      |> assign(time_zone: time_zone)

    {:noreply, socket}
  end

  @impl true
  def handle_async(:fetch_devices, result, socket) do
    case result do
      {:ok, devices} ->
        device_ids =
          Enum.map(devices, fn device -> device.id |> Integer.to_string() |> String.to_atom() end)

        period = socket.assigns.period

        socket =
          socket
          |> assign(devices: AsyncResult.ok(devices))
          |> assign_async(device_ids, fn -> fetch_data(devices, period) end)

        {:noreply, socket}

      {:exit, reason} ->
        {:noreply, assign(socket, devices: AsyncResult.ok(nil) |> AsyncResult.failed(reason))}
    end
  end

  defp parse_date_time_input_value(value, time_zone) do
    value
    |> then(&(&1 <> ":00"))
    |> NaiveDateTime.from_iso8601!()
    |> DateTime.from_naive!(time_zone)
  end

  defp refresh(socket) do
    devices = socket.assigns.devices.result

    device_ids =
      Enum.map(devices, fn device -> device.id |> Integer.to_string() |> String.to_atom() end)

    period = socket.assigns.period
    assign_async(socket, device_ids, fn -> fetch_data(devices, period) end)
  end

  defp format_date_time_for_input(%DateTime{} = date_time) do
    Calendar.strftime(date_time, "%Y-%m-%dT%H:%M")
  end

  defp fetch_devices() do
    DeviceRepository.all()
  end

  defp fetch_data(devices, period) do
    device_data =
      Map.new(devices, fn device ->
        {device.id |> Integer.to_string() |> String.to_existing_atom(),
         {device, fetch_device_data(device.id, period)}}
      end)

    {:ok, device_data}
  end

  defp fetch_device_data(device_id, period) do
    power_task =
      Task.async(fn ->
        DeviceValueRepository.fetch(Power, device_id, period)
        |> Map.new(fn %Power{} = value -> {DateTime.to_unix(value.timestamp), value.power} end)
      end)

    temperature_task =
      Task.async(fn ->
        DeviceValueRepository.fetch(Temperature, device_id, period)
        |> Map.new(fn %Temperature{} = value ->
          {DateTime.to_unix(value.timestamp), value.temperature}
        end)
      end)

    target_temperature_task =
      Task.async(fn ->
        DeviceValueRepository.fetch(TargetTemperature, device_id, period)
        |> Map.new(fn %TargetTemperature{} = value ->
          {DateTime.to_unix(value.timestamp), value.target_temperature}
        end)
      end)

    [power_values, temperature_values, target_temperature_values] =
      Task.await_many([power_task, temperature_task, target_temperature_task])

    power_timestamps =
      power_values |> MapSet.new(fn {timestamp, _} -> timestamp end)

    temperature_timestamps =
      temperature_values |> MapSet.new(fn {timestamp, _} -> timestamp end)

    target_temperature_timestamps =
      target_temperature_values
      |> MapSet.new(fn {timestamp, _} -> timestamp end)

    all_timestamps =
      power_timestamps
      |> MapSet.union(temperature_timestamps)
      |> MapSet.union(target_temperature_timestamps)

    all_timestamps
    |> Map.new(fn timestamp ->
      {timestamp,
       %{
         "power" => power_values[timestamp],
         "temperature" => temperature_values[timestamp],
         "targetTemperature" => target_temperature_values[timestamp]
       }}
    end)
    |> JSON.encode!()
  end
end
