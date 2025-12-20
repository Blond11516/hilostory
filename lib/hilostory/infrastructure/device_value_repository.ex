defmodule Hilostory.Infrastructure.DeviceValueRepository do
  @moduledoc false
  import Ecto.Query, only: [from: 2]

  alias Ecto.Changeset
  alias Hilostory.DeviceValue.Reading
  alias Hilostory.Repo
  alias Hilostory.Schema.DeviceValueSchema

  def insert(%Reading{} = reading, device_id) when is_binary(device_id) do
    DeviceValueSchema
    |> Changeset.cast(
      %{value: reading.value.value, timestamp: reading.timestamp, device_id: device_id, kind: reading.value.kind},
      [
        :value,
        :timestamp,
        :device_id,
        :kind
      ]
    )
    |> Repo.insert(
      on_conflict: [set: [{:value, reading.value.value}, {:kind, reading.value.kind}]],
      conflict_target: [:timestamp, :value_name, :device]
    )
  end

  @spec fetch(:ambient_temperature | :ambient_temperature_setpoint | :power, String.t(), {DateTime.t(), Datetime.t()}) ::
          struct()
  def fetch(value, device_id, period) when value in [Temperature, TargetTemperature, Power] do
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
