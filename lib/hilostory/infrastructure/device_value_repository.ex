defmodule Hilostory.Infrastructure.DeviceValueRepository do
  @moduledoc false
  import Ecto.Query, only: [from: 2]

  alias Ecto.Changeset
  alias Hilostory.DeviceValue.ConnectionState
  alias Hilostory.DeviceValue.DrmsState
  alias Hilostory.DeviceValue.GdState
  alias Hilostory.DeviceValue.Heating
  alias Hilostory.DeviceValue.PairingState
  alias Hilostory.DeviceValue.Power
  alias Hilostory.DeviceValue.TargetTemperature
  alias Hilostory.DeviceValue.Temperature
  alias Hilostory.Repo
  alias Hilostory.Schema.ConnectionStateSchema
  alias Hilostory.Schema.DrmsStateSchema
  alias Hilostory.Schema.GdStateSchema
  alias Hilostory.Schema.HeatingSchema
  alias Hilostory.Schema.PairingStateSchema
  alias Hilostory.Schema.PowerSchema
  alias Hilostory.Schema.TargetTemperatureSchema
  alias Hilostory.Schema.TemperatureSchema

  @typep value_module ::
           ConnectionState
           | PairingState
           | Temperature
           | TargetTemperature
           | Heating
           | Power
           | GdState
           | DrmsState

  def insert(value, device_id)
      when is_integer(device_id) and
             (is_struct(value, ConnectionState) or is_struct(value, PairingState) or is_struct(value, Temperature) or
                is_struct(value, TargetTemperature) or is_struct(value, Heating) or is_struct(value, Power) or
                is_struct(value, GdState) or is_struct(value, DrmsState)) do
    {schema, params, permitted} =
      case value do
        %ConnectionState{} ->
          {%ConnectionStateSchema{}, %{connected: value.connected?}, [:connected]}

        %PairingState{} ->
          {%PairingStateSchema{}, %{paired: value.paired?}, [:paired]}

        %Temperature{} ->
          {%TemperatureSchema{}, %{temperature: value.temperature}, [:temperature]}

        %TargetTemperature{} ->
          {%TargetTemperatureSchema{}, %{target_temperature: value.target_temperature}, [:target_temperature]}

        %Heating{} ->
          {%HeatingSchema{}, %{heating: value.heating}, [:heating]}

        %Power{} ->
          {%PowerSchema{}, %{power: value.power}, [:power]}

        %GdState{} ->
          {%GdStateSchema{}, %{state: value.state}, [:state]}

        %DrmsState{} ->
          {%DrmsStateSchema{}, %{state: value.state}, [:state]}
      end

    schema
    |> Changeset.cast(params, permitted)
    |> Changeset.cast(%{timestamp: value.timestamp, device_id: device_id}, [
      :timestamp,
      :device_id
    ])
    |> Repo.insert(on_conflict: [set: [value: value]], conflict_target: :timestamp)
  end

  @spec fetch(value_module(), integer(), {DateTime.t(), Datetime.t()}) :: struct()
  def fetch(value, device_id, period)
      when value in [ConnectionState, PairingState, Temperature, TargetTemperature, Heating, Power, GdState, DrmsState] do
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
      %ConnectionStateSchema{} = value ->
        %ConnectionState{timestamp: value.timestamp, connected?: value.connected}

      %PairingStateSchema{} = value ->
        %PairingState{timestamp: value.timestamp, paired?: value.paired}

      %TemperatureSchema{} = value ->
        %Temperature{timestamp: value.timestamp, temperature: value.temperature}

      %TargetTemperatureSchema{} = value ->
        %TargetTemperature{
          timestamp: value.timestamp,
          target_temperature: value.target_temperature
        }

      %HeatingSchema{} = value ->
        %Heating{timestamp: value.timestamp, heating: value.heating}

      %PowerSchema{} = value ->
        %Power{timestamp: value.timestamp, power: value.power}

      %GdStateSchema{} = value ->
        %GdState{timestamp: value.timestamp, state: value.state}

      %DrmsStateSchema{} = value ->
        %DrmsState{timestamp: value.timestamp, state: value.state}
    end)
  end
end
