defmodule Hilostory.DeviceValue.DrmsState do
  use TypedStruct

  typedstruct do
    field :state, boolean()
    field :timestamp, DateTime.t()
  end
end
