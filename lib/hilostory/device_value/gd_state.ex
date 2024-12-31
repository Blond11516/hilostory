defmodule Hilostory.DeviceValue.GdState do
  use TypedStruct

  typedstruct enforce: true do
    field :state, integer()
    field :timestamp, DateTime.t()
  end
end
