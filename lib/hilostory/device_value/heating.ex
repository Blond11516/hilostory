defmodule Hilostory.DeviceValue.Heating do
  use TypedStruct

  typedstruct enforce: true do
    field :heating, float()
    field :timestamp, DateTime.t()
  end
end
