defmodule Hilostory.Infrastructure.Hilo.Models.WebsocketMessages.DeviceListUpdatedValuesReceived do
  @moduledoc false

  @schema Zoi.object(%{
            "category" => Zoi.string(),
            "groupId" => Zoi.nullable(Zoi.integer()),
            "hiloId" => Zoi.string(),
            "id" => Zoi.integer(),
            "name" => Zoi.string()
          })

  # @type t :: unquote(Zoi.type_spec(@schema))

  def schema, do: @schema
end
