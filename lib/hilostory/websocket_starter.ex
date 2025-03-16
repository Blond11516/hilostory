defmodule Hilostory.WebsocketStarter do
  @moduledoc false
  use Task

  alias Hilostory.WebsocketSupervisor

  require Logger

  def start_link(_) do
    Task.start_link(__MODULE__, :start_websocket, [])
  end

  def start_websocket do
    Logger.info("Will attempt to start websocket.")

    case WebsocketSupervisor.start_websocket() do
      {:ok, _} -> :ok
      {:error, error} -> Logger.error("Failed to start websocket: #{inspect(error)}")
    end
  end
end
