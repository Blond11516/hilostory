defmodule Hilostory.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        HilostoryWeb.Telemetry,
        Hilostory.Repo,
        Hilostory.Joken.HiloStrategy,
        Hilostory.TokenRefreshScheduler,
        {Phoenix.PubSub, name: Hilostory.PubSub},
        Hilostory.Vault,
        Hilostory.WebsocketSuperviser,
        Hilostory.WebsocketStarter,
        # Start a worker by calling: Hilostory.Worker.start_link(arg)
        # {Hilostory.Worker, arg},
        # Start to serve requests, typically the last entry
        HilostoryWeb.Endpoint
      ]
      |> append_if(Application.get_env(:hilostory, :env) != :test, {Tz.UpdatePeriodically, []})

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hilostory.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HilostoryWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp append_if(list, condition, item) do
    if condition, do: list ++ [item], else: list
  end
end
