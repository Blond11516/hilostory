defmodule Hilostory.Graphql.Subscription do
  @moduledoc false
  use WebSockex

  alias Hilostory.DeviceValue.Reading
  alias Hilostory.Graphql.DevicesUpdatedMessage
  alias Hilostory.Graphql.Message
  alias Hilostory.Graphql.SubscriptionQuery
  alias Hilostory.Infrastructure.DeviceValueRepository
  alias Hilostory.Infrastructure.OauthTokensRepository

  require Logger

  def start_link(%{subscription: subscription}) do
    Logger.info("Starting GraphQL subscription")

    case OauthTokensRepository.get() do
      nil ->
        {:error, "No OAuth token found"}

      tokens ->
        {:ok, websockex_pid} =
          "wss://platform.hiloenergie.com"
          |> URI.parse()
          |> URI.append_path("/api")
          |> URI.append_path("/digital-twin")
          |> URI.append_path("/v3")
          |> URI.append_path("/graphql")
          |> URI.append_query(URI.encode_query(%{"access_token" => tokens.access_token}))
          |> URI.to_string()
          |> WebSockex.start_link(__MODULE__, subscription,
            extra_headers: [{"Sec-WebSocket-Protocol", "graphql-transport-ws"}]
          )

        {:ok, websockex_pid}
    end
  end

  @impl true
  def handle_connect(_conn, state) do
    Logger.info("Websocket connected, will initialize connection")

    WebSockex.cast(self(), :initialize_connection)

    {:ok, state}
  end

  @impl true
  def handle_disconnect(connection_status_map, state) do
    Logger.info("Websocket disconnected: #{connection_status_map}")

    {:ok, state}
  end

  @impl true
  def handle_cast(:initialize_connection, state) do
    message = {:text, Message.initialize_connection()}

    Logger.debug("Sending websocket frame to initialize subscription connection: #{inspect(message)}")

    {:reply, message, state}
  end

  def handle_cast(:subscribe, %SubscriptionQuery{} = subscription_query) do
    message = {:text, Message.subscribe(subscription_query)}

    Logger.debug("Sending websocket frame to subscribe to #{subscription_query.operation_name}: #{inspect(message)}")

    {:reply, message, subscription_query}
  end

  def handle_cast(:pong, state) do
    message = {:text, Message.pong()}

    Logger.debug("Sending pong websocket frame")

    {:reply, message, state}
  end

  @impl true
  def handle_frame(frame, state) do
    Logger.debug("Received frame #{inspect(frame)}")

    {:text, frame_text} = frame

    frame_text
    |> Message.from_websocket_frame()
    |> tap(&Logger.debug("Decoded message #{inspect(&1)}"))
    |> handle_message()

    {:ok, state}
  end

  @impl true
  def terminate(close_reason, _state) do
    Logger.error("Subscription terminating: #{inspect(close_reason)}")

    :ok
  end

  defp handle_message(%Message{type: "connection_ack"}) do
    WebSockex.cast(self(), :subscribe)
  end

  defp handle_message(%Message{type: "ping"}) do
    WebSockex.cast(self(), :pong)
  end

  defp handle_message(%Message{type: "next"} = message) do
    Logger.info("Received next message")
    Logger.debug("Raw message: #{inspect(message)}")

    {:ok, payload} = Zoi.parse(DevicesUpdatedMessage.schema(), message.payload)
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

  defp handle_message(%Message{type: "error"} = message) do
    Logger.error("Received error message: #{inspect(message)}")
  end

  defp handle_message(%Message{} = message) do
    Logger.warning("Received unexpected message with type #{message.type}")
  end
end
