defmodule Hilostory.Infrastructure.OauthTokensRepository do
  alias Hilostory.Repo
  alias Hilostory.Schema.OauthTokensSchema

  def upsert(access_token, refresh_token) when is_binary(access_token) and is_binary(refresh_token) do
    Repo.transaction(fn ->
      case Repo.one(OauthTokensSchema) do
        nil -> nil
        _ -> Repo.delete_all(OauthTokensSchema)
      end
      Repo.insert(%OauthTokensSchema{
        access_token: access_token,
        refresh_token: refresh_token
      })
    end)
  end

  def get() do
    Repo.one(OauthTokensSchema)
  end
end
