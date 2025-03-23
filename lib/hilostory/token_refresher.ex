defmodule Hilostory.TokenRefresher do
  @moduledoc false
  alias Hilostory.Infrastructure.Hilo.AuthorizationClient
  alias Hilostory.Joken.HiloToken
  alias Hilostory.Schema.OauthTokensSchema

  @spec refresh(OauthTokensSchema.t()) :: {:ok, OauthTokensSchema.t()} | {:error, Exception.t()}
  def refresh(%OauthTokensSchema{} = tokens) do
    with {:ok, refreshed_tokens} <-
           AuthorizationClient.refresh_access_token(tokens.refresh_token) do
      refresh_token_expires_at =
        HiloToken.calculate_refresh_token_expiration(refreshed_tokens.refresh_token_expires_in)

      {:ok,
       %OauthTokensSchema{
         access_token: refreshed_tokens.access_token,
         refresh_token: refreshed_tokens.refresh_token,
         refresh_token_expires_at: refresh_token_expires_at
       }}
    end
  end

  def calculate_time_until_refresh(claims) do
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

    refresh_in
  end
end
