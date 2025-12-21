defmodule Hilostory.Infrastructure.Hilo.Models.WebsocketConnectionInfo do
  @moduledoc false

  @schema Zoi.object(%{
            "accessToken" => Zoi.string(),
            "availableTransports" => Zoi.array(),
            "negotiateVersion" => Zoi.integer(),
            "url" => Zoi.transform(Zoi.url(), &URI.new/1)
          })

  def schema, do: @schema
end
