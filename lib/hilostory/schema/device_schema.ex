defmodule Hilostory.Schema.DeviceSchema do
  use Ecto.Schema

  @primary_key false

  schema "device" do
    field :id, :integer, primary_key: true
    field :hilo_id, :string
    field :name, :string
    field :type, :string
  end
end
