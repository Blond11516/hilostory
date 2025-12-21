defmodule Hilostory.Infrastructure.DeviceValueRepository do
  @moduledoc false
  import Ecto.Query, only: [from: 2]

  alias Hilostory.DeviceValue.Reading
  alias Hilostory.Repo
  alias Hilostory.Schema.DeviceValueSchema

  def upsert(%Reading{} = reading, device_id), do: upsert([reading], device_id)

  def upsert(readings, device_id) when is_list(readings) and is_binary(device_id) do
    entries =
      Enum.map(readings, fn %Reading{} = reading ->
        %{
          # Ensure the timestamp has microsecond precision
          timestamp: DateTime.add(reading.timestamp, 0, :microsecond),
          value_name: reading.value.type,
          device_id: device_id,
          value: reading.value.value,
          kind: reading.value.kind
        }
      end)

    Repo.insert_all(
      DeviceValueSchema,
      entries,
      on_conflict: {:replace, [:value, :kind]},
      conflict_target: [:timestamp, :value_name, :device_id]
    )
  end

  @spec fetch(:ambient_temperature | :ambient_temperature_setpoint | :power, String.t(), {DateTime.t(), Datetime.t()}) ::
          struct()
  def fetch(value, device_id, period) when value in [:ambient_temperature, :ambient_temperature_setpoint, :power] do
    {period_start, period_end} = period

    from(v in DeviceValueSchema,
      where:
        v.device_id == ^device_id and
          v.timestamp > ^period_start and
          v.timestamp < ^period_end,
      select: v
    )
    |> Repo.all()
    |> Enum.map(&DeviceValueSchema.to_reading/1)
  end
end
