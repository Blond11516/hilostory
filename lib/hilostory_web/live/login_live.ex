defmodule HilostoryWeb.LoginLive do
  @moduledoc false
  use HilostoryWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if Hilostory.HiloTokens.has_valid_tokens() do
      {:ok, redirect(socket, to: ~p"/")}
    else
      {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.link href={~p"/auth/login"}>Login</.link>
    """
  end
end
