defmodule Hilostory.Infrastructure.Hilo.Models.Device do
  @moduledoc false

  @schema Zoi.object(%{
            "assetId" => Zoi.string(),
            "category" => Zoi.string(),
            "eTag" => Zoi.string(),
            "externalGroup" => Zoi.string(),
            "gatewayAssetId" => Zoi.null(),
            "gatewayExternalId" => Zoi.string(),
            "gatewayId" => Zoi.integer(),
            "groupId" => Zoi.integer(),
            "hiloId" => Zoi.string(),
            "icon" => Zoi.null(),
            "id" => Zoi.integer(),
            "identifier" => Zoi.string(),
            "isFavorite" => Zoi.boolean(),
            "loadConnected" => Zoi.null(),
            "locationId" => Zoi.integer(),
            "modelNumber" => Zoi.string(),
            "name" => Zoi.string(),
            "parameters" => Zoi.null(),
            "provider" => Zoi.integer(),
            "providerData" => Zoi.string() |> Zoi.transform(&JSON.decode!/1) |> Zoi.nullable(),
            "settableAttributes" => Zoi.string(),
            "settableAttributesList" => Zoi.array(Zoi.string()),
            "supportedParameters" => Zoi.string(),
            "supportedParametersList" => Zoi.array(Zoi.string()),
            "type" => Zoi.string()
          })

  # @type t :: unquote(Zoi.type_spec(@schema))

  def schema, do: @schema
end
