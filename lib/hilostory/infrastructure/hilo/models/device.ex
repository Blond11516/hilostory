defmodule Hilostory.Infrastructure.Hilo.Models.Device do
  use TypedStruct

  typedstruct enforce: true do
    field :asset_id, String.t()
    field :category, String.t()
    field :e_tag, String.t()
    field :external_group, String.t()
    field :gateway_asset_id, nil
    field :gateway_external_id, String.t()
    field :gateway_id, integer()
    field :group_id, integer()
    field :hilo_id, String.t()
    field :icon, nil
    field :id, integer()
    field :identifier, String.t()
    field :is_favorite, boolean()
    field :load_connected, nil
    field :location_id, integer()
    field :model_number, String.t()
    field :name, String.t()
    field :parameters, nil
    field :provider, integer()
    field :provider_data, nil | %{String.t() => String.t()}
    field :settable_attributes, String.t()
    field :settable_attributes_list, list(String.t())
    field :supported_parameters, String.t()
    field :supported_parameters_list, list(String.t())
    field :type, String.t()
  end
end
