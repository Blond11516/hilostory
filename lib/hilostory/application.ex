defmodule Hilostory.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    start_app = Application.get_env(:hilostory, :start_app, true)

    children =
      [
        HilostoryWeb.Telemetry,
        Hilostory.Repo
      ]
      |> append_if(start_app, [
        {Finch, name: :joken_jwks_client, pools: %{default: [size: 1, count: 1]}},
        Hilostory.Joken.HiloStrategy,
        Hilostory.TokenManager,
        {Phoenix.PubSub, name: Hilostory.PubSub},
        Hilostory.Vault,
        Hilostory.WebsocketSupervisor,
        Hilostory.WebsocketStarter,
        HilostoryWeb.Endpoint
      ])
      |> append_if(
        start_app and Application.get_env(:hilostory, :env) != :test,
        {Tz.UpdatePeriodically, []}
      )

    # Start a worker by calling: Hilostory.Worker.start_link(arg)
    # {Hilostory.Worker, arg},
    # Start to serve requests, typically the last entry

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hilostory.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    HilostoryWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp append_if(list, condition, items) when is_list(items) do
    if condition, do: list ++ items, else: list
  end

  defp append_if(list, condition, item) do
    append_if(list, condition, [item])
  end
end
