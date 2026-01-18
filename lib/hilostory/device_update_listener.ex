defmodule Hilostory.DeviceUpdateListener do
  @moduledoc false
  use WebSockex

  alias Hilostory.DeviceValue.Reading
  alias Hilostory.Graphql.DevicesUpdatedMessage
  alias Hilostory.Graphql.Subscription
  alias Hilostory.Graphql.SubscriptionQuery
  alias Hilostory.Infrastructure.DeviceValueRepository
  alias Hilostory.Infrastructure.OauthTokensRepository

  require Logger

  @devices_subscription %SubscriptionQuery{
    query: """
    subscription onAnyDeviceUpdated($locationHiloId: String!) {
        onAnyDeviceUpdated(locationHiloId: $locationHiloId) {
            locationHiloId
            transmissionTime
            device {
                ... on BasicSmartMeter {
                    deviceType
                    hiloId
                    power {
                        value
                        kind
                    }
                }
                ... on BasicThermostat {
                    deviceType
                    hiloId
                    ambientTemperature {
                        value
                        kind
                    }
                    ambientTempSetpoint {
                        value
                        kind
                    }
                    power {
                        value
                        kind
                    }
                }
            }
        }
    }
    """,
    operation_name: "onAnyDeviceUpdated",
    variables: %{"locationHiloId" => "urn:hilo:crm:4594276-s3h2l9:0"}
  }

  def start_link(_) do
    Logger.info("Starting device update listener")

    case OauthTokensRepository.get() do
      nil ->
        {:error, "No OAuth token found"}

      tokens ->
        url =
          "wss://platform.hiloenergie.com"
          |> URI.parse()
          |> URI.append_path("/api")
          |> URI.append_path("/digital-twin")
          |> URI.append_path("/v3")
          |> URI.append_path("/graphql")
          |> URI.append_query(URI.encode_query(%{"access_token" => tokens.access_token}))

        Subscription.start_link(%{
          subscription: @devices_subscription,
          url: url,
          handle_next: &handle_device_update/1
        })
    end
  end

  defp handle_device_update(payload) do
    {:ok, payload} = Zoi.parse(DevicesUpdatedMessage.schema(), payload)
    Logger.debug("Parsed message: #{inspect(payload)}")

    device_id = DevicesUpdatedMessage.device_id(payload)
    values = DevicesUpdatedMessage.values(payload)
    timestamp = DevicesUpdatedMessage.timestamp(payload)

    Logger.info("Inserting values for device \"#{device_id}\" at timestamp #{timestamp}")
    Logger.debug("Inserting values #{inspect(values)}")

    values
    |> Enum.map(fn value -> %Reading{timestamp: timestamp, value: value} end)
    |> DeviceValueRepository.upsert(device_id)
  end
end
