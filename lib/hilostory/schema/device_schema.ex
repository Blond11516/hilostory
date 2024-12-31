defmodule Hilostory.Schema.DeviceSchema do
  alias Hilostory.Schema.PowerSchema
  alias Hilostory.Schema.TemperatureSchema
  alias Hilostory.Schema.TargetTemperatureSchema
  alias Hilostory.Schema.PairingStateSchema
  alias Hilostory.Schema.HeatingSchema
  alias Hilostory.Schema.GdStateSchema
  alias Hilostory.Schema.DrmsStateSchema
  alias Hilostory.Schema.ConnectionStateSchema

  use Ecto.Schema

  @primary_key {:id, :integer, []}

  schema "device" do
    field :hilo_id, :string
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
