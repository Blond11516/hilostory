defmodule Hilostory.Schema.PowerSchema do
  alias Hilostory.Schema.DeviceSchema
  use Ecto.Schema

  @primary_key false

  schema "device_power" do
    belongs_to :device, DeviceSchema, primary_key: true
    field :power, :float
    field :timestamp, :utc_datetime_usec, primary_key: true
  end
end
