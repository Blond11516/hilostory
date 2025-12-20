defmodule Hilostory.Infrastructure.Hilo.WebsocketClient do
  @moduledoc false
  use WebSockex

  alias Hilostory.Device
  alias Hilostory.DeviceValue.Power
  alias Hilostory.DeviceValue.TargetTemperature
  alias Hilostory.DeviceValue.Temperature
  alias Hilostory.Infrastructure.DeviceRepository
  alias Hilostory.Infrastructure.DeviceValueRepository
  alias Hilostory.Infrastructure.Hilo.AutomationClient
  alias Hilostory.Infrastructure.Hilo.BaseApiClient
  alias Hilostory.Infrastructure.Hilo.Models.WebsocketConnectionInfo
  alias Hilostory.Infrastructure.Hilo.Models.WebsocketMessages.DeviceListInitialValuesReceived
  alias Hilostory.Infrastructure.Hilo.Models.WebsocketMessages.DeviceListUpdatedValuesReceived
  alias Hilostory.Infrastructure.Hilo.Models.WebsocketMessages.DeviceValuesReceived
  alias Hilostory.Signalr.Message
  alias Hilostory.TokenManager

  require Logger

  def start_link(_) do
    Logger.info("Starting websocket client")

    {:ok, tokens} = TokenManager.get()
    Logger.info("Obtained the latest access token")

    {:ok, %{body: [location]}} = AutomationClient.list_locations(tokens.access_token)
    Logger.info("Retrieved the Hilo location")

    connection_info = get_websocket_connection_info(tokens)
    Logger.info("Fetched websocket connection info")

    connection_id =
      get_connection_id(connection_info["url"], connection_info["accessToken"])

    Logger.info("Fetched websocket connection id: #{connection_id}")

    {:ok, websockex_pid} =
      connection_info["url"]
      |> URI.append_query(
        URI.encode_query(%{
          "id" => connection_id,
          "access_token" => connection_info["accessToken"]
        })
      )
      |> URI.to_string()
      |> WebSockex.start_link(__MODULE__, fn -> subscribe_to_location(location) end)

    Logger.info("Started websocket process")
    {:ok, websockex_pid}
  end

  defp subscribe_to_location(location) do
    Logger.info("Subscribing to location #{location["id"]}")
    WebSockex.cast(self(), {:subscribe_to_location, location})
  end

  @impl true
  def handle_cast(:handshake, state) do
    handshake_frame = {:text, Message.handshake_frame()}
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
    subsrciption_frame = {:text, Message.subscribe_to_location_frame(location["id"])}

    Logger.debug("Sending websocket frame to subscribe to location #{location["id"]}: #{inspect(subsrciption_frame)}")

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
    {:text, frame_text} = frame

    frame_text
    |> Message.from_websocket_frame()
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

  defp get_connection_id(%URI{} = websocket_uri, websocket_access_token) when is_binary(websocket_access_token) do
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
        WebsocketConnectionInfo
      )

    resp.body
  end

  defp handle_message(%Message{type: :ping}) do
    Logger.debug("Received ping message. Will reply with pong.")
    WebSockex.cast(self(), :pong)
  end

  defp handle_message(%Message{type: :invoke, target: "DeviceListInitialValuesReceived"} = message) do
    Logger.info("Handling \"DeviceListInitialValuesReceived\". Persisting devices in task.")

    Task.start(fn ->
      Logger.info("Persisting initial devices list.")

      message.arguments
      |> hd()
      |> Enum.map(&Zoi.parse!(DeviceListInitialValuesReceived.schema(), &1))
      |> Enum.each(fn device ->
        device = %Device{
          hilo_id: device["hiloId"],
          name: device["name"],
          type: device["type"]
        }

        device
        |> DeviceRepository.upsert()
        |> case do
          {:ok, _} ->
            Logger.info("Successfully persisted device #{device.hilo_id}")

          {:error, error} ->
            Logger.error("Failed to persist device #{device.hilo_id}: #{inspect(error)}")
        end
      end)

      Logger.info("Finished persisting devices, task will end.")
    end)
  end

  defp handle_message(%Message{type: :invoke, target: "DeviceListUpdatedValuesReceived"} = message) do
    Logger.info("Handling \"DeviceListUpdatedValuesReceived\". Persisting devices in task.")

    Task.start(fn ->
      Logger.info("Persisting updated devices.")

      message.arguments
      |> hd()
      |> Enum.map(&Zoi.parse!(DeviceListUpdatedValuesReceived.schema(), &1))
      |> Enum.each(fn device ->
        case DeviceRepository.update(device["id"], device["name"]) do
          {:ok, _} ->
            Logger.info("Successfully updated device #{device["id"]}")

          {:error, error} ->
            Logger.error("Failed to update device #{device["id"]}: #{inspect(error)}")
        end
      end)

      Logger.info("Finished updating devices, task will end.")
    end)
  end

  defp handle_message(%Message{type: :invoke, target: "DevicesValuesReceived"} = message) do
    Logger.info("Handling \"DevicesValuesReceived\". Persiting values in task.")

    Task.start(fn ->
      Logger.info("Persisting device values.")

      message.arguments
      |> hd()
      |> Enum.map(&Zoi.parse!(DeviceValuesReceived.schema(), &1))
      |> Enum.each(fn value ->
        parsed_value =
          case value.attribute do
            "CurrentTemperature" ->
              %Temperature{
                temperature: value.value,
                timestamp: value.time_stamp_utc
              }

            "TargetTemperature" ->
              %TargetTemperature{
                target_temperature: value.value,
                timestamp: value.time_stamp_utc
              }

            "Power" ->
              %Power{
                power: value.value,
                timestamp: value.time_stamp_utc
              }

            _ ->
              :untracked_value
          end

        if parsed_value != :untracked_value do
          parsed_value
          |> DeviceValueRepository.insert(value.device_id)
          |> case do
            {:ok, _} ->
              Logger.info(
                "Successfully inserted value #{value.value} for attribute #{value.attribute} of device #{value.device_id} at time #{value.time_stamp_utc}."
              )

            {:error, error} ->
              Logger.error(
                "Failed to insert value #{value.value} for attribute #{value.attribute} of device #{value.device_id} at time #{value.time_stamp_utc}: #{inspect(error)}"
              )
          end
        end
      end)
    end)
  end

  defp handle_message(%Message{} = message) do
    Logger.warning(
      "Received unexpected message with type #{message.type}, target \"#{message.target}\" and invocation id \"#{message.invocation_id}\"."
    )
  end
end
