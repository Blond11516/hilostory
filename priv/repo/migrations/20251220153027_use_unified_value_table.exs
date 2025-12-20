defmodule Hilostory.Repo.Migrations.UseUnifiedValueTable do
  use Ecto.Migration

  import Timescale.Migration

  def up do
    execute "CREATE TYPE device_value_type AS ENUM ('temperature', 'target_temperature', 'power')"

    create table("device_value", primary_key: false) do
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :value_name, :device_value_type, null: false, primary_key: true
      add :device_id, references("device", type: :text, column: :hilo_id), primary_key: true
      add :value, :real, null: false
    end

    create_hypertable("device_value", :timestamp)

    drop table("device_power")
    drop table("device_target_temperature")
    drop table("device_temperature")
  end

  def down do
    create table("device_power", primary_key: false) do
      add :paired, :boolean, null: false
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :device_id, references("device", type: :text, column: :hilo_id), null: false
    end

    create_hypertable("device_power", :timestamp)

    create table("device_target_temperature", primary_key: false) do
      add :paired, :boolean, null: false
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :device_id, references("device", type: :text, column: :hilo_id), null: false
    end

    create_hypertable("device_target_temperature", :timestamp)

    create table("device_temperature", primary_key: false) do
      add :paired, :boolean, null: false
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :device_id, references("device", type: :text, column: :hilo_id), null: false
    end

    create_hypertable("device_temperature", :timestamp)

    drop table("device_value")
    execute "DROP TYPE device_value_type"
  end
end
