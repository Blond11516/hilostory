defmodule HilostoryWeb.PageController do
  use HilostoryWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    Hello, World!
    """
  end
end
