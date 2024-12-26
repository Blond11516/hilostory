defmodule Hilostory.Infrastructure.Hilo.Models.Location do
  use TypedStruct

  typedstruct enforce: true do
    field :address_id, String.t()
    field :country_code, String.t()
    field :created_utc, DateTime.t()
    field :energy_cost_configured, boolean()
    field :gateway_count, integer()
    field :id, integer()
    field :location_hilo_id, String.t()
    field :name, String.t()
    field :postal_code, String.t()
    field :temperature_format, String.t()
    field :time_format, String.t()
    field :time_zone, String.t()
  end
end
