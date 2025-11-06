defmodule Hilostory.Infrastructure.Hilo.Models.WebsocketConnectionInfo do
  @moduledoc false

  @schema Zoi.object(%{
            "accessToken" => Zoi.string(),
            "availableTransports" => Zoi.array(),
            "negotiateVersion" => Zoi.integer(),
            "url" => Zoi.url() |> Zoi.transform(&URI.new/1)
          })

  # @type t :: unquote(Zoi.type_spec(@schema))

  def schema, do: @schema
end
