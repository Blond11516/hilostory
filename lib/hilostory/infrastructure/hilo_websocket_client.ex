defmodule Hilostory.Infrastructure.HiloWebsocketClient do
  require Logger

  use WebSockex

  alias Hilostory.Signalr.Message

  def start_link() do
    {websocket_uri, websocket_access_token} = get_websocket_uri()

    connection_id =
      get_connection_id(websocket_uri, websocket_access_token)

    {:ok, websockex_pid} =
      websocket_uri
      |> URI.append_query(
        URI.encode_query(%{"id" => connection_id, "access_token" => websocket_access_token})
      )
      |> URI.to_string()
      |> WebSockex.start_link(__MODULE__, %{})

    {:ok, websockex_pid}
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

  defp get_websocket_uri() do
    access_token = Hilostory.Infrastructure.OauthTokensRepository.get().access_token

    resp =
      Req.new(
        url: "https://api.hiloenergie.com/DeviceHub/negotiate",
        auth: {:bearer, access_token},
        headers: %{
          "content-type" => "application/json; charset=utf-8",
          "ocp-apim-subscription-key" => "20eeaedcb86945afa3fe792cea89b8bf"
        },
        body: ""
      )
      |> Req.post!()

    %{
      "accessToken" => access_token,
      "availableTransports" => _available_transports,
      "negotiateVersion" => _negotiate_version,
      "url" => url
    } = resp.body

    {URI.parse(url), access_token}
  end

  defp handle_message(%Message{type: :ping}) do
    Logger.debug("Received ping message. Will reply with pong.")
    WebSockex.cast(self(), :pong)
  end
end
