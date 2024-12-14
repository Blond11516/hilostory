defmodule Hilostory.Infrastructure.Hilo.Models.Device do
  @keys [
    :asset_id,
    :category,
    :e_tag,
    :external_group,
    :gateway_asset_id,
    :gateway_external_id,
    :gateway_id,
    :group_id,
    :hilo_id,
    :icon,
    :id,
    :identifier,
    :is_favorite,
    :load_connected,
    :location_id,
    :model_number,
    :name,
    :parameters,
    :provider,
    :provider_data,
    :settable_attributes,
    :settable_attributes_list,
    :supported_attributes,
    :supported_attributes_list,
    :supported_parameters,
    :supported_parameters_list,
    :type
  ]

  @enforce_keys @keys
  defstruct @keys

  @type t :: %__MODULE__{
          asset_id: String.t(),
          category: String.t(),
          e_tag: String.t(),
          external_group: String.t(),
          gateway_asset_id: nil,
          gateway_external_id: String.t(),
          gateway_id: integer(),
          group_id: integer(),
          hilo_id: String.t(),
          icon: nil,
          id: integer(),
          identifier: String.t(),
          is_favorite: boolean(),
          load_connected: nil,
          location_id: integer(),
          model_number: String.t(),
          name: String.t(),
          parameters: nil,
          provider: integer(),
          provider_data: nil | %{String.t() => String.t()},
          settable_attributes: String.t(),
          settable_attributes_list: list(String.t()),
          supported_attributes: String.t(),
          supported_attributes_list: list(String.t()),
          supported_parameters: String.t(),
          supported_parameters_list: list(String.t()),
          type: String.t()
        }
end
