defmodule Hilostory.WebsocketSupervisor do
  @moduledoc false
  use DynamicSupervisor

  alias Hilostory.DeviceUpdateListener
  alias Hilostory.SupervisorChildStartErrorLogger

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one, max_children: 1)
  end

  def start_websocket do
    DynamicSupervisor.start_child(
      __MODULE__,
      SupervisorChildStartErrorLogger.child_spec(DeviceUpdateListener, nil)
    )
  end
end
