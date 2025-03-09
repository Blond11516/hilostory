defmodule Hilostory.DeviceValue.Heating do
  @moduledoc false
  use TypedStruct

  typedstruct enforce: true do
    field :heating, float()
    field :timestamp, DateTime.t()
  end
end
