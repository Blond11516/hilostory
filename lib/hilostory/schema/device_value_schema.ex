defmodule Hilostory.Schema.DeviceValueSchema do
  @moduledoc false
  use Ecto.Schema

  alias Hilostory.DeviceValue
  alias Hilostory.DeviceValue.Reading
  alias Hilostory.Schema.DeviceSchema

  @primary_key false

  schema "device_value" do
    field :timestamp, :utc_datetime_usec, primary_key: true
    field :value_name, Ecto.Enum, values: [:ambient_temperature, :ambient_temperature_setpoint, :power], primary_key: true
    belongs_to :device, DeviceSchema, references: :hilo_id, type: :string, primary_key: true
    field :value, :float
    field :kind, :string
  end

  def to_reading(%__MODULE__{} = value) do
    %Reading{
      timestamp: value.timestamp,
      value: %DeviceValue{
        type: value.value_name,
        value: value.value,
        kind: value.kind
      }
    }
  end
end
