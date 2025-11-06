defmodule Hilostory.Infrastructure.Hilo.Models.WebsocketMessages.DeviceListUpdatedValuesReceived do
  @moduledoc false

  @schema Zoi.object(%{
            "category" => Zoi.string(),
            "groupId" => Zoi.nullable(Zoi.integer()),
            "hiloId" => Zoi.string(),
            "id" => Zoi.integer(),
            "name" => Zoi.string()
          })

  def schema, do: @schema
end
