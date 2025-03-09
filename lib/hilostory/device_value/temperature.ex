defmodule Hilostory.DeviceValue.Temperature do
  @moduledoc false
  use TypedStruct

  typedstruct enforce: true do
    field :temperature, float()
    field :timestamp, DateTime.t()
  end
end
