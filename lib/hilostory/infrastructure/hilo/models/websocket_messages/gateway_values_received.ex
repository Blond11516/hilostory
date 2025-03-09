defmodule Hilostory.Infrastructure.Hilo.Models.WebsocketMessages.GatewayValuesReceived do
  @moduledoc false
  use TypedStruct

  typedstruct enforce: true do
    field :attribute, String.t()
    field :device_id, integer()
    field :hilo_id, String.t()
    field :location_hilo_id, String.t()
    field :location_id, integer()
    field :time_stamp_utc, DateTime.t()
    field :value, integer() | float() | String.t() | boolean() | list()
    field :value_type, String.t(), enforce: false
  end
end
