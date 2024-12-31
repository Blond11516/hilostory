defmodule Hilostory.Repo.Migrations.AddDeviceValueTables do
  use Ecto.Migration

  import Timescale.Migration

  def up do
    create_timescaledb_extension()

    create table("device_connection_state", primary_key: false) do
      add :connected, :boolean, null: false
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :device_id, references("device"), null: false
    end

    create_hypertable("device_connection_state", :timestamp)

    create table("device_drms_state", primary_key: false) do
      add :state, :boolean, null: false
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :device_id, references("device"), null: false
    end

    create_hypertable("device_drms_state", :timestamp)

    create table("device_gd_state", primary_key: false) do
      add :state, :integer, null: false
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :device_id, references("device"), null: false
    end

    create_hypertable("device_gd_state", :timestamp)

    create table("device_heating", primary_key: false) do
      add :heating, :float, null: false
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :device_id, references("device"), null: false
    end

    create_hypertable("device_heating", :timestamp)

    create table("device_pairing_state", primary_key: false) do
      add :paired, :boolean, null: false
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :device_id, references("device"), null: false
    end

    create_hypertable("device_pairing_state", :timestamp)

    create table("device_power", primary_key: false) do
      add :power, :float, null: false
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :device_id, references("device"), null: false
    end

    create_hypertable("device_power", :timestamp)

    create table("device_target_temperature", primary_key: false) do
      add :target_temperature, :float, null: false
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :device_id, references("device"), null: false
    end

    create_hypertable("device_target_temperature", :timestamp)

    create table("device_temperature", primary_key: false) do
      add :temperature, :float, null: false
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :device_id, references("device"), null: false
    end

    create_hypertable("device_temperature", :timestamp)
  end

  def down do
    drop table("device_temperature")
    drop table("device_target_temperature")
    drop table("device_power")
    drop table("device_pairing_state")
    drop table("device_heating")
    drop table("device_gd_state")
    drop table("device_drms_state")
    drop table("device_connection_state")
    drop_timescaledb_extension()
  end
end
