defmodule Hilostory.Graphql.DevicesUpdatedMessage do
  @moduledoc false

  alias Hilostory.DeviceValue

  require Logger

  @value_schema Zoi.object(%{
                  "value" => Zoi.nullable(Zoi.number()),
                  "kind" => Zoi.string()
                })

  @schema Zoi.object(%{
            "data" =>
              Zoi.object(%{
                "onAnyDeviceUpdated" =>
                  Zoi.object(%{
                    "locationHiloId" => Zoi.string(),
                    "transmissionTime" => Zoi.ISO.to_datetime_struct(Zoi.ISO.datetime()),
                    "device" =>
                      Zoi.union([
                        Zoi.object(%{
                          "deviceType" => Zoi.literal("meter"),
                          "hiloId" => Zoi.string(),
                          "power" => @value_schema
                        }),
                        Zoi.object(%{
                          "deviceType" => Zoi.literal("tstat"),
                          "hiloId" => Zoi.string(),
                          "ambientTemperature" => @value_schema,
                          "ambientTempSetpoint" => @value_schema,
                          "power" => @value_schema
                        })
                      ])
                  })
              })
          })

  def schema, do: @schema

  def values(message) when is_map(message) do
    [
      {:power, get_in(message, ["data", "onAnyDeviceUpdated", "device", "power"])},
      {:ambient_temperature, get_in(message, ["data", "onAnyDeviceUpdated", "device", "ambientTemperature"])},
      {:ambient_temperature_setpoint, get_in(message, ["data", "onAnyDeviceUpdated", "device", "ambientTempSetpoint"])}
    ]
    |> Enum.filter(fn {_, value} -> value != nil end)
    |> Enum.map(fn {type, value} ->
      %DeviceValue{
        type: type,
        value:
          case value["value"] do
            x when is_float(x) -> x
            x when is_integer(x) -> x / 1
          end,
        kind: value["kind"]
      }
    end)
  end

  def device_id(message) when is_map(message) do
    get_in(message, ["data", "onAnyDeviceUpdated", "device", "hiloId"])
  end

  def timestamp(message) when is_map(message) do
    get_in(message, ["data", "onAnyDeviceUpdated", "transmissionTime"])
  end
end
