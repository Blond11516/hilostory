defmodule Hilostory.Repo.Migrations.RemoveDeviceId do
  use Ecto.Migration

  import Ecto.Query, only: [from: 2, field: 2]

  def up do
    alter table("device") do
      add :tmp_hilo_id, :text
    end

    flush()

    from(d in "device",
      update: [set: [tmp_hilo_id: d.hilo_id]]
    )
    |> Hilostory.Repo.update_all([])

    create unique_index("device", [:tmp_hilo_id])

    migrate_value_table_foreign_key("device_connection_state", :id, :tmp_hilo_id)
    migrate_value_table_foreign_key("device_drms_state", :id, :tmp_hilo_id)
    migrate_value_table_foreign_key("device_gd_state", :id, :tmp_hilo_id)
    migrate_value_table_foreign_key("device_heating", :id, :tmp_hilo_id)
    migrate_value_table_foreign_key("device_pairing_state", :id, :tmp_hilo_id)
    migrate_value_table_foreign_key("device_power", :id, :tmp_hilo_id)
    migrate_value_table_foreign_key("device_target_temperature", :id, :tmp_hilo_id)
    migrate_value_table_foreign_key("device_temperature", :id, :tmp_hilo_id)

    alter table("device") do
      remove :id
      modify :hilo_id, :text, primary_key: true
    end

    migrate_value_table_foreign_key("device_connection_state", :hilo_id, :hilo_id)
    migrate_value_table_foreign_key("device_drms_state", :hilo_id, :hilo_id)
    migrate_value_table_foreign_key("device_gd_state", :hilo_id, :hilo_id)
    migrate_value_table_foreign_key("device_heating", :hilo_id, :hilo_id)
    migrate_value_table_foreign_key("device_pairing_state", :hilo_id, :hilo_id)
    migrate_value_table_foreign_key("device_power", :hilo_id, :hilo_id)
    migrate_value_table_foreign_key("device_target_temperature", :hilo_id, :hilo_id)
    migrate_value_table_foreign_key("device_temperature", :hilo_id, :hilo_id)

    alter table("device") do
      remove :tmp_hilo_id
    end
  end

  def down do
    alter table("device") do
      add :tmp_id, :integer, null: false, generated: "ALWAYS AS IDENTITY"
    end

    create unique_index("device", [:tmp_id])

    rollback_value_table_foreign_key("device_temperature", :hilo_id, :tmp_id)
    rollback_value_table_foreign_key("device_target_temperature", :hilo_id, :tmp_id)
    rollback_value_table_foreign_key("device_power", :hilo_id, :tmp_id)
    rollback_value_table_foreign_key("device_pairing_state", :hilo_id, :tmp_id)
    rollback_value_table_foreign_key("device_heating", :hilo_id, :tmp_id)
    rollback_value_table_foreign_key("device_gd_state", :hilo_id, :tmp_id)
    rollback_value_table_foreign_key("device_drms_state", :hilo_id, :tmp_id)
    rollback_value_table_foreign_key("device_connection_state", :hilo_id, :tmp_id)

    drop constraint("device", "device_pkey")

    alter table("device") do
      modify :hilo_id, :text, null: false
      add :id, :integer
    end

    flush()

    from(d in "device",
      update: [set: [id: d.tmp_id]]
    )
    |> Hilostory.Repo.update_all([])

    alter table("device") do
      modify :id, :integer, primary_key: true
    end

    rollback_value_table_foreign_key("device_temperature", :id, :id)
    rollback_value_table_foreign_key("device_target_temperature", :id, :id)
    rollback_value_table_foreign_key("device_power", :id, :id)
    rollback_value_table_foreign_key("device_pairing_state", :id, :id)
    rollback_value_table_foreign_key("device_heating", :id, :id)
    rollback_value_table_foreign_key("device_gd_state", :id, :id)
    rollback_value_table_foreign_key("device_drms_state", :id, :id)
    rollback_value_table_foreign_key("device_connection_state", :id, :id)

    alter table("device") do
      remove :tmp_id
    end
  end

  defp migrate_value_table_foreign_key(table_name, device_primary_key_name, column_name) do
    alter table(table_name) do
      add :new_device_id, :text
    end

    flush()

    from(dt in table_name,
      join: d in "device",
      on: dt.device_id == field(d, ^device_primary_key_name),
      update: [set: [new_device_id: d.hilo_id]]
    )
    |> Hilostory.Repo.update_all([])

    alter table(table_name) do
      remove :device_id
      modify :new_device_id, references("device", column: column_name, type: :text), null: false
    end

    rename table(table_name), :new_device_id, to: :device_id
  end

  defp rollback_value_table_foreign_key(table_name, device_primary_key_name, column_name) do
    rename table(table_name), :device_id, to: :new_device_id

    alter table(table_name) do
      add :device_id,
          references("device",
            column: column_name,
            name: "#{table_name}_device_id_#{column_name}_fkey"
          )
    end

    flush()

    from(
      dt in table_name,
      join: d in "device",
      on: dt.new_device_id == field(d, ^device_primary_key_name),
      update: [set: [device_id: field(d, ^column_name)]]
    )
    |> Hilostory.Repo.update_all([])

    alter table(table_name) do
      remove :new_device_id
      modify :device_id, :integer, null: false
    end
  end
end
