defmodule Hilostory.Graphql.Subscription do
  @moduledoc false
  use WebSockex

  alias Hilostory.Graphql.Message
  alias Hilostory.Graphql.SubscriptionQuery

  require Logger

  def start_link(%{subscription: %SubscriptionQuery{} = subscription, url: %URI{} = url, handle_next: handle_next})
      when is_function(handle_next) do
    Logger.info("Starting GraphQL subscription")

    url
    |> URI.to_string()
    |> WebSockex.start_link(__MODULE__, {subscription, handle_next},
      extra_headers: [{"Sec-WebSocket-Protocol", "graphql-transport-ws"}]
    )
  end

  @impl WebSockex
  def handle_connect(_conn, state) do
    Logger.info("Websocket connected, will initialize connection")

    WebSockex.cast(self(), :initialize_connection)

    {:ok, state}
  end

  @impl WebSockex
  def handle_disconnect(connection_status_map, state) do
    Logger.info("Websocket disconnected: #{connection_status_map}")

    {:ok, state}
  end

  @impl WebSockex
  def handle_cast(:initialize_connection, state) do
    message = {:text, Message.initialize_connection()}

    Logger.debug("Sending websocket frame to initialize subscription connection: #{inspect(message)}")

    {:reply, message, state}
  end

  def handle_cast(:subscribe, {%SubscriptionQuery{} = subscription_query, _} = state) do
    message = {:text, Message.subscribe(subscription_query)}

    Logger.debug("Sending websocket frame to subscribe to #{subscription_query.operation_name}: #{inspect(message)}")

    {:reply, message, state}
  end

  def handle_cast(:pong, state) do
    message = {:text, Message.pong()}

    Logger.debug("Sending pong websocket frame")

    {:reply, message, state}
  end

  @impl WebSockex
  def handle_frame(frame, {_, handle_next} = state) do
    Logger.debug("Received frame #{inspect(frame)}")

    {:text, frame_text} = frame

    frame_text
    |> Message.from_websocket_frame()
    |> tap(&Logger.debug("Decoded message #{inspect(&1)}"))
    |> handle_message(handle_next)

    {:ok, state}
  end

  @impl WebSockex
  def terminate(close_reason, _state) do
    Logger.error("Subscription terminating: #{inspect(close_reason)}")

    :ok
  end

  defp handle_message(%Message{type: "connection_ack"}, _handle_next) do
    WebSockex.cast(self(), :subscribe)
  end

  defp handle_message(%Message{type: "ping"}, _handle_next) do
    WebSockex.cast(self(), :pong)
  end

  defp handle_message(%Message{type: "next"} = message, handle_next) do
    Logger.info("Received next message")
    Logger.debug("Raw message: #{inspect(message)}")

    handle_next.(message.payload)
  end

  defp handle_message(%Message{type: "error"} = message, _handle_next) do
    Logger.error("Received error message: #{inspect(message)}")
  end

  defp handle_message(%Message{} = message, _handle_next) do
    Logger.warning("Received unexpected message with type #{message.type}")
  end
end
