defmodule Hilostory.Infrastructure.DeviceValueRepository do
  alias Hilostory.DeviceValue.DrmsState
  alias Hilostory.DeviceValue.GdState
  alias Hilostory.DeviceValue.Power
  alias Hilostory.DeviceValue.Heating
  alias Hilostory.DeviceValue.TargetTemperature
  alias Hilostory.DeviceValue.Temperature
  alias Hilostory.DeviceValue.PairingState
  alias Hilostory.DeviceValue.ConnectionState
  alias Hilostory.Schema.DrmsStateSchema
  alias Hilostory.Schema.GdStateSchema
  alias Hilostory.Schema.PowerSchema
  alias Hilostory.Schema.HeatingSchema
  alias Hilostory.Schema.TargetTemperatureSchema
  alias Hilostory.Schema.TemperatureSchema
  alias Hilostory.Schema.PairingStateSchema
  alias Hilostory.Schema.ConnectionStateSchema
  alias Hilostory.Repo
  alias Ecto.Changeset

  def insert(value, device_id)
      when is_integer(device_id) and
             (is_struct(value, ConnectionState) or
                is_struct(value, PairingState) or
                is_struct(value, Temperature) or
                is_struct(value, TargetTemperature) or
                is_struct(value, Heating) or
                is_struct(value, Power) or
                is_struct(value, GdState) or
                is_struct(value, DrmsState)) do
    {schema, params, permitted} =
      case value do
        %ConnectionState{} ->
          {%ConnectionStateSchema{}, %{connected: value.connected?}, [:connected]}

        %PairingState{} ->
          {%PairingStateSchema{}, %{paired: value.paired?}, [:paired]}

        %Temperature{} ->
          {%TemperatureSchema{}, %{temperature: value.temperature}, [:temperature]}

        %TargetTemperature{} ->
          {%TargetTemperatureSchema{}, %{target_temperature: value.target_temperature},
           [:target_temperature]}

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
    |> Repo.insert()
  end
end
