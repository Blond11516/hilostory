defmodule Hilostory.Infrastructure.DeviceValueRepository do
  @moduledoc false
  import Ecto.Query, only: [from: 2]

  alias Ecto.Changeset
  alias Hilostory.DeviceValue.Power
  alias Hilostory.DeviceValue.TargetTemperature
  alias Hilostory.DeviceValue.Temperature
  alias Hilostory.Repo
  alias Hilostory.Schema.PowerSchema
  alias Hilostory.Schema.TargetTemperatureSchema
  alias Hilostory.Schema.TemperatureSchema

  @typep value_module ::
           Temperature
           | TargetTemperature
           | Power

  def insert(value, device_id)
      when is_integer(device_id) and
             (is_struct(value, Temperature) or is_struct(value, TargetTemperature) or is_struct(value, Power)) do
    {schema, value_field_name, inner_value} =
      case value do
        %Temperature{} ->
          {%TemperatureSchema{}, :temperature, value.temperature}

        %TargetTemperature{} ->
          {%TargetTemperatureSchema{}, :target_temperature, value.target_temperature}

        %Power{} ->
          {%PowerSchema{}, :power, value.power}
      end

    schema
    |> Changeset.cast(%{value_field_name => inner_value}, [value_field_name])
    |> Changeset.cast(%{timestamp: value.timestamp, device_id: device_id}, [
      :timestamp,
      :device_id
    ])
    |> Repo.insert(
      on_conflict: [set: [{value_field_name, inner_value}]],
      conflict_target: :timestamp
    )
  end

  @spec fetch(value_module(), integer(), {DateTime.t(), Datetime.t()}) :: struct()
  def fetch(value, device_id, period) when value in [Temperature, TargetTemperature, Power] do
    value_schema =
      case value do
        ConnectionState -> ConnectionStateSchema
        PairingState -> PairingStateSchema
        Temperature -> TemperatureSchema
        TargetTemperature -> TargetTemperatureSchema
        Heating -> HeatingSchema
        Power -> PowerSchema
        GdState -> GdStateSchema
        DrmsState -> DrmsStateSchema
      end

    {period_start, period_end} = period

    from(v in value_schema,
      where:
        v.device_id == ^device_id and
          v.timestamp > ^period_start and
          v.timestamp < ^period_end,
      select: v
    )
    |> Repo.all()
    |> Enum.map(fn
      %TemperatureSchema{} = value ->
        %Temperature{timestamp: value.timestamp, temperature: value.temperature}

      %TargetTemperatureSchema{} = value ->
        %TargetTemperature{
          timestamp: value.timestamp,
          target_temperature: value.target_temperature
        }

      %PowerSchema{} = value ->
        %Power{timestamp: value.timestamp, power: value.power}
    end)
  end
end
