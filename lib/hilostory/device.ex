defmodule Hilostory.Device do
  use TypedStruct

  typedstruct enforce: true do
    field :id, integer()
    field :hilo_id, String.t()
    field :name, String.t()
    field :type, String.t()
  end
end
