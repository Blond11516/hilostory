defmodule Hilostory.Infrastructure.OauthTokensRepository do
  @moduledoc false
  alias Hilostory.Repo
  alias Hilostory.Schema.OauthTokensSchema

  @spec upsert(String.t(), String.t(), DateTime.t()) :: :ok | {:error, Ecto.Changeset.t()}
  def upsert(access_token, refresh_token, %DateTime{} = refresh_token_expires_at)
      when is_binary(access_token) and is_binary(refresh_token) do
    Repo.transaction(fn ->
      case Repo.one(OauthTokensSchema) do
        nil -> nil
        _ -> delete()
      end

      new_schema = %OauthTokensSchema{
        access_token: access_token,
        refresh_token: refresh_token,
        refresh_token_expires_at: refresh_token_expires_at
      }

      case Repo.insert(new_schema) do
        {:ok, _token} -> :ok
        {:error, changeset} -> {:error, changeset}
      end
    end)
  end

  @spec get() :: OauthTokensSchema.t() | nil
  def get do
    Repo.one(OauthTokensSchema)
  end

  def delete do
    Repo.delete_all(OauthTokensSchema)
  end
end
