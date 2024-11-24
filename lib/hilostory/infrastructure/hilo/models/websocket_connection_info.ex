defmodule Hilostory.Infrastructure.Hilo.Models.WebsocketConnectionInfo do
  @keys [
    :access_token,
    :available_transports,
    :negotiate_version,
    :url
  ]

  @enforce_keys @keys
  defstruct @keys
end
