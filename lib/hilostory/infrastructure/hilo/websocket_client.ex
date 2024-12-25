defmodule Hilostory.Infrastructure.Hilo.WebsocketClient do
  require Logger

  use WebSockex

  alias Hilostory.Signalr.Message
  alias Hilostory.Infrastructure.Hilo.BaseApiClient
  alias Hilostory.Infrastructure.Hilo.Models
  alias Hilostory.Infrastructure.Hilo.Models.WebsocketConnectionInfo
  alias Hilostory.Infrastructure.Hilo.Models.Location

  def start_link(_) do
    connection_info = get_websocket_connection_info()

    connection_id =
      get_connection_id(connection_info.url, connection_info.access_token)

    {:ok, websockex_pid} =
      connection_info.url
      |> URI.append_query(
        URI.encode_query(%{"id" => connection_id, "access_token" => connection_info.access_token})
      )
      |> URI.to_string()
      |> WebSockex.start_link(__MODULE__, %{})

    {:ok, websockex_pid}
  end

  def subscribe_to_location(client, %Location{} = location) do
    WebSockex.send_frame(
      client,
      {:text,
       Jason.encode!(%{
         "arguments" => [location.id],
         "invocationId" => "0",
         "target" => "SubscribeToLocation",
         "type" => 1
       })}
    )
  end

  @impl true
  def handle_cast(:handshake, state) do
    handshake_frame = {:text, Jason.encode!(%{"protocol" => "json", "version" => 1}) <> "\u001e"}
    Logger.debug("Sending websocket handshake #{inspect(handshake_frame)}")
    {:reply, handshake_frame, state}
  end

  def handle_cast(:pong, state) do
    Logger.debug("Replying to ping message with a pong")
    {:reply, {:text, Message.pong_frame()}, state}
  end

  @impl true
  def handle_connect(_conn, state) do
    WebSockex.cast(self(), :handshake)

    {:ok, state}
  end

  @impl true
  def handle_disconnect(connection_status_map, state) do
    IO.inspect("handle_disconnect")
    dbg(connection_status_map)

    {:ok, state}
  end

  @impl true
  def handle_frame(frame, state) do
    case frame do
      {:text, frame_text} -> Message.from_websocket_frame(frame_text)
    end
    |> Enum.each(fn
      {:ok, message} ->
        Logger.debug("Handling message #{inspect(message)}")
        handle_message(message)

      {:error, reason, raw_message} ->
        Logger.error(
          "Failed to parse SignalR message.\nReason: #{inspect(reason)}\nOriginal message: #{inspect(raw_message)}"
        )
    end)

    {:ok, state}
  end

  @impl true
  def terminate(_close_reason, _state) do
    :ok
  end

  defp get_connection_id(%URI{} = websocket_uri, websocket_access_token)
       when is_binary(websocket_access_token) do
    resp =
      websocket_uri
      |> URI.parse()
      |> URI.append_path("/negotiate")
      |> Req.post!(auth: {:bearer, websocket_access_token})

    %{
      "availableTransports" => _available_transports,
      "connectionId" => connection_id,
      "negotiateVersion" => _negotiate_version
    } = resp.body

    connection_id
  end

  defp get_websocket_connection_info() do
    access_token = Hilostory.Infrastructure.OauthTokensRepository.get().access_token

    {:ok, resp} =
      BaseApiClient.post(
        "/DeviceHub",
        "/negotiate",
        access_token,
        &Models.parse(
          &1,
          WebsocketConnectionInfo,
          %{url: fn raw_url -> URI.new!(raw_url) end}
        )
      )

    resp.body
  end

  defp handle_message(%Message{type: :ping}) do
    Logger.debug("Received ping message. Will reply with pong.")
    WebSockex.cast(self(), :pong)
  end

  defp handle_message(%Message{} = message) do
    Logger.warning(
      "Received unexpected message with type #{message.type}, target \"#{message.target}\" and invocation id \"#{message.invocation_id}\"."
    )
  end
end
