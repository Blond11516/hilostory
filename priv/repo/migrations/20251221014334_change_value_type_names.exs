defmodule Hilostory.Repo.Migrations.ChangeValueTypeNames do
  use Ecto.Migration

  def up do
    execute "ALTER TYPE device_value_type RENAME VALUE 'temperature' TO 'ambient_temperature'"

    execute "ALTER TYPE device_value_type RENAME VALUE 'target_temperature' TO 'ambient_temperature_setpoint'"
  end

  def down do
    execute "ALTER TYPE device_value_type RENAME VALUE 'ambient_temperature' TO 'temperature'"

    execute "ALTER TYPE device_value_type RENAME VALUE 'ambient_temperature_setpoint' TO 'target_temperature'"
  end
end
