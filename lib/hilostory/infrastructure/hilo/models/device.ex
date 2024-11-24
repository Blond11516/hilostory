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
end
