defmodule Hilostory.Infrastructure.Hilo.Models.WebsocketMessages.DeviceListInitialValuesReceived do
  @keys [
    :category,
    :e_tag,
    :external_group,
    :hilo_id,
    :id,
    :identifier,
    :is_favorite,
    :model_number,
    :name,
    :provider,
    :settable_attributes_list,
    :supported_attributes_list,
    :supported_parameters_list,
    :type
  ]

  @enforce_keys @keys
  defstruct @keys ++ [group_id: nil]

  @type t :: %__MODULE__{
          category: String.t(),
          e_tag: String.t(),
          external_group: String.t(),
          group_id: integer() | nil,
          hilo_id: String.t(),
          id: integer(),
          identifier: String.t(),
          is_favorite: boolean(),
          model_number: String.t(),
          name: String.t(),
          provider: integer(),
          settable_attributes_list: list(String.t()),
          supported_attributes_list: list(String.t()),
          supported_parameters_list: list(String.t()),
          type: String.t()
        }
end
