defmodule Hilostory.Infrastructure.Hilo.Models.WebsocketMessages.GatewayValuesReceived do
  @moduledoc false

  @schema Zoi.object(%{
            "attribute" => Zoi.string(),
            "deviceId" => Zoi.integer(),
            "hiloId" => Zoi.string(),
            "locationHiloId" => Zoi.string(),
            "locationId" => Zoi.integer(),
            "timeStampUtc" => Zoi.ISO.datetime(),
            "value" => Zoi.union([Zoi.integer(), Zoi.float(), Zoi.string(), Zoi.boolean(), Zoi.array()]),
            "valueType" => Zoi.nullable(Zoi.string())
          })

  # @type t :: unquote(Zoi.type_spec(@schema))

  def schema, do: @schema
end
