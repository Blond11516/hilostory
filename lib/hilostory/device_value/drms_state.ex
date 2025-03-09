defmodule Hilostory.DeviceValue.DrmsState do
  @moduledoc false
  use TypedStruct

  typedstruct do
    field :state, boolean()
    field :timestamp, DateTime.t()
  end
end
