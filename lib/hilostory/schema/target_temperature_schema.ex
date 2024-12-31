defmodule Hilostory.Schema.TargetTemperatureSchema do
  alias Hilostory.Schema.DeviceSchema
  use Ecto.Schema

  @primary_key false

  schema "device_target_temperature" do
    belongs_to :device, DeviceSchema, primary_key: true
    field :target_temperature, :float
    field :timestamp, :utc_datetime_usec, primary_key: true
  end
end
