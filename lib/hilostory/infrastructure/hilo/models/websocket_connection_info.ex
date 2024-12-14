defmodule Hilostory.Infrastructure.Hilo.Models.WebsocketConnectionInfo do
  @keys [
    :access_token,
    :available_transports,
    :negotiate_version,
    :url
  ]

  @enforce_keys @keys
  defstruct @keys

  @type t :: %__MODULE__{
          access_token: String.t(),
          available_transports: List.t(),
          negotiate_version: integer(),
          url: URI.t()
        }
end
