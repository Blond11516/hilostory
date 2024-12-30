defmodule Hilostory.Repo.Migrations.AddDevices do
  use Ecto.Migration

  def change do
    create table("device", primary_key: false) do
      add :id, :integer, null: false, primary_key: true
      add :hilo_id, :text, null: false
      add :name, :text, null: false
      add :type, :text, null: false
    end
  end
end
