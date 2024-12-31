defmodule Hilostory.Schema.DrmsStateSchema do
  alias Hilostory.Schema.DeviceSchema
  use Ecto.Schema

  @primary_key false

  schema "device_drms_state" do
    belongs_to :device, DeviceSchema, primary_key: true
    field :state, :boolean
    field :timestamp, :utc_datetime_usec, primary_key: true
  end
end
