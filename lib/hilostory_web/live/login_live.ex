defmodule HilostoryWeb.LoginLive do
  use HilostoryWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, counter: 0)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.link href={~p"/auth/login"}>Login</.link>
    <button phx-click="flash">Flash</button>
    """
  end

  @impl true
  def handle_event("flash", _unsigned_params, socket) do
    socket =
      socket
      |> put_flash(:info, "test #{socket.assigns.counter}")
      |> assign(counter: socket.assigns.counter + 1)

    {:noreply, socket}
  end
end
