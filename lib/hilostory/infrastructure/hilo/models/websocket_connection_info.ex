defmodule Hilostory.Infrastructure.Hilo.Models.WebsocketConnectionInfo do
  @moduledoc false
  use TypedStruct

  typedstruct do
    field :access_token, String.t()
    field :available_transports, list()
    field :negotiate_version, integer()
    field :url, URI.t()
  end
end
