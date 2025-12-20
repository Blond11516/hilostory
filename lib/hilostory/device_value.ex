defmodule Hilostory.DeviceValue do
  @moduledoc false
  use TypedStruct

  typedstruct enforce: true do
    field :type, :ambient_temperature | :ambient_temperature_setpoint | :power
    field :value, float()
    field :kind, String.t()
  end
end
