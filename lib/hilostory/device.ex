defmodule Hilostory.Device do
  @moduledoc false
  use TypedStruct

  typedstruct enforce: true do
    field :hilo_id, String.t()
    field :name, String.t()
    field :type, String.t()
  end
end
