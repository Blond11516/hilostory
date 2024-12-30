defmodule Hilostory.Infrastructure.Hilo.WebsocketClient do
  require Logger

  use WebSockex

  alias Hilostory.Infrastructure.Hilo.Models.WebsocketMessages.DeviceListUpdatedValuesReceived
  alias Hilostory.Infrastructure.DeviceRepository
  alias Hilostory.Device
  alias Hilostory.Infrastructure.Hilo.Models.WebsocketMessages.DeviceListInitialValuesReceived
  alias Hilostory.Signalr.Message
  alias Hilostory.Infrastructure.Hilo.BaseApiClient
  alias Hilostory.Infrastructure.Hilo.Models
  alias Hilostory.Infrastructure.Hilo.Models.WebsocketConnectionInfo
  alias Hilostory.Infrastructure.Hilo.Models.Location

  def start_link({tokens, connected_callback}) do
    Logger.info("Starting websocket client")

    connection_info = get_websocket_connection_info(tokens)
    Logger.info("Fetched websocket connection info")

    connection_id =
      get_connection_id(connection_info.url, connection_info.access_token)

    Logger.info("Fetched websocket connection id: #{connection_id}")

    {:ok, websockex_pid} =
      connection_info.url
      |> URI.append_query(
        URI.encode_query(%{"id" => connection_id, "access_token" => connection_info.access_token})
      )
      |> URI.to_string()
      |> WebSockex.start_link(__MODULE__, connected_callback)

    Logger.info("Started websocket process")
    {:ok, websockex_pid}
  end

  def subscribe_to_location(client, %Location{} = location) do
    Logger.info("Subscribing to location #{location.id}")
    WebSockex.cast(client, {:subscribe_to_location, location})
  end

  @impl true
  def handle_cast(:handshake, state) do
    handshake_frame = {:text, Jason.encode!(%{"protocol" => "json", "version" => 1}) <> "\u001e"}
    Logger.debug("Sending websocket handshake #{inspect(handshake_frame)}")
    WebSockex.cast(self(), :run_connected_callback)
    {:reply, handshake_frame, state}
  end

  def handle_cast(:pong, state) do
    Logger.debug("Replying to ping message with a pong")
    {:reply, {:text, Message.pong_frame()}, state}
  end

  def handle_cast(:run_connected_callback, connected_callback) do
    Logger.info("Running connected callback")
    connected_callback.()
    {:ok, connected_callback}
  end

  def handle_cast({:subscribe_to_location, location}, state) do
    subsrciption_frame =
      {:text,
       Jason.encode!(%{
         "arguments" => [location.id],
         "invocationId" => "0",
         "target" => "SubscribeToLocation",
         "type" => 1
       })}

    Logger.debug(
      "Sending websocket frame to subscribe to location #{location.id}: #{inspect(subsrciption_frame)}"
    )

    {:reply, subsrciption_frame, state}
  end

  @impl true
  def handle_connect(_conn, state) do
    Logger.info("Websocket connected, will send handshake")
    WebSockex.cast(self(), :handshake)

    {:ok, state}
  end

  @impl true
  def handle_disconnect(connection_status_map, state) do
    Logger.info("Websocket disconnected: #{connection_status_map}")

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
  def terminate(close_reason, _state) do
    Logger.info("Websocket client terminated: #{inspect(close_reason)}")
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

  defp get_websocket_connection_info(tokens) do
    access_token = tokens.access_token

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

  defp handle_message(
         %Message{type: :invoke, target: "DeviceListInitialValuesReceived"} = message
       ) do
    Logger.info("Handling \"DeviceListInitialValuesReceived\". Persisting devices in task.")

    Task.start(fn ->
      Logger.info("Persisting initial devices list.")

      message.arguments
      |> hd()
      |> Models.parse(DeviceListInitialValuesReceived)
      |> Enum.each(fn %DeviceListInitialValuesReceived{} = device ->
        device = %Device{
          id: device.id,
          hilo_id: device.hilo_id,
          name: device.name,
          type: device.type
        }

        device
        |> DeviceRepository.upsert()
        |> case do
          {:ok, _} ->
            Logger.info("Successfully persisted device #{device.id}")

          {:error, error} ->
            Logger.error("Failed to persist device #{device.id}: #{inspect(error)}")
        end
      end)

      Logger.info("Finished persisting devices, task will end.")
    end)
  end

  defp handle_message(
         %Message{type: :invoke, target: "DeviceListUpdatedValuesReceived"} = message
       ) do
    Logger.info("Handling \"DeviceListUpdatedValuesReceived\". Persisting devices in task.")

    Task.start(fn ->
      Logger.info("Persisting updated devices.")

      message.arguments
      |> hd()
      |> Models.parse(DeviceListUpdatedValuesReceived)
      |> Enum.each(fn %DeviceListUpdatedValuesReceived{} = device ->
        DeviceRepository.update(device.id, device.name)
        |> case do
          {:ok, _} ->
            Logger.info("Successfully updated device #{device.id}")

          {:error, error} ->
            Logger.error("Failed to update device #{device.id}: #{inspect(error)}")
        end
      end)

      Logger.info("Finished updating devices, task will end.")
    end)
  end

  defp handle_message(%Message{} = message) do
    Logger.warning(
      "Received unexpected message with type #{message.type}, target \"#{message.target}\" and invocation id \"#{message.invocation_id}\"."
    )
  end
end
