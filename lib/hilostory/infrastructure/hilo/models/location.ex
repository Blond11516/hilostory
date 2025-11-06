defmodule Hilostory.Infrastructure.Hilo.Models.Location do
  @moduledoc false

  @schema Zoi.object(%{
            "addressId" => Zoi.string(),
            "countryCode" => Zoi.string(),
            "createdUtc" => Zoi.ISO.datetime(),
            "energyCostConfigured" => Zoi.boolean(),
            "gatewayCount" => Zoi.integer(),
            "id" => Zoi.integer(),
            "locationHiloId" => Zoi.string(),
            "name" => Zoi.string(),
            "postalCode" => Zoi.string(),
            "temperatureFormat" => Zoi.string(),
            "timeFormat" => Zoi.string(),
            "timeZone" => Zoi.string(),
            "ratePlan" =>
              Zoi.object(%{
                "current" => Zoi.string(),
                "history" =>
                  Zoi.array(
                    Zoi.object(%{
                      "effectiveDate" => Zoi.ISO.datetime(),
                      "name" => Zoi.string()
                    })
                  )
              }),
            "mobileAppAccessDeniedReason" => Zoi.null()
          })

  def schema, do: @schema
end
