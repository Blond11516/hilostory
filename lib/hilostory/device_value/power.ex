defmodule Hilostory.DeviceValue.Power do
  @moduledoc false
  use TypedStruct

  typedstruct enforce: true do
    field :power, float()
    field :timestamp, DateTime.t()
  end
end
