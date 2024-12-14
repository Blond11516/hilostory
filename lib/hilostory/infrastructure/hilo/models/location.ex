defmodule Hilostory.Infrastructure.Hilo.Models.Location do
  @keys [
    :address_id,
    :country_code,
    :created_utc,
    :energy_cost_configured,
    :gateway_count,
    :id,
    :location_hilo_id,
    :name,
    :postal_code,
    :temperature_format,
    :time_format,
    :time_zone
  ]

  @enforce_keys @keys
  defstruct @keys

  @type t :: %__MODULE__{
          address_id: String.t(),
          country_code: String.t(),
          created_utc: DateTime.t(),
          energy_cost_configured: boolean(),
          gateway_count: integer(),
          id: integer(),
          location_hilo_id: String.t(),
          name: String.t(),
          postal_code: String.t(),
          temperature_format: String.t(),
          time_format: String.t(),
          time_zone: String.t()
        }
end
