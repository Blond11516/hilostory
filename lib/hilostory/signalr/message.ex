defmodule Hilostory.Signalr.Message do
  @record_separator "\u001e"

  @type_codes_to_types %{
    1 => :invoke,
    2 => :stream,
    3 => :complete,
    4 => :stream_invocation,
    5 => :cancel_invocation,
    6 => :ping,
    7 => :close,
    0xFF => :unknown
  }
  @types_to_type_codes Map.new(@type_codes_to_types, fn {type_code, type} -> {type, type_code} end)

  @keys [:type, :target, :invocation_id, :arguments]
  @enforce_keys @keys
  defstruct @keys

  @type t :: %__MODULE__{
          type:
            :invoke
            | :stream
            | :complete
            | :stream_invocation
            | :cancel_invocation
            | :ping
            | :close
            | :unknown,
          target: String.t() | nil,
          invocation_id: String.t() | nil,
          arguments: list()
        }

  def from_websocket_frame(frame) do
    frame
    |> String.split(@record_separator)
    |> Enum.filter(fn message -> message != "" end)
    |> Enum.map(&parse_message/1)
    |> Enum.filter(fn
      {:error, :no_type, "{}"} -> false
      _ -> true
    end)
  end

  def pong_frame do
    Jason.encode!(%{"type" => @types_to_type_codes[:ping]}) <> @record_separator
  end

  defp parse_message(raw_message) do
    with {:ok, message} <- Jason.decode(raw_message),
         {:ok, type_code} <- get_type_code(message),
         {:ok, type} <- get_type(type_code) do
      {:ok,
       %__MODULE__{
         type: type,
         target: message["target"],
         invocation_id: message["invocation_id"],
         arguments: message["arguments"]
       }}
    else
      {:error, reason} -> {:error, reason, raw_message}
    end
  end

  defp get_type_code(message) do
    case message do
      %{"type" => type_code} -> {:ok, type_code}
      _ -> {:error, :no_type}
    end
  end

  defp get_type(type_code) do
    case @type_codes_to_types do
      %{^type_code => type} -> {:ok, type}
      _ -> {:error, :unknown_type}
    end
  end
end
