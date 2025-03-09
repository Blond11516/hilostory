defmodule Hilostory.Schema.PairingStateSchema do
  @moduledoc false
  use Ecto.Schema

  alias Hilostory.Schema.DeviceSchema

  @primary_key false

  schema "device_pairing_state" do
    belongs_to :device, DeviceSchema, primary_key: true
    field :paired, :boolean
    field :timestamp, :utc_datetime_usec, primary_key: true
  end
end
