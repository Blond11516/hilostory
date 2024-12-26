defmodule Hilostory.Infrastructure.Hilo.Models.WebsocketMessages.DeviceListInitialValuesReceived do
  use TypedStruct

  typedstruct enforce: true do
    field :category, String.t()
    field :e_tag, String.t()
    field :external_group, String.t()
    field :group_id, integer(), enforce: false
    field :hilo_id, String.t()
    field :id, integer()
    field :identifier, String.t()
    field :is_favorite, boolean()
    field :model_number, String.t()
    field :name, String.t()
    field :provider, integer()
    field :settable_attributes_list, list(String.t())
    field :supported_attributes_list, list(String.t())
    field :supported_parameters_list, list(String.t())
    field :type, String.t()
  end
end
