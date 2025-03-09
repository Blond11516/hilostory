defmodule Hilostory.Infrastructure.DeviceRepository do
  @moduledoc false
  alias Ecto.Changeset
  alias Hilostory.Device
  alias Hilostory.Repo
  alias Hilostory.Schema.DeviceSchema

  def upsert(%Device{} = device) do
    params = Map.delete(device, :__struct__)

    %DeviceSchema{}
    |> Changeset.cast(params, [:id, :hilo_id, :name, :type])
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:id])
  end

  def update(id, name) when is_integer(id) and is_binary(name) do
    %DeviceSchema{id: id}
    |> Changeset.cast(%{name: name}, [:name])
    |> Repo.update()
  end

  def all do
    Repo.all(DeviceSchema)
  end
end
