defmodule Hilostory.Graphql.Message do
  @moduledoc false
  require Logger

  @enforce_keys [:type, :id, :payload, :message]
  defstruct [:type, :id, :payload, :message]

  @type t :: %__MODULE__{
          type: String.t(),
          id: String.t() | nil,
          payload: %{String.t() => term()} | list(term()) | nil,
          message: String.t() | nil
        }

  def from_websocket_frame(frame_text) when is_binary(frame_text) do
    message = JSON.decode!(frame_text)

    Logger.debug("Decoded JSON message #{inspect(message)}")

    %__MODULE__{
      type: message["type"],
      id: message["id"],
      payload: message["payload"],
      message: message["message"]
    }
  end

  def initialize_connection do
    encode(%{"type" => "connection_init"})
  end

  def subscribe(%Hilostory.Graphql.SubscriptionQuery{} = query) do
    encode(%{
      "type" => "subscribe",
      "id" => "0",
      "payload" => %{
        "variables" => query.variables,
        "operationName" => query.operation_name,
        "extensions" => %{},
        "query" => query.query
      }
    })
  end

  def pong do
    encode(%{"type" => "pong"})
  end

  defp encode(message) when is_map(message) do
    JSON.encode!(message)
  end
end
