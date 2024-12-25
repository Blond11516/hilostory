defmodule Hilostory.WebsocketSuperviser do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_websocket() do
    DynamicSupervisor.start_child(__MODULE__, Hilostory.Infrastructure.Hilo.WebsocketClient)
  end
end
