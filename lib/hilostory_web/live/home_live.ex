defmodule HilostoryWeb.HomeLive do
  alias Hilostory.DeviceValue.TargetTemperature
  alias Hilostory.DeviceValue.Temperature
  alias Hilostory.DeviceValue.Power
  alias Hilostory.Infrastructure.DeviceValueRepository
  use HilostoryWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign_async(socket, :data, &fetch_data/0)
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.async_result :let={data} assign={@data}>
      <:loading>Loading data</:loading>
      <:failed :let={error}>Failed to fetch data: {inspect(error)}</:failed>
      <div id="chart" phx-hook="Chart" data-data={data} />
    </.async_result>
    """
  end

  defp fetch_data() do
    power_task =
      Task.async(fn ->
        DeviceValueRepository.fetch(Power)
        |> Map.new(fn %Power{} = value -> {DateTime.to_unix(value.timestamp), value.power} end)
      end)

    temperature_task =
      Task.async(fn ->
        DeviceValueRepository.fetch(Temperature)
        |> Map.new(fn %Temperature{} = value ->
          {DateTime.to_unix(value.timestamp), value.temperature}
        end)
      end)

    target_temperature_task =
      Task.async(fn ->
        DeviceValueRepository.fetch(TargetTemperature)
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

    data =
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

    {:ok, %{data: data}}
  end
end
