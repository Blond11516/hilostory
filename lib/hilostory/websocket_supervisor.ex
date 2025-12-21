defmodule Hilostory.WebsocketSupervisor do
  @moduledoc false
  use DynamicSupervisor

  alias Hilostory.Graphql.Subscription
  alias Hilostory.Graphql.SubscriptionQuery
  alias Hilostory.Infrastructure.OauthTokensRepository
  alias Hilostory.SupervisorChildStartErrorLogger

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_websocket do
    case OauthTokensRepository.get() do
      nil ->
        {:error, "No OAuth token found"}

      tokens ->
        DynamicSupervisor.start_child(
          __MODULE__,
          SupervisorChildStartErrorLogger.child_spec(Subscription, %{
            access_token: tokens.access_token,
            subscription: devices_subscription()
          })
        )
    end
  end

  defp devices_subscription do
    %SubscriptionQuery{
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
  end
end
