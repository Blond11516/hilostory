defmodule Hilostory.Infrastructure.DeviceRepository do
  alias Hilostory.Schema.DeviceSchema
  alias Hilostory.Device
  alias Hilostory.Repo

  def upsert(%Device{} = device) do
    params = Map.drop(device, [:__struct__])

    %DeviceSchema{}
    |> Ecto.Changeset.cast(params, [:id, :hilo_id, :name, :type])
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:id])
  end
end
