defmodule Hilostory.TokenManager do
  @moduledoc false
  use GenServer

  alias Hilostory.Infrastructure.OauthTokensRepository
  alias Hilostory.Joken.HiloToken
  alias Hilostory.Schema.OauthTokensSchema
  alias Hilostory.TokenRefresher

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get do
    GenServer.call(__MODULE__, :get)
  end

  @impl true
  def init(_init_arg) do
    {:ok, nil, {:continue, :maybe_self_start_loop}}
  end

  @impl true
  def handle_call(:get, _, _) do
    case do_get() do
      {:ok, tokens, _claims} -> {:reply, {:ok, tokens}, nil}
      {:error, error} -> {:reply, {:error, error}, nil}
    end
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

    with {:ok, tokens, _claims} <- do_get(),
         {:ok, refreshed_tokens, refresh_token_expires_at} <- TokenRefresher.refresh(tokens),
         :ok <-
           OauthTokensRepository.upsert(
             refreshed_tokens.access_token,
             refreshed_tokens.refresh_token,
             refresh_token_expires_at
           ) do
      claims = verify_tokens(refreshed_tokens)
      refresh_in = TokenRefresher.calculate_time_until_refresh(claims)
      Logger.info("Access token refreshed. Will refresh again in #{refresh_in} seconds.")

      schedule_refresh(refresh_in)
    else
      error ->
        Logger.error("Failed to refresh access token: #{inspect(error)}")
    end

    {:noreply, state}
  end

  def start_loop do
    case do_get() do
      {:ok, _tokens, claims} ->
        refresh_in = TokenRefresher.calculate_time_until_refresh(claims)

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
    Logger.info("Scheduling access token refresh in #{refresh_in} seconds.")

    Process.send_after(
      self(),
      :refresh,
      :erlang.convert_time_unit(refresh_in, :second, :millisecond)
    )
  end

  defp verify_tokens(%OauthTokensSchema{} = tokens) do
    case verify_refresh_token_not_expired(tokens) do
      :ok ->
        HiloToken.verify(tokens.access_token)

      {:error, :refresh_token_expired} ->
        Logger.info("Refresh token has expired. Deleting it.")
        OauthTokensRepository.delete()
        {:error, :refresh_token_expired}
    end
  end

  defp verify_refresh_token_not_expired(%OauthTokensSchema{} = tokens) do
    if DateTime.before?(tokens.refresh_token_expires_at, DateTime.utc_now()) do
      {:error, :refresh_token_expired}
    else
      :ok
    end
  end

  defp do_get do
    with %OauthTokensSchema{} = tokens <- OauthTokensRepository.get(),
         {:ok, claims} <- verify_tokens(tokens) do
      {:ok, tokens, claims}
    else
      nil -> {:error, :no_stored_token}
    end
  end
end
