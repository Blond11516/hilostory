defmodule Hilostory.SupervisorChildStartErrorLogger do
  @moduledoc """
  Wraps another module's `start_link/1` function to log any errors that occur
  during startup.

  This helps diagnose restart failures of children of `elixir:DynamicSupervisor`
  or other supervisors that don't log start errors on automatic restarts.
  """

  require Logger

  def child_spec(module, start_argument) do
    Supervisor.child_spec(module.child_spec(nil), %{
      start: {__MODULE__, :start_link, [module, start_argument]}
    })
  end

  def start_link(module, start_argument) do
    module.start_link(start_argument)
  rescue
    error ->
      Logger.error("Failed to start #{inspect(module)} with argument #{inspect(start_argument)}: #{inspect(error)}")

      reraise error, __STACKTRACE__
  end
end
