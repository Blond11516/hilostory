defmodule Hilostory.TokenRefreshScheduler do
  use GenServer

  require Logger

  alias Hilostory.TokenRefresher

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    {:ok, nil, {:continue, :maybe_self_start_loop}}
  end

  @impl true
  def handle_continue(:maybe_self_start_loop, state) do
    Logger.info("Attempting to start access token refresh loop.")

    start_loop()

    {:noreply, state}
  end

  @impl true
  def handle_info(:refresh, state) do
    Logger.info("Refreshing access token.")

    with {:ok, _tokens} <- TokenRefresher.refresh(),
         {:ok, refresh_in} <- TokenRefresher.calculate_time_until_refresh() do
      Logger.info("Access token refreshed. Will refresh again in #{refresh_in} seconds.")

      schedule_refresh(refresh_in)
    end

    {:noreply, state}
  end

  def start_loop() do
    case TokenRefresher.calculate_time_until_refresh() do
      {:ok, refresh_in} ->
        Logger.info(
          "Access token refresh loop can start successfully. Will refresh access token in #{refresh_in} seconds."
        )

        schedule_refresh(refresh_in)
        :ok

      {:error, :no_signers_fetched} ->
        Logger.info("JWKS not yet fetched. Will try starting refresh loop again in 2 seconds.")
        Process.sleep(2_000)
        start_loop()
        :ok

      error ->
        Logger.error("Failed to start access token refresh loop: #{inspect(error)}")
        {:error, error}
    end
  end

  defp schedule_refresh(refresh_in) when is_integer(refresh_in) do
    Process.send_after(
      self(),
      :refresh,
      :erlang.convert_time_unit(refresh_in, :second, :millisecond)
    )
  end
end
