defmodule HilostoryWeb.HomeLive do
  alias Phoenix.LiveView.AsyncResult
  alias Hilostory.Infrastructure.DeviceRepository
  alias Hilostory.DeviceValue.TargetTemperature
  alias Hilostory.DeviceValue.Temperature
  alias Hilostory.DeviceValue.Power
  alias Hilostory.Infrastructure.DeviceValueRepository

  use HilostoryWeb, :live_view

  @type predefined_period :: :last_hour | :last_day | :last_am_challenge | :last_pm_challenge
  @type period :: {:predefined, predefined_period()} | {:custom, {DateTime.t(), DateTime.t()}}

  @predefined_periods [:last_hour, :last_day, :last_am_challenge, :last_pm_challenge]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(devices: AsyncResult.loading())
      |> assign(period: {:predefined, :last_hour})
      |> assign(pending_custom_period?: false)

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

    assigns =
      assign(assigns,
        predefined_periods: @predefined_periods,
        time_zone: Map.get(assigns, :time_zone, nil)
      )

    ~H"""
    <span id="time-zone-hook-target" style="display: none;" phx-hook="PushTimeZone" />

    <form phx-submit="period-submitted" phx-change="period-changed">
      <div>Select data period to display</div>
      <label for="period-type-input">Period</label>
      <select id="period-type-input" name="period-type" value={format_period_option_value(@period)}>
        <option :for={period <- @predefined_periods} value={format_period_option_value(period)}>
          {format_predefined_period_option_display_name(period)}
        </option>
        <option value="custom">Custom</option>
      </select>
      <label for="datetime-start-input">From</label>
      <!-- TODO for predefined periods, should store the last fetched period to avoid the displayed period changing on unrelated updates -->
      <input
        type="datetime-local"
        id="datetime-start-input"
        name="start"
        disabled={not match?({:custom, _}, @period) and not @pending_custom_period?}
        value={format_date_time_for_input(@period, :start, @time_zone)}
      />
      <label for="datetime-end-input">To</label>
      <input
        type="datetime-local"
        id="datetime-end-input"
        name="end"
        disabled={not match?({:custom, _}, @period) and not @pending_custom_period?}
        value={format_date_time_for_input(@period, :end, @time_zone)}
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

  def handle_event("period-submitted", params, socket) do
    period = parse_updated_period(params, socket.assigns.time_zone)

    socket =
      socket
      |> assign(period: period)
      |> assign(pending_custom_period?: false)
      |> refresh()

    {:noreply, socket}
  end

  def handle_event("period-changed", params, socket) do
    {:noreply, assign(socket, pending_custom_period?: params["period-type"] == "custom")}
  end

  def handle_event("set-timezone", params, socket) do
    time_zone = params["time-zone"]

    period =
      case socket.assigns.period do
        {:custom, _} -> {:custom, get_current_period(socket.assigns.period, time_zone)}
        period -> period
      end

    socket =
      socket
      |> assign(period: period)
      |> assign(time_zone: time_zone)
      |> start_async(:fetch_devices, &fetch_devices/0)

    {:noreply, socket}
  end

  @impl true
  def handle_async(:fetch_devices, result, socket) do
    case result do
      {:ok, devices} ->
        device_ids =
          Enum.map(devices, fn device -> device.id |> Integer.to_string() |> String.to_atom() end)

        period = get_current_period(socket.assigns.period, socket.assigns.time_zone)

        socket =
          socket
          |> assign(devices: AsyncResult.ok(devices))
          |> assign_async(device_ids, fn -> fetch_data(devices, period) end)

        {:noreply, socket}

      {:exit, reason} ->
        {:noreply, assign(socket, devices: AsyncResult.ok(nil) |> AsyncResult.failed(reason))}
    end
  end

  @spec format_period_option_value(period()) :: String.t()
  defp format_period_option_value({:custom, _}), do: "custom"
  defp format_period_option_value({:predefined, period}), do: format_period_option_value(period)

  defp format_period_option_value(period) when period in @predefined_periods,
    do: Atom.to_string(period)

  @spec format_predefined_period_option_display_name(predefined_period()) :: String.t()
  defp format_predefined_period_option_display_name(:last_hour), do: "Last hour"
  defp format_predefined_period_option_display_name(:last_day), do: "Last day"
  defp format_predefined_period_option_display_name(:last_am_challenge), do: "Last AM challenge"
  defp format_predefined_period_option_display_name(:last_pm_challenge), do: "Last PM challenge"

  @spec get_current_period(period(), Calendar.time_zone()) :: {DateTime.t(), DateTime.t()}
  defp get_current_period({:custom, {period_start, period_end}}, time_zone),
    do:
      {DateTime.shift_zone!(period_start, time_zone), DateTime.shift_zone!(period_end, time_zone)}

  defp get_current_period({:predefined, :last_hour}, _time_zone),
    do: {DateTime.utc_now() |> DateTime.shift(Duration.new!(hour: -1)), DateTime.utc_now()}

  defp get_current_period({:predefined, :last_day}, _time_zone),
    do: {DateTime.utc_now() |> DateTime.shift(Duration.new!(hour: -24)), DateTime.utc_now()}

  defp get_current_period({:predefined, :last_am_challenge}, time_zone) do
    get_challenge_period({Time.new!(4, 0, 0), Time.new!(11, 0, 0)}, time_zone)
  end

  defp get_current_period({:predefined, :last_pm_challenge}, time_zone) do
    get_challenge_period({Time.new!(15, 0, 0), Time.new!(22, 0, 0)}, time_zone)
  end

  defp get_challenge_period(challenge_time_period, time_zone) do
    {challenge_start, challenge_end} = challenge_time_period |> IO.inspect(label: "challenge_time_period")
    time_now = DateTime.now!(time_zone) |> DateTime.to_time() |> IO.inspect(label: "time now")

    today = DateTime.utc_now() |> DateTime.shift_zone!(time_zone) |> DateTime.to_date() |> IO.inspect(label: "today")

    challenge_day =
      if Time.compare(time_now, challenge_start) == :lt do
        Date.shift(today, Duration.new!(day: -1))
      else
        today
      end
      |> IO.inspect(label: "challenge day")

    period_start = DateTime.new!(challenge_day, challenge_start, time_zone)
    period_end = DateTime.new!(challenge_day, challenge_end, time_zone)

    {period_start, period_end} |> IO.inspect(label: "challenge period")
  end

  @spec parse_updated_period(%{String.t() => String.t()}, Calendar.time_zone()) :: period()
  defp parse_updated_period(params, time_zone) do
    case params["period-type"] do
      "custom" ->
        period_start =
          params
          |> Map.fetch!("start")
          |> parse_date_time_input_value(time_zone)

        period_end =
          params
          |> Map.fetch!("end")
          |> parse_date_time_input_value(time_zone)

        {:custom, {period_start, period_end}}

      type ->
        {:predefined, String.to_existing_atom(type)}
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

    period = get_current_period(socket.assigns.period, socket.assigns.time_zone)
    assign_async(socket, device_ids, fn -> fetch_data(devices, period) end)
  end

  @spec format_date_time_for_input(period(), :start | :end, Calendar.time_zone() | nil) ::
          String.t()
  defp format_date_time_for_input(_, _, nil), do: ""

  defp format_date_time_for_input(period, start_or_end, time_zone) do
    period
    |> get_current_period(time_zone)
    |> then(fn {period_start, period_end} ->
      case start_or_end do
        :start -> period_start
        :end -> period_end
      end
    end)
    |> DateTime.shift_zone!(time_zone)
    |> Calendar.strftime("%Y-%m-%dT%H:%M")
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
