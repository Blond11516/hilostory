defmodule Hilostory.DeviceValue.Temperature do
  use TypedStruct

  typedstruct enforce: true do
    field :temperature, float()
    field :timestamp, DateTime.t()
  end
end
