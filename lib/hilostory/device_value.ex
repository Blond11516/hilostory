defmodule Hilostory.DeviceValue do
  @moduledoc false
  use TypedStruct

  require Logger

  typedstruct enforce: true do
    field :type, :ambient_temperature | :ambient_temperature_setpoint | :power
    field :value, float()
    field :kind, String.t()
  end

  def normalized(%__MODULE__{kind: "KILOWATT"} = value) do
    %{value | kind: "WATT", value: Float.round(value.value * 1000)}
  end

  def normalized(%__MODULE__{kind: kind} = value) when kind in ["WATT", "DEGREE_CELSIUS"] do
    value
  end

  def normalized(value) do
    Logger.warning("Found value with unknown kind \"#{value.kind}\"")
    value
  end
end
