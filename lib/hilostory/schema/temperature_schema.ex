defmodule Hilostory.Schema.TemperatureSchema do
  alias Hilostory.Schema.DeviceSchema
  use Ecto.Schema

  @primary_key false

  schema "device_temperature" do
    belongs_to :device, DeviceSchema, primary_key: true
    field :temperature, :float
    field :timestamp, :utc_datetime_usec, primary_key: true
  end
end
