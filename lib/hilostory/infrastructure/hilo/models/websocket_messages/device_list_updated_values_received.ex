defmodule Hilostory.Infrastructure.Hilo.Models.WebsocketMessages.DeviceListUpdatedValuesReceived do
  use TypedStruct

  typedstruct enforce: true do
    field :category, String.t()
    field :group_id, integer(), enforce: false
    field :hilo_id, String.t()
    field :id, integer()
    field :name, String.t()
  end
end
