defmodule Hilostory.DeviceValue.TargetTemperature do
  @moduledoc false
  use TypedStruct

  typedstruct enforce: true do
    field :target_temperature, float()
    field :timestamp, DateTime.t()
  end
end
