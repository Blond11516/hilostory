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
end
