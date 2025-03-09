defmodule Hilostory.DeviceValue.ConnectionState do
  @moduledoc false
  use TypedStruct

  typedstruct enforce: true do
    field :connected?, boolean()
    field :timestamp, DateTime.t()
  end
end
