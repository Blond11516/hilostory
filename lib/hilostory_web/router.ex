defmodule HilostoryWeb.Router do
  use HilostoryWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HilostoryWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :hilo_auth do
    plug HilostoryWeb.Plugs.HiloAuthenticated
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HilostoryWeb do
    pipe_through :browser

    live "/login", LoginLive
  end

  scope "/", HilostoryWeb do
    pipe_through [:browser, :hilo_auth]

    live "/", HomeLive
  end

  scope "/auth", HilostoryWeb do
    pipe_through :api

    get "/login", AuthController, :login

    # This endpoint is dictated by my.home-assistant.io, which is authorized as
    # a redirect URI by Hilo
    get "/external/callback", AuthController, :callback
  end

  # Other scopes may use custom stacks.
  # scope "/api", HilostoryWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:hilostory, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HilostoryWeb.Telemetry
    end
  end
end
