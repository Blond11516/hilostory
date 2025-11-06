defmodule Hilostory.Infrastructure.Hilo.Models.WebsocketMessages.DeviceListInitialValuesReceived do
  @moduledoc false

  @schema Zoi.object(%{
            "category" => Zoi.string(),
            "eTag" => Zoi.string(),
            "externalGroup" => Zoi.string(),
            "groupId" => Zoi.optional(Zoi.integer()),
            "hiloId" => Zoi.string(),
            "id" => Zoi.integer(),
            "identifier" => Zoi.string(),
            "isFavorite" => Zoi.boolean(),
            "modelNumber" => Zoi.string(),
            "name" => Zoi.string(),
            "provider" => Zoi.integer(),
            "settableAttributesList" => Zoi.array(Zoi.string()),
            "supportedAttributesList" => Zoi.array(Zoi.string()),
            "supportedParametersList" => Zoi.array(Zoi.string()),
            "type" => Zoi.string()
          })

  # @type t :: unquote(Zoi.type_spec(@schema))

  def schema, do: @schema
end
