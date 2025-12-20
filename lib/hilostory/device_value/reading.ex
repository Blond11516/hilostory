defmodule Hilostory.DeviceValue.Reading do
  @moduledoc false
  use TypedStruct

  typedstruct enforce: true do
    field :timestamp, DateTime.t()
    field :value, Hilostory.DeviceValue.t()
  end
end
