defmodule HilostoryWeb.Plugs.HiloAuthenticated do
  require HilostoryWeb

  HilostoryWeb.verified_routes()

  @behaviour Plug

  @impl true
  def init(options), do: options

  @impl true
  def call(conn, _opts) do
    if Hilostory.HiloTokens.has_valid_tokens() do
      conn
    else
      Phoenix.Controller.redirect(conn, to: ~p"/login")
    end
  end
end
