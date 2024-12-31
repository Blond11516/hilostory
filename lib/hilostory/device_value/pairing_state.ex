defmodule Hilostory.DeviceValue.PairingState do
  use TypedStruct

  typedstruct enforce: true do
    field :paired?, boolean()
    field :timestamp, DateTime.t()
  end
end
