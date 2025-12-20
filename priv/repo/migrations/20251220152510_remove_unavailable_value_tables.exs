defmodule Hilostory.Repo.Migrations.RemoveUnavailableValueTables do
  use Ecto.Migration

  import Timescale.Migration

  def up do
    drop table("device_pairing_state")
    drop table("device_heating")
    drop table("device_gd_state")
    drop table("device_drms_state")
    drop table("device_connection_state")
  end

  def down do
    create_timescaledb_extension()

    create table("device_connection_state", primary_key: false) do
      add :connected, :boolean, null: false
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :device_id, references("device", type: :text, column: :hilo_id), null: false
    end

    create_hypertable("device_connection_state", :timestamp)

    create table("device_drms_state", primary_key: false) do
      add :state, :boolean, null: false
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :device_id, references("device", type: :text, column: :hilo_id), null: false
    end

    create_hypertable("device_drms_state", :timestamp)

    create table("device_gd_state", primary_key: false) do
      add :state, :integer, null: false
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :device_id, references("device", type: :text, column: :hilo_id), null: false
    end

    create_hypertable("device_gd_state", :timestamp)

    create table("device_heating", primary_key: false) do
      add :heating, :float, null: false
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :device_id, references("device", type: :text, column: :hilo_id), null: false
    end

    create_hypertable("device_heating", :timestamp)

    create table("device_pairing_state", primary_key: false) do
      add :paired, :boolean, null: false
      add :timestamp, :timestamptz, null: false, primary_key: true
      add :device_id, references("device", type: :text, column: :hilo_id), null: false
    end

    create_hypertable("device_pairing_state", :timestamp)
  end
end
