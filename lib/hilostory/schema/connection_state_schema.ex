defmodule Hilostory.Schema.ConnectionStateSchema do
  alias Hilostory.Schema.DeviceSchema

  use Ecto.Schema

  @primary_key false

  schema "device_connection_state" do
    belongs_to :device, DeviceSchema, primary_key: true
    field :connected, :boolean
    field :timestamp, :utc_datetime_usec, primary_key: true
  end
end
