defmodule Hilostory.Infrastructure.Hilo.Models.WebsocketMessages.DeviceValuesReceived do
  @keys [
    :attribute,
    :device_id,
    :hilo_id,
    :location_hilo_id,
    :location_id,
    :time_stamp_utc,
    :value
  ]

  @enforce_keys @keys
  defstruct @keys ++ [value_type: nil]

  @type t :: %__MODULE__{
          attribute: String.t(),
          device_id: integer(),
          hilo_id: String.t(),
          location_hilo_id: String.t(),
          location_id: integer(),
          time_stamp_utc: DateTime.t(),
          value: integer() | float() | String.t() | boolean() | list(),
          value_type: String.t() | nil
        }
end
