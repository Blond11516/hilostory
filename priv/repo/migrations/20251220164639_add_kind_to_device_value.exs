defmodule Hilostory.Repo.Migrations.AddUnitToDeviceValue do
  use Ecto.Migration

  def change do
    alter table("device_value") do
      add :kind, :text, null: false
    end
  end
end
