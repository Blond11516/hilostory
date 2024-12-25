defmodule Hilostory.Infrastructure.OauthTokensRepository do
  alias Hilostory.Repo
  alias Hilostory.Schema.OauthTokensSchema

  def upsert(access_token, refresh_token, %DateTime{} = refresh_token_expires_at)
      when is_binary(access_token) and is_binary(refresh_token) do
    Repo.transaction(fn ->
      case Repo.one(OauthTokensSchema) do
        nil -> nil
        _ -> delete()
      end

      Repo.insert(%OauthTokensSchema{
        access_token: access_token,
        refresh_token: refresh_token,
        refresh_token_expires_at: refresh_token_expires_at
      })
    end)
  end

  @spec get() :: OauthTokensSchema.t() | nil
  def get() do
    Repo.one(OauthTokensSchema)
  end

  def delete() do
    Repo.delete_all(OauthTokensSchema)
  end
end
