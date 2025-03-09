defmodule Hilostory.Schema.TargetTemperatureSchema do
  @moduledoc false
  use Ecto.Schema

  alias Hilostory.Schema.DeviceSchema

  @primary_key false

  schema "device_target_temperature" do
    belongs_to :device, DeviceSchema, primary_key: true
    field :target_temperature, :float
    field :timestamp, :utc_datetime_usec, primary_key: true
  end
end
