defmodule Hilostory.Schema.DeviceSchema do
  @moduledoc false
  use Ecto.Schema

  alias Hilostory.Schema.ConnectionStateSchema
  alias Hilostory.Schema.DrmsStateSchema
  alias Hilostory.Schema.GdStateSchema
  alias Hilostory.Schema.HeatingSchema
  alias Hilostory.Schema.PairingStateSchema
  alias Hilostory.Schema.PowerSchema
  alias Hilostory.Schema.TargetTemperatureSchema
  alias Hilostory.Schema.TemperatureSchema

  schema "device" do
    field :hilo_id, :string, primary_key: true
    field :name, :string
    field :type, :string
    has_many :connection_states, ConnectionStateSchema, foreign_key: :device_id
    has_many :drms_states, DrmsStateSchema, foreign_key: :device_id
    has_many :gd_states, GdStateSchema, foreign_key: :device_id
    has_many :heatings, HeatingSchema, foreign_key: :device_id
    has_many :pairing_states, PairingStateSchema, foreign_key: :device_id
    has_many :powers, PowerSchema, foreign_key: :device_id
    has_many :target_temperatures, TargetTemperatureSchema, foreign_key: :device_id
    has_many :temperatures, TemperatureSchema, foreign_key: :device_id
  end
end
