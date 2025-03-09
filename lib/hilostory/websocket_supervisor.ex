defmodule Hilostory.WebsocketSupervisor do
  use DynamicSupervisor

  alias Hilostory.Infrastructure.Hilo.WebsocketClient

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_websocket(tokens, location) do
    connected_callback = fn -> WebsocketClient.subscribe_to_location(self(), location) end

    DynamicSupervisor.start_child(__MODULE__, {WebsocketClient, {tokens, connected_callback}})
  end
end
