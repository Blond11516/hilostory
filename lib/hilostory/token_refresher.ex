defmodule Hilostory.TokenRefresher do
  @moduledoc false
  alias Hilostory.Infrastructure.Hilo.AuthorizationClient
  alias Hilostory.Infrastructure.OauthTokensRepository
  alias Hilostory.Joken.HiloToken
  alias Hilostory.Schema.OauthTokensSchema

  def refresh do
    with %OauthTokensSchema{} = tokens <- get_tokens(),
         :ok <- verify_refresh_token_valid(tokens),
         {:ok, refreshed_tokens} <-
           AuthorizationClient.refresh_access_token(tokens.refresh_token),
         refresh_token_expires_at =
           HiloToken.calculate_refresh_token_expiration(refreshed_tokens.refresh_token_expires_in) do
      OauthTokensRepository.upsert(
        refreshed_tokens.access_token,
        refreshed_tokens.refresh_token,
        refresh_token_expires_at
      )
    end
  end

  def calculate_time_until_refresh do
    with %OauthTokensSchema{} = tokens <- OauthTokensRepository.get(),
         :ok <- verify_refresh_token_valid(tokens),
         {:ok, claims} <- HiloToken.verify(tokens.access_token) do
      expires_at =
        claims
        |> Map.fetch!("exp")
        |> DateTime.from_unix!()

      not_valid_before =
        claims
        |> Map.fetch!("nbf")
        |> DateTime.from_unix!()

      total_valid_for = DateTime.diff(expires_at, not_valid_before, :second)
      valid_for_with_buffer = trunc(total_valid_for * 0.9)

      refresh_in =
        not_valid_before
        |> DateTime.add(valid_for_with_buffer, :second)
        |> DateTime.diff(DateTime.utc_now(), :second)
        |> max(0)

      {:ok, refresh_in}
    end
  end

  defp verify_refresh_token_valid(%OauthTokensSchema{} = tokens) do
    if DateTime.before?(tokens.refresh_token_expires_at, DateTime.utc_now()) do
      OauthTokensRepository.delete()

      {:error, :refresh_token_expired}
    else
      :ok
    end
  end

  defp get_tokens do
    case OauthTokensRepository.get() do
      nil -> {:error, :no_stored_tokens}
      tokens -> tokens
    end
  end
end
