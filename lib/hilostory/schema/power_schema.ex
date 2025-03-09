defmodule Hilostory.Schema.PowerSchema do
  @moduledoc false
  use Ecto.Schema

  alias Hilostory.Schema.DeviceSchema

  @primary_key false

  schema "device_power" do
    belongs_to :device, DeviceSchema, primary_key: true
    field :power, :float
    field :timestamp, :utc_datetime_usec, primary_key: true
  end
end
