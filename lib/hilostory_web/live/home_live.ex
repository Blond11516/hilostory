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
    devices = socket.assigns.devices.result

    device_ids =
      Enum.map(devices, fn device -> device.id |> Integer.to_string() |> String.to_atom() end)

    {:noreply, assign_async(socket, device_ids, fn -> fetch_data(devices) end)}
  end

  @impl true
  def handle_async(:fetch_devices, result, socket) do
    case result do
      {:ok, devices} ->
        device_ids =
          Enum.map(devices, fn device -> device.id |> Integer.to_string() |> String.to_atom() end)

        socket =
          socket
          |> assign(devices: AsyncResult.ok(devices))
          |> assign_async(device_ids, fn -> fetch_data(devices) end)

        {:noreply, socket}

      {:exit, reason} ->
        {:noreply, assign(socket, devices: AsyncResult.ok(nil) |> AsyncResult.failed(reason))}
    end
  end

  defp fetch_devices() do
    DeviceRepository.all()
  end

  defp fetch_data(devices) do
    device_data =
      Map.new(devices, fn device ->
        {device.id |> Integer.to_string() |> String.to_existing_atom(),
         {device, fetch_device_data(device.id)}}
      end)

    {:ok, device_data}
  end

  defp fetch_device_data(device_id) do
    power_task =
      Task.async(fn ->
        DeviceValueRepository.fetch(Power, device_id)
        |> Map.new(fn %Power{} = value -> {DateTime.to_unix(value.timestamp), value.power} end)
      end)

    temperature_task =
      Task.async(fn ->
        DeviceValueRepository.fetch(Temperature, device_id)
        |> Map.new(fn %Temperature{} = value ->
          {DateTime.to_unix(value.timestamp), value.temperature}
        end)
      end)

    target_temperature_task =
      Task.async(fn ->
        DeviceValueRepository.fetch(TargetTemperature, device_id)
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
