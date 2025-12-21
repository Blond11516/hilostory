defmodule Hilostory.Schema.DeviceSchema do
  @moduledoc false
  use Ecto.Schema

  alias Hilostory.Schema.DeviceValueSchema

  @primary_key false

  schema "device" do
    field :hilo_id, :string, primary_key: true
    field :name, :string
    field :type, :string
    has_many :values, DeviceValueSchema, references: :hilo_id, foreign_key: :device_id
  end
end
