defmodule HilostoryWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use HilostoryWeb, :controller
      use HilostoryWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: HilostoryWeb.Layouts]

      import Plug.Conn

      require HilostoryWeb

      HilostoryWeb.verified_routes()
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {HilostoryWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components and translation
      import HilostoryWeb.CoreComponents

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      require HilostoryWeb

      # Routes generation with the ~p sigil
      HilostoryWeb.verified_routes()
    end
  end

  defmacro verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: HilostoryWeb.Endpoint,
        router: HilostoryWeb.Router,
        statics: HilostoryWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
