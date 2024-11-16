defmodule Hilostory.Repo.Migrations.AddHiloOauthTokensTable do
  use Ecto.Migration

  def change do
    create table("oauth_tokens", primary_key: false) do
      add :access_token, :bytea, null: false
      add :refresh_token, :bytea, null: false
    end
  end
end
