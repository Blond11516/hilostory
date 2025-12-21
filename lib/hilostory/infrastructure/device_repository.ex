defmodule Hilostory.Infrastructure.DeviceRepository do
  @moduledoc false
  alias Ecto.Changeset
  alias Hilostory.Device
  alias Hilostory.Repo
  alias Hilostory.Schema.DeviceSchema

  def upsert(%Device{} = device) do
    params = Map.delete(device, :__struct__)

    %DeviceSchema{}
    |> Changeset.cast(params, [:hilo_id, :name, :type])
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:hilo_id])
  end

  def update(id, name) when is_binary(id) and is_binary(name) do
    %DeviceSchema{hilo_id: id}
    |> Changeset.cast(%{name: name}, [:name])
    |> Repo.update()
  end

  def all do
    Repo.all(DeviceSchema)
  end
end
