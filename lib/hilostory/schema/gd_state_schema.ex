defmodule Hilostory.Schema.GdStateSchema do
  @moduledoc false
  use Ecto.Schema

  alias Hilostory.Schema.DeviceSchema

  @primary_key false

  schema "device_gd_state" do
    belongs_to :device, DeviceSchema, primary_key: true
    field :state, :integer
    field :timestamp, :utc_datetime_usec, primary_key: true
  end
end
